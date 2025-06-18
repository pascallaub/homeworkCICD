#!/bin/bash

set -e

AWS_REGION="${AWS_REGION:-eu-central-1}"
BUCKET_NAME="react-cicd-terraform-state-1750250738"
TABLE_NAME="terraform-locks"

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: TF_STATE_BUCKET environment variable is required"
    echo "Usage: TF_STATE_BUCKET=your-bucket-name ./scripts/cleanup-aws.sh"
    exit 1
fi

echo "Cleaning up AWS infrastructure..."
echo "Region: $AWS_REGION"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $TABLE_NAME"

echo "Emptying S3 bucket (including all versions)..."

# Method 1: Try using S3 sync with delete (works for most cases)
aws s3 sync --delete --exact-timestamps s3://$BUCKET_NAME s3://$BUCKET_NAME || true

# Method 2: Force empty bucket using lifecycle (more aggressive)
echo "Setting lifecycle configuration to expire all versions immediately..."
cat > /tmp/lifecycle.json << 'EOF'
{
    "Rules": [
        {
            "ID": "DeleteEverything",
            "Status": "Enabled",
            "Filter": {"Prefix": ""},
            "Expiration": {"Days": 1},
            "NoncurrentVersionExpiration": {"NoncurrentDays": 1},
            "AbortIncompleteMultipartUpload": {"DaysAfterInitiation": 1}
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET_NAME" \
    --lifecycle-configuration file:///tmp/lifecycle.json || true

# Method 3: Manual deletion of versions
echo "Attempting to delete all object versions..."
aws s3api list-object-versions \
    --bucket "$BUCKET_NAME" \
    --output text \
    --query 'Versions[].[Key,VersionId]' | \
    while read key version; do
        if [ -n "$key" ] && [ -n "$version" ] && [ "$key" != "None" ] && [ "$version" != "None" ]; then
            echo "Deleting: $key (version: $version)"
            aws s3api delete-object \
                --bucket "$BUCKET_NAME" \
                --key "$key" \
                --version-id "$version" || true
        fi
    done

# Method 4: Delete delete markers
aws s3api list-object-versions \
    --bucket "$BUCKET_NAME" \
    --output text \
    --query 'DeleteMarkers[].[Key,VersionId]' | \
    while read key version; do
        if [ -n "$key" ] && [ -n "$version" ] && [ "$key" != "None" ] && [ "$version" != "None" ]; then
            echo "Deleting delete marker: $key (version: $version)"
            aws s3api delete-object \
                --bucket "$BUCKET_NAME" \
                --key "$key" \
                --version-id "$version" || true
        fi
    done

# Final cleanup
aws s3 rm "s3://$BUCKET_NAME" --recursive || true

echo "Waiting for bucket to be empty..."
sleep 5

echo "Deleting S3 bucket..."
aws s3api delete-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" || true

echo "Deleting DynamoDB table..."
aws dynamodb delete-table \
    --table-name "$TABLE_NAME" \
    --region "$AWS_REGION" || true

echo "Cleanup completed!"

#!/bin/bash

set -e

AWS_REGION="${AWS_REGION:-eu-central-1}"
BUCKET_NAME="${TF_STATE_BUCKET}"
TABLE_NAME="terraform-locks"

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: TF_STATE_BUCKET environment variable is required"
    echo "Usage: TF_STATE_BUCKET=your-bucket-name ./scripts/cleanup-aws-simple.sh"
    exit 1
fi

echo "=== AWS Infrastructure Cleanup ==="
echo "Region: $AWS_REGION"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $TABLE_NAME"
echo ""

# Function to empty S3 bucket completely
empty_bucket() {
    echo "🗑️  Emptying S3 bucket completely..."
    
    # Disable versioning first
    echo "Suspending bucket versioning..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Suspended || true
    
    # Delete all current objects
    echo "Deleting current objects..."
    aws s3 rm "s3://$BUCKET_NAME" --recursive || true
    
    # Delete all versions
    echo "Deleting all object versions..."
    aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --output text \
        --query 'Versions[].[Key,VersionId]' 2>/dev/null | \
        while read key version; do
            if [ "$key" != "None" ] && [ "$version" != "None" ] && [ -n "$key" ] && [ -n "$version" ]; then
                echo "  Deleting: $key (version: $version)"
                aws s3api delete-object \
                    --bucket "$BUCKET_NAME" \
                    --key "$key" \
                    --version-id "$version" >/dev/null 2>&1 || true
            fi
        done
    
    # Delete all delete markers
    echo "Deleting delete markers..."
    aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --output text \
        --query 'DeleteMarkers[].[Key,VersionId]' 2>/dev/null | \
        while read key version; do
            if [ "$key" != "None" ] && [ "$version" != "None" ] && [ -n "$key" ] && [ -n "$version" ]; then
                echo "  Deleting marker: $key (version: $version)"
                aws s3api delete-object \
                    --bucket "$BUCKET_NAME" \
                    --key "$key" \
                    --version-id "$version" >/dev/null 2>&1 || true
            fi
        done
    
    echo "✅ Bucket emptied successfully"
}

# Function to delete S3 bucket
delete_bucket() {
    echo "🗑️  Deleting S3 bucket..."
    
    for i in {1..5}; do
        if aws s3api delete-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" 2>/dev/null; then
            echo "✅ S3 bucket deleted successfully"
            return 0
        else
            echo "  Attempt $i failed, retrying in 5 seconds..."
            sleep 5
        fi
    done
    
    echo "❌ Failed to delete S3 bucket after 5 attempts"
    echo "💡 You may need to delete it manually in the AWS Console"
}

# Function to delete DynamoDB table
delete_table() {
    echo "🗑️  Deleting DynamoDB table..."
    
    if aws dynamodb delete-table \
        --table-name "$TABLE_NAME" \
        --region "$AWS_REGION" >/dev/null 2>&1; then
        echo "✅ DynamoDB table deletion initiated"
    else
        echo "⚠️  DynamoDB table may not exist or already deleted"
    fi
}

# Execute cleanup
echo "Starting cleanup process..."
echo ""

empty_bucket
sleep 2
delete_bucket
sleep 1
delete_table

echo ""
echo "🎉 Cleanup completed!"
echo ""
echo "Next steps:"
echo "1. Verify in AWS Console that resources are deleted"
echo "2. Remove GitHub Secrets if project is finished"
echo "3. Delete local repository if no longer needed"

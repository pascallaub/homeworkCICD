#!/bin/bash

set -e

AWS_REGION="${AWS_REGION:-eu-central-1}"
BUCKET_NAME="${TF_STATE_BUCKET}"
TABLE_NAME="terraform-locks"

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: TF_STATE_BUCKET environment variable is required"
    echo "Usage: TF_STATE_BUCKET=your-bucket-name ./scripts/recreate-backend.sh"
    exit 1
fi

echo "=== Recreating Terraform Backend Infrastructure ==="
echo "Region: $AWS_REGION"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $TABLE_NAME"
echo ""

# Check if bucket exists
echo "🔍 Checking if S3 bucket exists..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ S3 bucket already exists"
else
    echo "🔨 Creating S3 bucket..."
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME"
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi
    
    echo "🔒 Enabling bucket versioning..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    echo "🔐 Enabling bucket encryption..."
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    },
                    "BucketKeyEnabled": true
                }
            ]
        }'
    echo "✅ S3 bucket created and configured"
fi

# Check if DynamoDB table exists
echo "🔍 Checking if DynamoDB table exists..."
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" 2>/dev/null >/dev/null; then
    echo "✅ DynamoDB table already exists"
else
    echo "🔨 Creating DynamoDB table..."
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions \
            AttributeName=LockID,AttributeType=S \
        --key-schema \
            AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput \
            ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$AWS_REGION"
    
    echo "⏳ Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$AWS_REGION"
    echo "✅ DynamoDB table created successfully"
fi

echo ""
echo "🎉 Terraform backend infrastructure is ready!"
echo ""
echo "You can now run:"
echo "  cd terraform"
echo "  terraform init"
echo "  terraform plan"
echo "  terraform apply"

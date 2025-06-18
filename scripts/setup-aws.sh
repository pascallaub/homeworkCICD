#!/bin/bash

set -e

AWS_REGION="${AWS_REGION:-eu-central-1}"
BUCKET_NAME="${TF_STATE_BUCKET:-react-cicd-terraform-state-$(date +%s)}"
TABLE_NAME="terraform-locks"

echo "Setting up AWS infrastructure for Terraform state management..."
echo "Region: $AWS_REGION"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $TABLE_NAME"

echo "Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION"

echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "Enabling encryption on S3 bucket..."
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

echo "Creating DynamoDB table for state locking..."
aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions \
        AttributeName=LockID,AttributeType=S \
    --key-schema \
        AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region "$AWS_REGION"

echo "Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$AWS_REGION"

echo "Setup completed successfully!"
echo ""
echo "Please add the following secrets to your GitHub repository:"
echo "AWS_ACCESS_KEY_ID: <your-access-key-id>"
echo "AWS_SECRET_ACCESS_KEY: <your-secret-access-key>"
echo "AWS_ACCESS_TOKEN: <your-session-token-if-using-temporary-credentials>"
echo "AWS_REGION: $AWS_REGION"
echo "TF_STATE_BUCKET: $BUCKET_NAME"
echo ""
echo "Update terraform/main.tf backend configuration with:"
echo "bucket = \"$BUCKET_NAME\""
echo "region = \"$AWS_REGION\""

#!/bin/bash

set -e

AWS_REGION="${AWS_REGION:-eu-central-1}"
BUCKET_NAME="${TF_STATE_BUCKET}"
TABLE_NAME="terraform-locks"

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: TF_STATE_BUCKET environment variable is required"
    exit 1
fi

echo "Cleaning up AWS infrastructure..."
echo "Region: $AWS_REGION"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $TABLE_NAME"

echo "Emptying S3 bucket..."
aws s3 rm "s3://$BUCKET_NAME" --recursive || true

echo "Deleting S3 bucket..."
aws s3api delete-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" || true

echo "Deleting DynamoDB table..."
aws dynamodb delete-table \
    --table-name "$TABLE_NAME" \
    --region "$AWS_REGION" || true

echo "Cleanup completed!"

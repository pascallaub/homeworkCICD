#!/bin/bash

set -e

AWS_REGION="${AWS_REGION:-eu-central-1}"
PROJECT_NAME="${PROJECT_NAME:-react-cicd}"
KEY_NAME="${PROJECT_NAME}-keypair"

echo "=== Cleaning up existing AWS Key Pairs ==="
echo "Region: $AWS_REGION"
echo "Key Name: $KEY_NAME"
echo ""

# List existing key pairs
echo "🔍 Checking for existing key pairs..."
EXISTING_KEYS=$(aws ec2 describe-key-pairs \
    --region "$AWS_REGION" \
    --query "KeyPairs[?starts_with(KeyName, '${PROJECT_NAME}')].KeyName" \
    --output text 2>/dev/null || echo "")

if [ -z "$EXISTING_KEYS" ]; then
    echo "✅ No existing key pairs found"
else
    echo "🗑️  Found existing key pairs:"
    for key in $EXISTING_KEYS; do
        echo "  - $key"
        echo "    Deleting..."
        aws ec2 delete-key-pair \
            --key-name "$key" \
            --region "$AWS_REGION" || true
        echo "    ✅ Deleted"
    done
fi

echo ""
echo "🎉 Key pair cleanup completed!"
echo ""
echo "You can now run terraform apply again."

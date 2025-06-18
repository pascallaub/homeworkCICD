#!/bin/bash

set -e

AWS_REGION="${AWS_REGION:-eu-central-1}"
PROJECT_NAME="react-cicd"

echo "=== Complete AWS Infrastructure Cleanup ==="
echo "Region: $AWS_REGION"
echo "Project: $PROJECT_NAME"
echo ""

# Function to terminate EC2 instances
cleanup_ec2_instances() {
    echo "🔍 Checking for EC2 instances..."
    
    INSTANCES=$(aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=$PROJECT_NAME" \
                  "Name=instance-state-name,Values=running,stopped,stopping,pending" \
        --query "Reservations[].Instances[].InstanceId" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$INSTANCES" ] && [ "$INSTANCES" != "None" ]; then
        echo "🗑️  Found EC2 instances to terminate:"
        for instance in $INSTANCES; do
            echo "  - $instance"
            aws ec2 terminate-instances \
                --instance-ids "$instance" \
                --region "$AWS_REGION" || true
        done
        
        echo "⏳ Waiting for instances to terminate..."
        for instance in $INSTANCES; do
            aws ec2 wait instance-terminated \
                --instance-ids "$instance" \
                --region "$AWS_REGION" || true
        done
        echo "✅ EC2 instances terminated"
    else
        echo "✅ No EC2 instances found"
    fi
}

# Function to cleanup security groups
cleanup_security_groups() {
    echo "🔍 Checking for security groups..."
    
    SECURITY_GROUPS=$(aws ec2 describe-security-groups \
        --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=$PROJECT_NAME" \
        --query "SecurityGroups[?GroupName!='default'].GroupId" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$SECURITY_GROUPS" ] && [ "$SECURITY_GROUPS" != "None" ]; then
        echo "🗑️  Found security groups to delete:"
        for sg in $SECURITY_GROUPS; do
            echo "  - $sg"
            aws ec2 delete-security-group \
                --group-id "$sg" \
                --region "$AWS_REGION" || true
        done
        echo "✅ Security groups deleted"
    else
        echo "✅ No security groups found"
    fi
}

# Function to cleanup subnets
cleanup_subnets() {
    echo "🔍 Checking for subnets..."
    
    SUBNETS=$(aws ec2 describe-subnets \
        --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=$PROJECT_NAME" \
        --query "Subnets[].SubnetId" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$SUBNETS" ] && [ "$SUBNETS" != "None" ]; then
        echo "🗑️  Found subnets to delete:"
        for subnet in $SUBNETS; do
            echo "  - $subnet"
            aws ec2 delete-subnet \
                --subnet-id "$subnet" \
                --region "$AWS_REGION" || true
        done
        echo "✅ Subnets deleted"
    else
        echo "✅ No subnets found"
    fi
}

# Function to cleanup internet gateways and route tables
cleanup_network() {
    echo "🔍 Checking for VPCs and network components..."
    
    VPCS=$(aws ec2 describe-vpcs \
        --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=$PROJECT_NAME" \
        --query "Vpcs[].VpcId" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$VPCS" ] && [ "$VPCS" != "None" ]; then
        for vpc in $VPCS; do
            echo "🗑️  Cleaning up VPC: $vpc"
            
            # Delete route tables (except main)
            ROUTE_TABLES=$(aws ec2 describe-route-tables \
                --region "$AWS_REGION" \
                --filters "Name=vpc-id,Values=$vpc" \
                --query "RouteTables[?Associations[0].Main!=\`true\`].RouteTableId" \
                --output text 2>/dev/null || echo "")
            
            for rt in $ROUTE_TABLES; do
                if [ "$rt" != "None" ] && [ -n "$rt" ]; then
                    echo "  Deleting route table: $rt"
                    aws ec2 delete-route-table \
                        --route-table-id "$rt" \
                        --region "$AWS_REGION" || true
                fi
            done
            
            # Detach and delete internet gateways
            IGWS=$(aws ec2 describe-internet-gateways \
                --region "$AWS_REGION" \
                --filters "Name=attachment.vpc-id,Values=$vpc" \
                --query "InternetGateways[].InternetGatewayId" \
                --output text 2>/dev/null || echo "")
            
            for igw in $IGWS; do
                if [ "$igw" != "None" ] && [ -n "$igw" ]; then
                    echo "  Detaching and deleting internet gateway: $igw"
                    aws ec2 detach-internet-gateway \
                        --internet-gateway-id "$igw" \
                        --vpc-id "$vpc" \
                        --region "$AWS_REGION" || true
                    aws ec2 delete-internet-gateway \
                        --internet-gateway-id "$igw" \
                        --region "$AWS_REGION" || true
                fi
            done
            
            # Delete VPC
            echo "  Deleting VPC: $vpc"
            aws ec2 delete-vpc \
                --vpc-id "$vpc" \
                --region "$AWS_REGION" || true
        done
        echo "✅ Network components deleted"
    else
        echo "✅ No VPCs found"
    fi
}

# Function to cleanup key pairs
cleanup_key_pairs() {
    echo "🔍 Checking for key pairs..."
    
    KEY_PAIRS=$(aws ec2 describe-key-pairs \
        --region "$AWS_REGION" \
        --query "KeyPairs[?starts_with(KeyName, '$PROJECT_NAME')].KeyName" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$KEY_PAIRS" ] && [ "$KEY_PAIRS" != "None" ]; then
        echo "🗑️  Found key pairs to delete:"
        for key in $KEY_PAIRS; do
            echo "  - $key"
            aws ec2 delete-key-pair \
                --key-name "$key" \
                --region "$AWS_REGION" || true
        done
        echo "✅ Key pairs deleted"
    else
        echo "✅ No key pairs found"
    fi
}

# Execute cleanup in correct order
echo "Starting comprehensive cleanup..."
echo ""

cleanup_ec2_instances
sleep 5
cleanup_security_groups
sleep 2
cleanup_subnets
sleep 2
cleanup_network
sleep 2
cleanup_key_pairs

echo ""
echo "🎉 Comprehensive cleanup completed!"
echo ""
echo "Note: This script only cleans up EC2/VPC resources."
echo "Run ./scripts/cleanup-aws-simple.sh to clean up S3/DynamoDB."

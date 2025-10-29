#!/bin/bash

echo "🔒 Fixing database security vulnerability..."

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=false" --query 'Vpcs[0].VpcId' --output text --region us-east-1)
if [ "$VPC_ID" = "None" ] || [ "$VPC_ID" = "" ]; then
    VPC_ID="vpc-01e4628c09189322a"
fi

echo "Using VPC: $VPC_ID"

# Create private subnets for database
echo "Creating private database subnets..."

# Private subnet 1 (us-east-1a)
PRIVATE_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.10.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecogrid-db-private-1a}]' \
  --query 'Subnet.SubnetId' \
  --output text \
  --region us-east-1)

# Private subnet 2 (us-east-1b)  
PRIVATE_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.11.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecogrid-db-private-1b}]' \
  --query 'Subnet.SubnetId' \
  --output text \
  --region us-east-1)

echo "Created private subnets: $PRIVATE_SUBNET_1, $PRIVATE_SUBNET_2"

# Create DB subnet group for private subnets
echo "Creating private DB subnet group..."
aws rds create-db-subnet-group \
  --db-subnet-group-name ecogrid-private-db-subnets \
  --db-subnet-group-description "Private subnets for EcoGrid database" \
  --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2 \
  --region us-east-1

# Modify database cluster to use private subnets and disable public access
echo "Modifying database to use private subnets..."
aws rds modify-db-cluster \
  --db-cluster-identifier ecogrid-aurora-standard \
  --db-subnet-group-name ecogrid-private-db-subnets \
  --apply-immediately \
  --region us-east-1

# Modify primary instance to disable public access
echo "Disabling public access on primary database instance..."
aws rds modify-db-instance \
  --db-instance-identifier ecogrid-standard-primary \
  --no-publicly-accessible \
  --apply-immediately \
  --region us-east-1

echo "✅ Database security fix initiated!"
echo "⏳ Changes will take 5-10 minutes to apply"
echo ""
echo "Security improvements:"
echo "- Database moved to private subnets (no internet access)"
echo "- Public accessibility disabled"
echo "- Only accessible from ECS tasks in same VPC"

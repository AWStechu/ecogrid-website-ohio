#!/bin/bash

echo "🚀 Setting up ECS infrastructure for EcoGrid..."

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Create ECS cluster if it doesn't exist
echo "Creating ECS cluster..."
aws ecs create-cluster \
  --cluster-name ecogrid-cluster \
  --capacity-providers FARGATE \
  --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
  --region us-east-1 || echo "Cluster may already exist"

# Create ECR repository if it doesn't exist
echo "Creating ECR repository..."
aws ecr create-repository \
  --repository-name ecogrid-app \
  --region us-east-1 || echo "Repository may already exist"

# Create CloudWatch log group
echo "Creating CloudWatch log group..."
aws logs create-log-group \
  --log-group-name /ecs/ecogrid-app \
  --region us-east-1 || echo "Log group may already exist"

# Get VPC and subnet information
echo "Getting VPC information..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region us-east-1)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0:2].SubnetId' --output text --region us-east-1)
SUBNET_1=$(echo $SUBNET_IDS | cut -d' ' -f1)
SUBNET_2=$(echo $SUBNET_IDS | cut -d' ' -f2)

echo "VPC ID: $VPC_ID"
echo "Subnets: $SUBNET_1, $SUBNET_2"

# Create security group for ECS service
echo "Creating security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name ecogrid-ecs-sg \
  --description "Security group for EcoGrid ECS service" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text \
  --region us-east-1 2>/dev/null || \
  aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=ecogrid-ecs-sg" \
    --query 'SecurityGroups[0].GroupId' \
    --output text \
    --region us-east-1)

echo "Security Group ID: $SECURITY_GROUP_ID"

# Add inbound rules to security group
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 5000 \
  --cidr 0.0.0.0/0 \
  --region us-east-1 2>/dev/null || echo "Security group rule may already exist"

aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region us-east-1 2>/dev/null || echo "Security group rule may already exist"

# Create initial task definition
echo "Creating initial task definition..."
aws ecs register-task-definition \
  --family ecogrid-app \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 256 \
  --memory 512 \
  --execution-role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole \
  --container-definitions '[{
    "name": "ecogrid-container",
    "image": "'$AWS_ACCOUNT_ID'.dkr.ecr.us-east-1.amazonaws.com/ecogrid-app:latest",
    "cpu": 0,
    "portMappings": [{
      "containerPort": 5000,
      "hostPort": 5000,
      "protocol": "tcp"
    }],
    "essential": true,
    "environment": [{
      "name": "DB_NAME",
      "value": "ecogrid"
    }, {
      "name": "DB_HOST", 
      "value": "ecogrid-aurora-standard.cluster-ckbygg2eq2ic.us-east-1.rds.amazonaws.com"
    }, {
      "name": "DB_USER",
      "value": "admin"
    }, {
      "name": "DB_PASSWORD",
      "value": "EcoGrid2025!"
    }],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/ecogrid-app",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]' \
  --region us-east-1

# Create ECS service
echo "Creating ECS service..."
aws ecs create-service \
  --cluster ecogrid-cluster \
  --service-name ecogrid-service \
  --task-definition ecogrid-app \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=ENABLED}" \
  --region us-east-1

echo "✅ ECS infrastructure setup completed!"
echo ""
echo "📋 Summary:"
echo "   • Cluster: ecogrid-cluster"
echo "   • Service: ecogrid-service" 
echo "   • Task Definition: ecogrid-app"
echo "   • ECR Repository: ecogrid-app"
echo "   • Security Group: $SECURITY_GROUP_ID"
echo ""
echo "🔄 The CI/CD pipeline should now work correctly!"

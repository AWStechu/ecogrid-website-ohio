#!/bin/bash

set -e

echo "Setting up Blue-Green deployment infrastructure for EcoGrid..."

# Variables
CLUSTER_NAME="ecogrid-cluster"
SERVICE_NAME="ecogrid-service-bg"
ALB_NAME="ecogrid-alb"
CODEDEPLOY_APP="ecogrid-app"
CODEDEPLOY_DG="ecogrid-bg-dg"
REGION="us-east-1"

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $ACCOUNT_ID"

# Create CodeDeploy application
echo "Creating CodeDeploy application..."
aws deploy create-application \
  --application-name $CODEDEPLOY_APP \
  --compute-platform ECS \
  --region $REGION || echo "Application already exists"

# Get ALB ARN
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names $ALB_NAME \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text \
  --region $REGION)

echo "ALB ARN: $ALB_ARN"

# Get target group ARNs
PROD_TG_ARN=$(aws elbv2 describe-target-groups \
  --names ecogrid-tg \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text \
  --region $REGION)

echo "Production Target Group ARN: $PROD_TG_ARN"

# Create test target group for blue-green
echo "Creating test target group..."
TEST_TG_ARN=$(aws elbv2 create-target-group \
  --name ecogrid-tg-test \
  --protocol HTTP \
  --port 5000 \
  --vpc-id $(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region $REGION) \
  --target-type ip \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --region $REGION \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text) || \
aws elbv2 describe-target-groups \
  --names ecogrid-tg-test \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text \
  --region $REGION

echo "Test Target Group ARN: $TEST_TG_ARN"

# Create test listener (port 8080)
echo "Creating test listener..."
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 8080 \
  --default-actions Type=forward,TargetGroupArn=$TEST_TG_ARN \
  --region $REGION || echo "Test listener already exists"

# Create CodeDeploy service role
echo "Creating CodeDeploy service role..."
cat > codedeploy-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name CodeDeployServiceRoleForECS \
  --assume-role-policy-document file://codedeploy-trust-policy.json || echo "Role already exists"

aws iam attach-role-policy \
  --role-name CodeDeployServiceRoleForECS \
  --policy-arn arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS

# Create deployment group
echo "Creating CodeDeploy deployment group..."
cat > deployment-group-config.json << EOF
{
  "applicationName": "$CODEDEPLOY_APP",
  "deploymentGroupName": "$CODEDEPLOY_DG",
  "serviceRoleArn": "arn:aws:iam::$ACCOUNT_ID:role/CodeDeployServiceRoleForECS",
  "deploymentConfigName": "CodeDeployDefault.ECSBlueGreenCanary10Percent5Minutes",
  "blueGreenDeploymentConfiguration": {
    "terminateBlueInstancesOnDeploymentSuccess": {
      "action": "TERMINATE",
      "terminationWaitTimeInMinutes": 5
    },
    "deploymentReadyOption": {
      "actionOnTimeout": "CONTINUE_DEPLOYMENT"
    },
    "greenFleetProvisioningOption": {
      "action": "COPY_AUTO_SCALING_GROUP"
    }
  },
  "loadBalancerInfo": {
    "targetGroupInfoList": [
      {
        "name": "ecogrid-tg"
      }
    ]
  },
  "ecsServices": [
    {
      "serviceName": "$SERVICE_NAME",
      "clusterName": "$CLUSTER_NAME"
    }
  ]
}
EOF

aws deploy create-deployment-group \
  --cli-input-json file://deployment-group-config.json \
  --region $REGION || echo "Deployment group already exists"

# Create ECS service for blue-green deployment
echo "Creating ECS service for blue-green deployment..."

# Get subnet IDs
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=default-for-az,Values=true" \
  --query 'Subnets[].SubnetId' \
  --output text \
  --region $REGION | tr '\t' ',')

# Get security group ID
SG_ID=$(aws ec2 describe-security-groups \
  --group-names default \
  --query 'SecurityGroups[0].GroupId' \
  --output text \
  --region $REGION)

cat > service-config.json << EOF
{
  "serviceName": "$SERVICE_NAME",
  "cluster": "$CLUSTER_NAME",
  "taskDefinition": "ecogrid-app-bg",
  "desiredCount": 2,
  "launchType": "FARGATE",
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": ["$(echo $SUBNET_IDS | sed 's/,/","/g')"],
      "securityGroups": ["$SG_ID"],
      "assignPublicIp": "ENABLED"
    }
  },
  "loadBalancers": [
    {
      "targetGroupArn": "$PROD_TG_ARN",
      "containerName": "ecogrid-container",
      "containerPort": 5000
    }
  ],
  "deploymentConfiguration": {
    "deploymentCircuitBreaker": {
      "enable": true,
      "rollback": true
    }
  },
  "enableExecuteCommand": true
}
EOF

aws ecs create-service \
  --cli-input-json file://service-config.json \
  --region $REGION || echo "Service already exists"

# Clean up temporary files
rm -f codedeploy-trust-policy.json deployment-group-config.json service-config.json

echo "Blue-Green deployment infrastructure setup completed!"
echo ""
echo "Next steps:"
echo "1. Update your task definition with correct account ID and subnets"
echo "2. Update appspec-bg.yml with correct subnet and security group IDs"
echo "3. Commit and push to trigger blue-green deployment"
echo ""
echo "Production URL: http://ecogrid-alb-492743554.us-east-1.elb.amazonaws.com"
echo "Test URL: http://ecogrid-alb-492743554.us-east-1.elb.amazonaws.com:8080"

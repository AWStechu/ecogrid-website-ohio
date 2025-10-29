#!/bin/bash

# EcoGrid Deployment Script
set -e

# Configuration
AWS_REGION="us-east-1"
ECR_REPOSITORY="ecogrid-app"
ECS_TASK_DEFINITION="ecogrid-app-bg"
CODEDEPLOY_APPLICATION="ecogrid-app"
CODEDEPLOY_DEPLOYMENT_GROUP="ecogrid-deployment-gp"
AWS_ACCOUNT_ID="442042546183"

# Get latest task definition
echo "Getting latest task definition..."
LATEST_TASK_DEF="arn:aws:ecs:us-east-1:442042546183:task-definition/ecogrid-app-bg:14"

echo "Using task definition: $LATEST_TASK_DEF"

# Create AppSpec content
APPSPEC_CONTENT=$(cat << EOF
{
  "version": "0.0",
  "Resources": [
    {
      "TargetService": {
        "Type": "AWS::ECS::Service",
        "Properties": {
          "TaskDefinition": "$LATEST_TASK_DEF",
          "LoadBalancerInfo": {
            "ContainerName": "ecogrid-container",
            "ContainerPort": 5000
          },
          "PlatformVersion": "1.4.0"
        }
      }
    }
  ]
}
EOF
)

# Create deployment
echo "Creating CodeDeploy deployment..."
DEPLOYMENT_ID=$(aws deploy create-deployment \
  --application-name $CODEDEPLOY_APPLICATION \
  --deployment-group-name $CODEDEPLOY_DEPLOYMENT_GROUP \
  --revision "revisionType=AppSpecContent,appSpecContent={content=\"$(echo $APPSPEC_CONTENT | jq -c . | sed 's/"/\\"/g')\"}" \
  --query 'deploymentId' \
  --output text \
  --region $AWS_REGION)

echo "Deployment created: $DEPLOYMENT_ID"
echo "Monitor deployment: aws deploy get-deployment --deployment-id $DEPLOYMENT_ID --region $AWS_REGION"

# Optional: Wait for deployment
if [ "$1" = "--wait" ]; then
  echo "Waiting for deployment to complete..."
  aws deploy wait deployment-successful --deployment-id $DEPLOYMENT_ID --region $AWS_REGION
  echo "Deployment completed successfully!"
fi

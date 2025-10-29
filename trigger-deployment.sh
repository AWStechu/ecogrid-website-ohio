#!/bin/bash

# Trigger EcoGrid Deployment Script
set -e

# Configuration
AWS_REGION="us-east-1"
CODEDEPLOY_APPLICATION="ecogrid-app"
CODEDEPLOY_DEPLOYMENT_GROUP="ecogrid-deployment-gp"

# Get latest task definition
echo "🔍 Getting latest task definition..."
LATEST_TASK_DEF=$(aws ecs describe-task-definition \
  --task-definition ecogrid-app-bg \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text \
  --region $AWS_REGION)

echo "📋 Using task definition: $LATEST_TASK_DEF"

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
echo "🚀 Creating CodeDeploy deployment..."
DEPLOYMENT_ID=$(aws deploy create-deployment \
  --application-name $CODEDEPLOY_APPLICATION \
  --deployment-group-name $CODEDEPLOY_DEPLOYMENT_GROUP \
  --revision "revisionType=AppSpecContent,appSpecContent={content=\"$(echo $APPSPEC_CONTENT | jq -c . | sed 's/"/\\"/g')\"}" \
  --query 'deploymentId' \
  --output text \
  --region $AWS_REGION)

echo "✅ Deployment created: $DEPLOYMENT_ID"
echo "🔗 Monitor: https://console.aws.amazon.com/codesuite/codedeploy/deployments/$DEPLOYMENT_ID"
echo "📊 CLI: aws deploy get-deployment --deployment-id $DEPLOYMENT_ID --region $AWS_REGION"

# Optional: Wait for deployment
if [ "$1" = "--wait" ]; then
  echo "⏳ Waiting for deployment to complete..."
  aws deploy wait deployment-successful --deployment-id $DEPLOYMENT_ID --region $AWS_REGION
  echo "🎉 Deployment completed successfully!"
fi

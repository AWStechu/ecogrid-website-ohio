#!/bin/bash

set -e

echo "Rolling back EcoGrid deployment..."

# Variables
CODEDEPLOY_APP="ecogrid-app"
REGION="us-east-1"

# Get the latest deployment
DEPLOYMENT_ID=$(aws deploy list-deployments \
  --application-name $CODEDEPLOY_APP \
  --deployment-group-name ecogrid-bg-dg \
  --include-only-statuses Succeeded \
  --query 'deployments[0]' \
  --output text \
  --region $REGION)

if [ "$DEPLOYMENT_ID" == "None" ] || [ -z "$DEPLOYMENT_ID" ]; then
  echo "No successful deployment found to rollback to"
  exit 1
fi

echo "Latest successful deployment: $DEPLOYMENT_ID"

# Stop current deployment if in progress
CURRENT_DEPLOYMENT=$(aws deploy list-deployments \
  --application-name $CODEDEPLOY_APP \
  --deployment-group-name ecogrid-bg-dg \
  --include-only-statuses InProgress \
  --query 'deployments[0]' \
  --output text \
  --region $REGION)

if [ "$CURRENT_DEPLOYMENT" != "None" ] && [ -n "$CURRENT_DEPLOYMENT" ]; then
  echo "Stopping current deployment: $CURRENT_DEPLOYMENT"
  aws deploy stop-deployment \
    --deployment-id $CURRENT_DEPLOYMENT \
    --auto-rollback-enabled \
    --region $REGION
fi

# Create rollback deployment
echo "Creating rollback deployment..."
ROLLBACK_DEPLOYMENT_ID=$(aws deploy create-deployment \
  --application-name $CODEDEPLOY_APP \
  --deployment-group-name ecogrid-bg-dg \
  --deployment-config-name CodeDeployDefault.ECSBlueGreenCanary10Percent5Minutes \
  --description "Rollback deployment" \
  --auto-rollback-configuration enabled=true,events=DEPLOYMENT_FAILURE,DEPLOYMENT_STOP_ON_ALARM \
  --query 'deploymentId' \
  --output text \
  --region $REGION)

echo "Rollback deployment started: $ROLLBACK_DEPLOYMENT_ID"

# Wait for rollback to complete
echo "Waiting for rollback to complete..."
aws deploy wait deployment-successful --deployment-id $ROLLBACK_DEPLOYMENT_ID --region $REGION

echo "Rollback completed successfully!"
echo "Application should now be running the previous version"

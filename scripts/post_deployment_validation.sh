#!/bin/bash

echo "Running post-deployment validation..."

# Validate new deployment is running
echo "Checking ECS service status..."
SERVICE_STATUS=$(aws ecs describe-services --cluster ecogrid-cluster --services ecogrid-service-bg --query 'services[0].status' --output text --region us-east-1)

if [ "$SERVICE_STATUS" != "ACTIVE" ]; then
    echo "ECS service is not active: $SERVICE_STATUS"
    exit 1
fi

# Check running task count
RUNNING_COUNT=$(aws ecs describe-services --cluster ecogrid-cluster --services ecogrid-service-bg --query 'services[0].runningCount' --output text --region us-east-1)

if [ "$RUNNING_COUNT" -lt 1 ]; then
    echo "No running tasks found"
    exit 1
fi

echo "Post-deployment validation passed!"
exit 0

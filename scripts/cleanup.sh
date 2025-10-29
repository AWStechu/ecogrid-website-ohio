#!/bin/bash

echo "Running cleanup tasks..."

# Clean up old task definitions (keep last 5)
echo "Cleaning up old task definitions..."
aws ecs list-task-definitions --family-prefix ecogrid-app-bg --status ACTIVE --region us-east-1 --query 'taskDefinitionArns[:-5]' --output text | xargs -r -n1 aws ecs deregister-task-definition --task-definition --region us-east-1

# Clean up old ECR images (keep last 10)
echo "Cleaning up old container images..."
aws ecr list-images --repository-name ecogrid-app --region us-east-1 --query 'imageIds[:-10]' --output json | jq -r '.[] | select(.imageTag != null) | .imageTag' | xargs -r -I {} aws ecr batch-delete-image --repository-name ecogrid-app --image-ids imageTag={} --region us-east-1

echo "Cleanup completed!"
exit 0

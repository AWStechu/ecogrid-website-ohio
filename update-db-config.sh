#!/bin/bash

# Script to update application configuration with new Aurora cluster endpoint

if [ $# -eq 0 ]; then
    echo "Usage: $0 <new-aurora-endpoint>"
    echo "Example: $0 ecogrid-aurora-cluster.cluster-abc123.us-east-1.rds.amazonaws.com"
    exit 1
fi

NEW_ENDPOINT=$1

echo "Updating application configuration..."

# Update app.py with new endpoint
sed -i.bak "s/ecogrid-aurora-cluster.cluster-xxxxxxxxx.us-east-1.rds.amazonaws.com/$NEW_ENDPOINT/g" app.py

# Update ECS task definition
cat > new-aurora-taskdef.json << EOF
{
  "family": "ecogrid-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::442042546183:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::442042546183:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "ecogrid-container",
      "image": "442042546183.dkr.ecr.us-east-1.amazonaws.com/ecogrid-repo:latest",
      "portMappings": [
        {
          "containerPort": 5000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DB_HOST",
          "value": "$NEW_ENDPOINT"
        },
        {
          "name": "DB_USER",
          "value": "admin"
        },
        {
          "name": "DB_PASSWORD",
          "value": "EcoGrid2025!"
        },
        {
          "name": "DB_NAME",
          "value": "ecogrid"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/ecogrid-task",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "essential": true
    }
  ]
}
EOF

echo "Configuration updated!"
echo "New Aurora endpoint: $NEW_ENDPOINT"
echo ""
echo "Next steps:"
echo "1. Register new task definition: aws ecs register-task-definition --cli-input-json file://new-aurora-taskdef.json"
echo "2. Update ECS service to use new task definition"
echo "3. Commit and push changes to trigger deployment"

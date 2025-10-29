#!/bin/bash

echo "Setting up auto scaling for blue-green service (3-10 instances)..."

# Register scalable target for blue-green service
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/ecogrid-cluster/ecogrid-service-bg \
  --min-capacity 3 \
  --max-capacity 10 \
  --region us-east-1

# Create CPU-based scaling policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/ecogrid-cluster/ecogrid-service-bg \
  --policy-name ecogrid-bg-cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 60.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
    },
    "ScaleOutCooldown": 180,
    "ScaleInCooldown": 300
  }' \
  --region us-east-1

# Create Memory-based scaling policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/ecogrid-cluster/ecogrid-service-bg \
  --policy-name ecogrid-bg-memory-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageMemoryUtilization"
    },
    "ScaleOutCooldown": 180,
    "ScaleInCooldown": 300
  }' \
  --region us-east-1

# Update service to desired count of 3
aws ecs update-service \
  --cluster ecogrid-cluster \
  --service ecogrid-service-bg \
  --desired-count 3 \
  --region us-east-1

echo "Auto scaling configured: 3-10 instances with CPU and Memory scaling!"

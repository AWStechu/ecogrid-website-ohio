#!/bin/bash

echo "🚀 Enabling High Scalability for EcoGrid Website..."
echo "=================================================="

# Step 1: Register scalable target (3-10 instances)
echo "📊 Setting up auto-scaling target (3-10 instances)..."
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/ecogrid-cluster/ecogrid-service-bg \
  --min-capacity 3 \
  --max-capacity 10 \
  --region us-east-1

if [ $? -eq 0 ]; then
  echo "✅ Auto-scaling target registered successfully"
else
  echo "❌ Failed to register auto-scaling target"
  exit 1
fi

# Step 2: CPU-based scaling policy (scale at 60% CPU)
echo "🔥 Creating CPU-based scaling policy..."
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

if [ $? -eq 0 ]; then
  echo "✅ CPU scaling policy created"
else
  echo "❌ Failed to create CPU scaling policy"
fi

# Step 3: Memory-based scaling policy (scale at 70% Memory)
echo "💾 Creating Memory-based scaling policy..."
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

if [ $? -eq 0 ]; then
  echo "✅ Memory scaling policy created"
else
  echo "❌ Failed to create Memory scaling policy"
fi

# Step 4: Scale service to 3 instances immediately
echo "📈 Scaling service to 3 instances..."
aws ecs update-service \
  --cluster ecogrid-cluster \
  --service ecogrid-service-bg \
  --desired-count 3 \
  --region us-east-1

if [ $? -eq 0 ]; then
  echo "✅ Service scaled to 3 instances"
else
  echo "❌ Failed to scale service"
fi

# Step 5: Verify scaling configuration
echo "🔍 Verifying auto-scaling configuration..."
aws application-autoscaling describe-scalable-targets \
  --service-namespace ecs \
  --resource-ids service/ecogrid-cluster/ecogrid-service-bg \
  --region us-east-1 \
  --query 'ScalableTargets[0].[ResourceId,MinCapacity,MaxCapacity]' \
  --output table

echo ""
echo "🎉 High Scalability Configuration Complete!"
echo "=================================================="
echo "📊 Scaling Configuration:"
echo "   • Minimum Instances: 3"
echo "   • Maximum Instances: 10"
echo "   • CPU Threshold: 60%"
echo "   • Memory Threshold: 70%"
echo "   • Scale Out: 3 minutes"
echo "   • Scale In: 5 minutes"
echo ""
echo "🚀 Your EcoGrid website is now highly scalable!"

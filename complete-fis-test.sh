#!/bin/bash

echo "🧪 Complete FIS Auto-Scaling Test for EcoGrid"
echo "============================================="

# Create FIS template
echo "🔬 Creating FIS experiment template..."
TEMPLATE_ID=$(aws fis create-experiment-template \
  --cli-input-json file://simple-fis-template.json \
  --region us-east-1 \
  --query 'experimentTemplate.id' \
  --output text)

if [ -z "$TEMPLATE_ID" ]; then
  echo "❌ Failed to create FIS template"
  exit 1
fi

echo "✅ FIS Template: $TEMPLATE_ID"

# Check baseline
echo ""
echo "📊 Baseline ECS tasks:"
aws ecs describe-services \
  --cluster ecogrid-cluster \
  --services ecogrid-service-bg \
  --query 'services[0].[runningCount,desiredCount]' \
  --output table \
  --region us-east-1

# Start experiment
echo ""
echo "🚀 Starting FIS experiment..."
EXPERIMENT_ID=$(aws fis start-experiment \
  --experiment-template-id $TEMPLATE_ID \
  --region us-east-1 \
  --query 'experiment.id' \
  --output text)

echo "✅ Experiment started: $EXPERIMENT_ID"
echo "📊 This will terminate 50% of tasks to trigger auto-scaling"

# Quick monitoring
echo ""
echo "⏱️  Monitoring for 1 minute..."
sleep 30
echo "📊 After 30 seconds:"
aws ecs describe-services \
  --cluster ecogrid-cluster \
  --services ecogrid-service-bg \
  --query 'services[0].[runningCount,desiredCount]' \
  --output table \
  --region us-east-1

sleep 30
echo "📊 After 60 seconds:"
aws ecs describe-services \
  --cluster ecogrid-cluster \
  --services ecogrid-service-bg \
  --query 'services[0].[runningCount,desiredCount]' \
  --output table \
  --region us-east-1

echo ""
echo "🎉 FIS Auto-Scaling Test Complete!"
echo "📊 Check scaling activity:"
echo "aws application-autoscaling describe-scaling-activities --service-namespace ecs --resource-id service/ecogrid-cluster/ecogrid-service-bg --region us-east-1"

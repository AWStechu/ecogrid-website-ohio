#!/bin/bash

echo "🧪 Running FIS Auto-Scaling Test..."
echo "==================================="

# Check if template ID exists
if [ ! -f "fis-template-id.txt" ]; then
  echo "❌ FIS template not found. Run setup-fis-autoscaling-test.sh first"
  exit 1
fi

TEMPLATE_ID=$(cat fis-template-id.txt)
echo "📋 Using FIS Template: $TEMPLATE_ID"

# Start monitoring in background
echo "📊 Starting monitoring..."
./monitor-autoscaling.sh > fis-monitoring.log 2>&1 &
MONITOR_PID=$!

# Start FIS experiment
echo "🚀 Starting FIS experiment..."
EXPERIMENT_ID=$(aws fis start-experiment \
  --experiment-template-id $TEMPLATE_ID \
  --region us-east-1 \
  --query 'experiment.id' \
  --output text)

if [ $? -eq 0 ]; then
  echo "✅ FIS Experiment started: $EXPERIMENT_ID"
  echo "⏱️  Duration: 10 minutes"
  echo "📊 Monitor progress: tail -f fis-monitoring.log"
  echo ""
  echo "🔍 Check experiment status:"
  echo "   aws fis get-experiment --id $EXPERIMENT_ID --region us-east-1"
else
  echo "❌ Failed to start FIS experiment"
  kill $MONITOR_PID 2>/dev/null
  exit 1
fi

# Wait for experiment to complete
echo "⏳ Waiting for experiment to complete (10 minutes)..."
sleep 600

# Stop monitoring
kill $MONITOR_PID 2>/dev/null

echo ""
echo "🎉 FIS Auto-Scaling Test Complete!"
echo "=================================="
echo "📊 Check results:"
echo "   • Monitoring log: cat fis-monitoring.log"
echo "   • Experiment details: aws fis get-experiment --id $EXPERIMENT_ID --region us-east-1"
echo "   • Auto-scaling activity: aws application-autoscaling describe-scaling-activities --service-namespace ecs --resource-id service/ecogrid-cluster/ecogrid-service-bg --region us-east-1"

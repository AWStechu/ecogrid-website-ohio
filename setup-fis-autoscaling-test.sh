#!/bin/bash

echo "🧪 Setting up AWS FIS Auto-Scaling Test for EcoGrid..."
echo "====================================================="

# Step 1: Create FIS Service Role (if not exists)
echo "🔐 Creating FIS Service Role..."
cat > fis-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "fis.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name FISExperimentRole \
  --assume-role-policy-document file://fis-trust-policy.json \
  --region us-east-1 2>/dev/null || echo "Role may already exist"

# Attach necessary policies
aws iam attach-role-policy \
  --role-name FISExperimentRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorECSAccess \
  --region us-east-1

aws iam attach-role-policy \
  --role-name FISExperimentRole \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess \
  --region us-east-1

# Step 2: Create CloudWatch Alarm for stop condition
echo "📊 Creating CloudWatch Alarm..."
aws cloudwatch put-metric-alarm \
  --alarm-name "ECS-CPU-High" \
  --alarm-description "Stop FIS experiment if CPU too high" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 90 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=ServiceName,Value=ecogrid-service-bg Name=ClusterName,Value=ecogrid-cluster \
  --region us-east-1

# Step 3: Create FIS Experiment Template
echo "🔬 Creating FIS Experiment Template..."
TEMPLATE_ID=$(aws fis create-experiment-template \
  --cli-input-json file://fis-autoscaling-test.json \
  --region us-east-1 \
  --query 'experimentTemplate.id' \
  --output text)

if [ $? -eq 0 ]; then
  echo "✅ FIS Experiment Template created: $TEMPLATE_ID"
  echo "$TEMPLATE_ID" > fis-template-id.txt
else
  echo "❌ Failed to create FIS template"
  exit 1
fi

# Step 4: Create monitoring script
cat > monitor-autoscaling.sh << 'EOF'
#!/bin/bash
echo "📊 Monitoring Auto-Scaling During FIS Test..."
echo "============================================="

for i in {1..20}; do
  echo "⏱️  Minute $i:"
  
  # Check task count
  aws ecs describe-services \
    --cluster ecogrid-cluster \
    --services ecogrid-service-bg \
    --query 'services[0].[runningCount,desiredCount]' \
    --output table \
    --region us-east-1
  
  # Check CPU utilization
  aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value=ecogrid-service-bg Name=ClusterName,Value=ecogrid-cluster \
    --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average \
    --region us-east-1 \
    --query 'Datapoints[0].Average' \
    --output text | xargs -I {} echo "CPU: {}%"
  
  echo "---"
  sleep 60
done
EOF

chmod +x monitor-autoscaling.sh

echo ""
echo "🎉 FIS Auto-Scaling Test Setup Complete!"
echo "========================================"
echo "📋 What was created:"
echo "   • FIS Experiment Template: $TEMPLATE_ID"
echo "   • CloudWatch Alarm: ECS-CPU-High"
echo "   • IAM Role: FISExperimentRole"
echo "   • Monitoring Script: monitor-autoscaling.sh"
echo ""
echo "🚀 To run the test:"
echo "   1. Start monitoring: ./monitor-autoscaling.sh &"
echo "   2. Run experiment: aws fis start-experiment --experiment-template-id $TEMPLATE_ID --region us-east-1"
echo ""
echo "📊 Expected behavior:"
echo "   • CPU stress injected → CPU >60% → Auto-scaling triggers"
echo "   • Tasks scale from 3 → up to 10 instances"
echo "   • After 10 minutes → stress stops → scales back down"

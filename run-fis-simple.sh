#!/bin/bash

echo "🧪 Simple FIS Auto-Scaling Test for EcoGrid"
echo "==========================================="

# Step 1: Create FIS Role (run with fresh AWS credentials)
echo "🔐 Step 1: Create FIS Role..."
echo "Run this command with fresh AWS credentials:"
echo ""
echo "aws iam create-role --role-name FISExperimentRole --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"fis.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}' --region us-east-1"
echo ""
echo "aws iam attach-role-policy --role-name FISExperimentRole --policy-arn arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorECSAccess --region us-east-1"
echo ""

# Step 2: Create FIS Template
echo "🔬 Step 2: Create FIS Template..."
echo "aws fis create-experiment-template --cli-input-json file://simple-fis-template.json --region us-east-1"
echo ""

# Step 3: Monitor before test
echo "📊 Step 3: Check current ECS tasks..."
echo "aws ecs describe-services --cluster ecogrid-cluster --services ecogrid-service-bg --query 'services[0].[runningCount,desiredCount]' --output table --region us-east-1"
echo ""

# Step 4: Run FIS experiment
echo "🚀 Step 4: Start FIS experiment (replace TEMPLATE_ID)..."
echo "aws fis start-experiment --experiment-template-id TEMPLATE_ID --region us-east-1"
echo ""

# Step 5: Monitor during test
echo "📈 Step 5: Monitor auto-scaling activity..."
echo "aws application-autoscaling describe-scaling-activities --service-namespace ecs --resource-id service/ecogrid-cluster/ecogrid-service-bg --region us-east-1"
echo ""

echo "💡 Complete workflow:"
echo "1. Set AWS credentials"
echo "2. Run the commands above in order"
echo "3. Monitor ECS service scaling from 3 → up to 10 tasks"
echo "4. After 5 minutes, tasks should scale back down"

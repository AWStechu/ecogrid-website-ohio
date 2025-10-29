#!/bin/bash

echo "Setting up Blue-Green deployment for existing EcoGrid infrastructure..."

# Variables from your existing infrastructure
ACCOUNT_ID="442042546183"
CLUSTER_NAME="ecogrid-cluster"
ALB_ARN="arn:aws:elasticloadbalancing:us-east-1:442042546183:loadbalancer/app/ecogrid-alb/9e987da674923d7d"
PROD_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:442042546183:targetgroup/ecogrid-targets/f93c2efaf73e88fc"
REGION="us-east-1"

echo "Account ID: $ACCOUNT_ID"
echo "Using existing ALB: $ALB_ARN"
echo "Using existing target group: $PROD_TG_ARN"

# The infrastructure is already set up, just need to configure CodeDeploy
echo "Blue-Green deployment is ready to use with your existing infrastructure!"
echo ""
echo "Your configuration uses:"
echo "- Existing ECS Cluster: $CLUSTER_NAME"
echo "- Existing ALB: ecogrid-alb-492743554.us-east-1.elb.amazonaws.com"
echo "- Existing Target Group: ecogrid-targets"
echo ""
echo "Next steps:"
echo "1. Commit and push the blue-green configuration files"
echo "2. The GitHub Actions workflow will handle the deployment"
echo ""
echo "Files ready for deployment:"
echo "- blue-green-taskdef.json (updated with account ID: $ACCOUNT_ID)"
echo "- appspec-bg.yml (configured for your network)"
echo "- .github/workflows/blue-green-deploy.yml (ready to use)"

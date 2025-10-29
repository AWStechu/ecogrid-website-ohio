#!/bin/bash

echo "Fixing ALB routing for whatsnewcustomer.com domain..."

# Note: AWS credentials should be set via environment variables or AWS CLI profile
# export AWS_ACCESS_KEY_ID=<your-access-key>
# export AWS_SECRET_ACCESS_KEY=<your-secret-key>
# export AWS_SESSION_TOKEN=<your-session-token>

# ALB and Target Group ARNs
ALB_ARN="arn:aws:elasticloadbalancing:us-east-1:442042546183:loadbalancer/app/ecogrid-alb/9e987da674923d7d"
LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:442042546183:listener/app/ecogrid-alb/9e987da674923d7d/373b67ef5fe1ab86"
ACTIVE_TARGET_GROUP="arn:aws:elasticloadbalancing:us-east-1:442042546183:targetgroup/ecogrid-targets/f93c2efaf73e88fc"
ALT_TARGET_GROUP="arn:aws:elasticloadbalancing:us-east-1:442042546183:targetgroup/ecogrid-targets-alt/98097439d64bf8b5"

echo "Step 1: Checking current target group health..."
aws elbv2 describe-target-health --target-group-arn $ACTIVE_TARGET_GROUP --region us-east-1
aws elbv2 describe-target-health --target-group-arn $ALT_TARGET_GROUP --region us-east-1

echo "Step 2: Updating listener to route all traffic to active target group..."
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$ACTIVE_TARGET_GROUP \
  --region us-east-1

echo "Step 3: Checking for any host-based rules that might route whatsnewcustomer.com differently..."
aws elbv2 describe-rules --listener-arn $LISTENER_ARN --region us-east-1

echo "ALB routing fix completed!"
echo "Both domains should now route to the same target group."
echo ""
echo "Test the domains:"
echo "- ELB: http://ecogrid-alb-492743554.us-east-1.elb.amazonaws.com"
echo "- Custom: http://whatsnewcustomer.com"

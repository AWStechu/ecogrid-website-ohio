# Blue-Green Deployment for EcoGrid

This document describes the blue-green deployment architecture implemented for zero-downtime deployments.

## Architecture Overview

The blue-green deployment uses:
- **AWS CodeDeploy** for orchestrating deployments
- **Application Load Balancer (ALB)** with two target groups (production and test)
- **ECS Fargate** services for running containers
- **GitHub Actions** for CI/CD pipeline integration

## Components

### 1. Target Groups
- **Production Target Group**: `ecogrid-tg` (port 80)
- **Test Target Group**: `ecogrid-tg-test` (port 8080)

### 2. ECS Services
- **Blue-Green Service**: `ecogrid-service-bg`
- **Task Definition**: `ecogrid-app-bg`

### 3. CodeDeploy Configuration
- **Application**: `ecogrid-app`
- **Deployment Group**: `ecogrid-bg-dg`
- **Deployment Config**: `CodeDeployDefault.ECSBlueGreenCanary10Percent5Minutes`

## Deployment Process

1. **Build Phase**: GitHub Actions builds and pushes new container image
2. **Task Definition**: New task definition created with updated image
3. **Green Deployment**: CodeDeploy creates new tasks in green environment
4. **Health Checks**: Automated health checks validate green environment
5. **Traffic Shift**: 10% traffic shifted to green, then 100% after 5 minutes
6. **Blue Termination**: Old blue environment terminated after successful deployment

## Setup Instructions

1. **Run Infrastructure Setup**:
   ```bash
   ./setup-blue-green.sh
   ```

2. **Update Configuration**:
   - Get your AWS account ID and update `blue-green-taskdef.json`
   - Update subnet and security group IDs in `appspec-bg.yml`

3. **Configure GitHub Secrets**:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

4. **Trigger Deployment**:
   ```bash
   git add .
   git commit -m "Enable blue-green deployment"
   git push origin main
   ```

## Monitoring Deployment

### GitHub Actions
Monitor deployment progress in the Actions tab of your repository.

### AWS Console
1. **CodeDeploy Console**: View deployment status and logs
2. **ECS Console**: Monitor service and task health
3. **ALB Console**: Check target group health

### CLI Monitoring
```bash
# Check deployment status
aws deploy get-deployment --deployment-id <deployment-id>

# Monitor ECS service
aws ecs describe-services --cluster ecogrid-cluster --services ecogrid-service-bg

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## Testing

### Health Check Endpoint
```bash
curl http://ecogrid-alb-492743554.us-east-1.elb.amazonaws.com/health
```

### Test Environment (During Deployment)
```bash
curl http://ecogrid-alb-492743554.us-east-1.elb.amazonaws.com:8080/
```

## Rollback

### Automatic Rollback
Automatic rollback occurs on:
- Health check failures
- Deployment errors
- CloudWatch alarms (if configured)

### Manual Rollback
```bash
./rollback-deployment.sh
```

## Deployment Hooks

### Pre-deployment (`scripts/pre_deployment_check.sh`)
- Database connectivity check
- Container image validation

### Post-deployment (`scripts/post_deployment_validation.sh`)
- ECS service status validation
- Running task count verification

### Health Check (`scripts/health_check.sh`)
- Application health endpoint testing
- Functional validation

### Cleanup (`scripts/cleanup.sh`)
- Old task definition cleanup
- ECR image cleanup

## Benefits

1. **Zero Downtime**: Traffic switches seamlessly between environments
2. **Automated Rollback**: Failures trigger automatic rollback
3. **Gradual Traffic Shift**: Canary deployment reduces risk
4. **Health Validation**: Comprehensive health checks before traffic shift
5. **Easy Rollback**: Quick manual rollback capability

## Troubleshooting

### Common Issues

1. **Health Check Failures**:
   - Check application logs in CloudWatch
   - Verify database connectivity
   - Ensure health endpoint returns 200

2. **Task Launch Failures**:
   - Check ECS service events
   - Verify task definition configuration
   - Check IAM permissions

3. **Target Group Health**:
   - Verify security group rules
   - Check ALB health check configuration
   - Ensure container port mapping

### Logs Location
- **ECS Logs**: CloudWatch Logs `/ecs/ecogrid-app-bg`
- **CodeDeploy Logs**: CodeDeploy console deployment details
- **ALB Logs**: S3 bucket (if enabled)

## Configuration Files

- `blue-green-taskdef.json`: ECS task definition for blue-green deployment
- `appspec-bg.yml`: CodeDeploy application specification
- `.github/workflows/blue-green-deploy.yml`: GitHub Actions workflow
- `buildspec-bg.yml`: CodeBuild specification for blue-green
- `scripts/`: Deployment hook scripts

## Security Considerations

1. **IAM Roles**: Ensure proper permissions for CodeDeploy and ECS
2. **Security Groups**: Configure appropriate network access
3. **Secrets Management**: Use AWS Secrets Manager for sensitive data
4. **Container Security**: Regular image scanning and updates

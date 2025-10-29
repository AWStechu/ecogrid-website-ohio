# EcoGrid CI/CD Pipeline Setup

## Overview
Complete CI/CD pipeline using AWS CodeDeploy for Blue-Green deployments to ECS Fargate.

## Fixed Issues ✅

### 1. Missing IAM Role
- **Problem**: `ecsTaskRole` didn't exist
- **Solution**: Created IAM role with proper ECS trust policy

### 2. Missing CloudWatch Log Group
- **Problem**: `/ecs/ecogrid-app-bg` log group missing
- **Solution**: Created log group for container logging

### 3. Health Check Configuration
- **Problem**: Target groups using wrong health check path
- **Solution**: Updated both target groups to use `/health` endpoint
- **Settings**: 15s interval, 2 healthy threshold

### 4. Blue-Green Deployment Configuration
- **Problem**: Deployment group not properly configured
- **Solution**: Updated to use `CodeDeployDefault.ECSLinear10PercentEvery1Minutes`

## Current Deployment
- **Deployment ID**: `d-9D2F8O7LF`
- **Status**: InProgress ✅
- **Strategy**: Blue-Green with traffic shifting
- **Target Groups**: 
  - Production: `ecogrid-targets`
  - Test: `ecogrid-targets-alt`

## CI/CD Pipeline Components

### 1. GitHub Actions (`.github/workflows/deploy.yml`)
- Builds Docker image
- Pushes to ECR
- Updates ECS task definition
- Triggers CodeDeploy deployment

### 2. CodeBuild (`buildspec.yml`)
- Alternative to GitHub Actions
- Integrated with AWS CodePipeline
- Automatic deployment on code changes

### 3. Manual Deployment (`deploy.sh`)
- Quick deployment script
- Uses latest task definition
- Run with `./deploy.sh --wait`

## Deployment Process

### For GitHub Actions:
1. Push code to `main` branch
2. GitHub Actions builds and deploys automatically
3. Monitor in AWS Console

### For Manual Deployment:
```bash
./deploy.sh --wait
```

### For CodeBuild/CodePipeline:
1. Set up CodePipeline with GitHub source
2. Use CodeBuild with provided `buildspec.yml`
3. Automatic deployment on code changes

## Monitoring
```bash
# Check deployment status
aws deploy get-deployment --deployment-id d-9D2F8O7LF

# Check ECS service
aws ecs describe-services --cluster ecogrid-cluster --services ecogrid-service-bg

# Check target group health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:442042546183:targetgroup/ecogrid-targets-alt/98097439d64bf8b5
```

## Blue-Green Traffic Flow
1. **Blue Environment**: Current production (`ecogrid-targets`)
2. **Green Environment**: New deployment (`ecogrid-targets-alt`)
3. **Traffic Shift**: Gradual 10% per minute via `ecogrid-alb`
4. **Rollback**: Automatic on health check failures

## Next Steps
1. Monitor current deployment completion
2. Set up GitHub secrets for automated deployments
3. Configure CloudWatch alarms for deployment monitoring
4. Test rollback scenarios

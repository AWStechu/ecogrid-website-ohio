#!/bin/bash

echo "Running pre-deployment checks..."

# Check if database is accessible
echo "Checking database connectivity..."
if ! nc -z ecogrid-aurora-standard.cluster-ckbygg2eq2ic.us-east-1.rds.amazonaws.com 3306; then
    echo "Database connection failed!"
    exit 1
fi

# Check if ECR image exists
echo "Validating container image..."
aws ecr describe-images --repository-name ecogrid-app --image-ids imageTag=latest --region us-east-1 > /dev/null
if [ $? -ne 0 ]; then
    echo "Container image validation failed!"
    exit 1
fi

echo "Pre-deployment checks passed!"
exit 0

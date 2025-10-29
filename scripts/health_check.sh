#!/bin/bash

# Health check script for blue-green deployment
echo "Starting health check validation..."

# Wait for application to be ready
sleep 30

# Get the ALB DNS name from environment or parameter
ALB_DNS=${ALB_DNS_NAME:-"ecogrid-alb-492743554.us-east-1.elb.amazonaws.com"}

# Perform health checks
for i in {1..10}; do
    echo "Health check attempt $i/10..."
    
    # Check if health endpoint responds
    if curl -f -s "http://$ALB_DNS/health" > /dev/null; then
        echo "Health check passed!"
        
        # Additional functional tests
        if curl -f -s "http://$ALB_DNS/" | grep -q "EcoGrid"; then
            echo "Application functional test passed!"
            exit 0
        fi
    fi
    
    echo "Health check failed, retrying in 10 seconds..."
    sleep 10
done

echo "Health check failed after 10 attempts"
exit 1

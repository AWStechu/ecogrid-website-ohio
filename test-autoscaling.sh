#!/bin/bash

echo "🧪 Testing ECS Auto-Scaling for EcoGrid..."
echo "=========================================="

URL="https://d2a18turzymr9c.cloudfront.net"

# Function to check current running tasks
check_tasks() {
    echo "📊 Current ECS Tasks:"
    aws ecs describe-services \
        --cluster ecogrid-cluster \
        --services ecogrid-service-bg \
        --query 'services[0].[runningCount,desiredCount]' \
        --output table \
        --region us-east-1
}

# Function to monitor CPU/Memory metrics
monitor_metrics() {
    echo "📈 CPU/Memory Utilization:"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ECS \
        --metric-name CPUUtilization \
        --dimensions Name=ServiceName,Value=ecogrid-service-bg Name=ClusterName,Value=ecogrid-cluster \
        --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 300 \
        --statistics Average \
        --region us-east-1 \
        --query 'Datapoints[*].[Timestamp,Average]' \
        --output table
}

echo "🔍 Initial State:"
check_tasks

echo ""
echo "🚀 Starting Load Test (5 minutes)..."
echo "This will generate load to trigger auto-scaling"

# Generate load using curl in parallel
for i in {1..20}; do
    (
        for j in {1..50}; do
            curl -s "$URL" > /dev/null &
            curl -s "$URL/projects" > /dev/null &
            curl -s "$URL/login" > /dev/null &
            sleep 0.1
        done
        wait
    ) &
done

echo "⏱️  Load test running... Monitoring for 5 minutes"

# Monitor for 5 minutes
for minute in {1..5}; do
    sleep 60
    echo ""
    echo "📊 Minute $minute:"
    check_tasks
done

echo ""
echo "🔍 Final Metrics:"
monitor_metrics

echo ""
echo "✅ Load test complete!"
echo "💡 Check AWS Console → ECS → ecogrid-service-bg for scaling activity"

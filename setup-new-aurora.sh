#!/bin/bash

echo "Setting up new Aurora MySQL cluster for EcoGrid..."

# Step 1: Create Aurora Cluster
echo "Creating Aurora cluster..."
aws rds create-db-cluster \
  --db-cluster-identifier ecogrid-aurora-cluster \
  --engine aurora-mysql \
  --engine-version 8.0.mysql_aurora.3.02.0 \
  --master-username admin \
  --master-user-password "EcoGrid2025!" \
  --database-name ecogrid \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00" \
  --storage-encrypted \
  --enable-cloudwatch-logs-exports error general slowquery \
  --region us-east-1

echo "Waiting for cluster to be available..."
aws rds wait db-cluster-available --db-cluster-identifier ecogrid-aurora-cluster --region us-east-1

# Step 2: Create Primary Instance (Writer)
echo "Creating primary instance..."
aws rds create-db-instance \
  --db-instance-identifier ecogrid-aurora-primary \
  --db-cluster-identifier ecogrid-aurora-cluster \
  --db-instance-class db.t3.small \
  --engine aurora-mysql \
  --publicly-accessible \
  --auto-minor-version-upgrade \
  --region us-east-1

# Step 3: Create Read Replica for High Availability
echo "Creating read replica..."
aws rds create-db-instance \
  --db-instance-identifier ecogrid-aurora-replica \
  --db-cluster-identifier ecogrid-aurora-cluster \
  --db-instance-class db.t3.small \
  --engine aurora-mysql \
  --auto-minor-version-upgrade \
  --region us-east-1

echo "Waiting for instances to be available..."
aws rds wait db-instance-available --db-instance-identifier ecogrid-aurora-primary --region us-east-1
aws rds wait db-instance-available --db-instance-identifier ecogrid-aurora-replica --region us-east-1

# Step 4: Get new cluster endpoint
NEW_ENDPOINT=$(aws rds describe-db-clusters --db-cluster-identifier ecogrid-aurora-cluster --query 'DBClusters[0].Endpoint' --output text --region us-east-1)
echo "New Aurora cluster endpoint: $NEW_ENDPOINT"

# Step 5: Enable Auto Scaling
echo "Setting up auto scaling..."
aws application-autoscaling register-scalable-target \
  --service-namespace rds \
  --resource-id cluster:ecogrid-aurora-cluster \
  --scalable-dimension rds:cluster:ReadReplicaCount \
  --min-capacity 1 \
  --max-capacity 3 \
  --region us-east-1

aws application-autoscaling put-scaling-policy \
  --service-namespace rds \
  --resource-id cluster:ecogrid-aurora-cluster \
  --scalable-dimension rds:cluster:ReadReplicaCount \
  --policy-name ecogrid-aurora-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "RDSReaderAverageCPUUtilization"
    },
    "ScaleOutCooldown": 300,
    "ScaleInCooldown": 300
  }' \
  --region us-east-1

echo "Aurora cluster setup complete!"
echo "Cluster Endpoint: $NEW_ENDPOINT"
echo "Username: admin"
echo "Password: EcoGrid2025!"
echo ""
echo "Next steps:"
echo "1. Run the data migration script: python migrate-aurora-data.py"
echo "2. Update the application configuration with the new endpoint"

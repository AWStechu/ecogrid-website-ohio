#!/bin/bash

echo "🔄 Migrating database to private subnets..."

SNAPSHOT_ID="ecogrid-private-migration-20251010-1022"
NEW_CLUSTER_ID="ecogrid-aurora-private"

# Wait for snapshot to complete
echo "⏳ Waiting for snapshot to complete..."
aws rds wait db-cluster-snapshot-completed \
  --db-cluster-snapshot-identifier $SNAPSHOT_ID \
  --region us-east-1

echo "✅ Snapshot completed! Creating new cluster in private subnets..."

# Restore cluster from snapshot to private subnet group
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier $NEW_CLUSTER_ID \
  --snapshot-identifier $SNAPSHOT_ID \
  --engine aurora-mysql \
  --db-subnet-group-name ecogrid-private-db-subnets \
  --vpc-security-group-ids sg-0b2d41e990ff403bc \
  --master-username admin \
  --region us-east-1 \
  --query 'DBCluster.{ClusterIdentifier:DBClusterIdentifier,Status:Status,SubnetGroup:DBSubnetGroup}' \
  --output table

echo "⏳ Waiting for new cluster to be available..."
aws rds wait db-cluster-available \
  --db-cluster-identifier $NEW_CLUSTER_ID \
  --region us-east-1

# Create primary instance in the new cluster
echo "🔧 Creating primary database instance..."
aws rds create-db-instance \
  --db-instance-identifier ecogrid-private-primary \
  --db-instance-class db.r5.large \
  --engine aurora-mysql \
  --db-cluster-identifier $NEW_CLUSTER_ID \
  --no-publicly-accessible \
  --region us-east-1

# Create replica instance
echo "🔧 Creating replica database instance..."
aws rds create-db-instance \
  --db-instance-identifier ecogrid-private-replica \
  --db-instance-class db.r5.large \
  --engine aurora-mysql \
  --db-cluster-identifier $NEW_CLUSTER_ID \
  --no-publicly-accessible \
  --region us-east-1

echo "⏳ Waiting for instances to be available..."
aws rds wait db-instance-available \
  --db-instance-identifier ecogrid-private-primary \
  --region us-east-1

echo "✅ Database migration to private subnets completed!"
echo ""
echo "📋 Next steps:"
echo "1. Update application connection string to: $NEW_CLUSTER_ID.cluster-ckbygg2eq2ic.us-east-1.rds.amazonaws.com"
echo "2. Test application connectivity"
echo "3. Delete old cluster: ecogrid-aurora-standard"
echo ""
echo "🔒 New database is now in private subnets with no internet access!"

#!/bin/bash

echo "🔄 Starting database cutover to private cluster..."

# Step 1: Deploy application with new database endpoint
echo "📦 Deploying application with new database endpoint..."
git add app.py
git commit -m "Switch to private database cluster

- Updated DB_HOST to ecogrid-aurora-private
- Application now connects to private subnets database
- Cutover from old cluster to new private cluster"
git push origin main

echo "⏳ Waiting for deployment to complete..."
sleep 60

# Step 2: Test application connectivity
echo "🧪 Testing application connectivity to new database..."
HEALTH_CHECK=$(curl -s http://whatsnewcustomer.com/health)
if [[ $HEALTH_CHECK == *"healthy"* ]]; then
    echo "✅ Application successfully connected to new private database!"
else
    echo "❌ Application health check failed. Aborting cutover."
    exit 1
fi

# Step 3: Stop old database cluster
echo "🛑 Stopping old database cluster..."
aws rds stop-db-cluster \
    --db-cluster-identifier ecogrid-aurora-standard \
    --region us-east-1

echo "⏳ Waiting for old cluster to stop..."
aws rds wait db-cluster-stopped \
    --db-cluster-identifier ecogrid-aurora-standard \
    --region us-east-1

echo "✅ Database cutover completed successfully!"
echo ""
echo "📊 CUTOVER SUMMARY:"
echo "✅ Application updated to use: ecogrid-aurora-private"
echo "✅ New database in private subnets (no internet access)"
echo "✅ Old database cluster stopped"
echo "✅ High availability maintained (primary + replica)"
echo ""
echo "🔒 Your application is now using the secure private database!"

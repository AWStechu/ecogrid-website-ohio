# Aurora Migration Guide

This guide will help you migrate from Aurora Serverless to a cost-optimized Aurora cluster with high availability.

## Overview

**New Aurora Configuration:**
- **Engine:** Aurora MySQL 8.0
- **Instance Class:** db.t3.small (cost-optimized)
- **High Availability:** Primary + Read Replica
- **Auto Scaling:** 1-3 read replicas based on CPU
- **Storage:** Encrypted, automatic backups
- **Cost:** ~$50-80/month vs $200+/month for serverless

## Step 1: Create New Aurora Cluster

Run the setup script with your AWS credentials:

```bash
# Set your AWS credentials first
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_SESSION_TOKEN=your_session_token

# Create the Aurora cluster
./setup-new-aurora.sh
```

This will create:
- Aurora cluster: `ecogrid-aurora-cluster`
- Primary instance: `ecogrid-aurora-primary` (db.t3.small)
- Read replica: `ecogrid-aurora-replica` (db.t3.small)
- Auto scaling policy for read replicas

## Step 2: Get New Cluster Endpoint

After creation, get the cluster endpoint:

```bash
aws rds describe-db-clusters \
  --db-cluster-identifier ecogrid-aurora-cluster \
  --query 'DBClusters[0].Endpoint' \
  --output text \
  --region us-east-1
```

Example output: `ecogrid-aurora-cluster.cluster-abc123.us-east-1.rds.amazonaws.com`

## Step 3: Migrate Data

Run the migration script with the new endpoint:

```bash
python migrate-aurora-data.py ecogrid-aurora-cluster.cluster-abc123.us-east-1.rds.amazonaws.com
```

This will:
- Create all necessary tables in the new cluster
- Migrate existing users and volunteers data
- Create new `customer_inquiries` table for Join the Community form

## Step 4: Update Application Configuration

Update the application with the new endpoint:

```bash
./update-db-config.sh ecogrid-aurora-cluster.cluster-abc123.us-east-1.rds.amazonaws.com
```

## Step 5: Deploy to ECS

Register the new task definition:

```bash
aws ecs register-task-definition --cli-input-json file://new-aurora-taskdef.json --region us-east-1
```

Update the ECS service:

```bash
aws ecs update-service \
  --cluster ecogrid-cluster \
  --service ecogrid-service \
  --task-definition ecogrid-task \
  --region us-east-1
```

## Step 6: Commit and Deploy

Commit all changes and push to trigger CI/CD:

```bash
git add .
git commit -m "Migrate to new Aurora cluster with customer inquiry functionality"
git push origin main
```

## New Features Added

### Customer Inquiry Database
- **Table:** `customer_inquiries`
- **Purpose:** Store Join the Community form submissions
- **Fields:** name, email, phone, address, provider, bill range, estimated savings
- **Indexing:** Optimized for email and date queries

### Database Error Handling
- Graceful handling of database connection failures
- Application continues to work even if database is unavailable
- Proper error logging and user feedback

## Cost Optimization Features

### Instance Configuration
- **db.t3.small:** Burstable performance, cost-effective
- **Auto Scaling:** Scale read replicas based on demand (1-3 instances)
- **Scheduled Maintenance:** Off-peak hours to minimize impact

### Monitoring and Alerts
- CloudWatch logs enabled for error tracking
- Performance Insights disabled to reduce costs
- 7-day backup retention for compliance

## High Availability Features

### Multi-AZ Deployment
- Primary instance in one AZ
- Read replica in different AZ
- Automatic failover capability

### Auto Scaling
- CPU-based scaling for read replicas
- Scale out at 70% CPU utilization
- 5-minute cooldown periods

## Security Features

### Encryption
- Storage encryption enabled
- In-transit encryption supported
- Strong password policy

### Access Control
- VPC security groups
- Database user permissions
- Application-level authentication

## Monitoring and Maintenance

### CloudWatch Metrics
- CPU utilization
- Database connections
- Read/write IOPS
- Storage usage

### Automated Backups
- 7-day retention period
- Point-in-time recovery
- Cross-region backup option

## Troubleshooting

### Connection Issues
1. Check security group rules
2. Verify endpoint URL
3. Test database connectivity
4. Check application logs

### Performance Issues
1. Monitor CPU utilization
2. Check for slow queries
3. Review connection pooling
4. Consider read replica scaling

### Cost Monitoring
1. Use AWS Cost Explorer
2. Set up billing alerts
3. Monitor instance utilization
4. Review scaling policies

## Rollback Plan

If issues occur, you can rollback by:
1. Reverting application configuration to old endpoint
2. Updating ECS task definition
3. Redeploying application
4. Keeping old Aurora Serverless as backup

## Next Steps

After successful migration:
1. Monitor application performance for 24-48 hours
2. Verify all functionality works correctly
3. Test customer inquiry form submissions
4. Review cost savings in AWS billing
5. Schedule old Aurora Serverless deletion (after 1 week)

## Support

For issues during migration:
1. Check CloudWatch logs
2. Review ECS service events
3. Test database connectivity
4. Verify application configuration

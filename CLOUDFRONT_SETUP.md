# CloudFront Setup for EcoGrid

## Overview
CloudFront provides global CDN caching, DDoS protection, and improved performance for your EcoGrid website.

## Setup Steps

### 1. Create CloudFront Distribution
```bash
# With valid AWS credentials, run:
aws cloudfront create-distribution \
  --distribution-config file://cloudfront-config.json \
  --region us-east-1
```

### 2. Update DNS (after distribution is deployed)
```bash
# Get CloudFront domain name from AWS Console
# Update whatsnewcustomer.com CNAME to point to:
# example: d1234567890abc.cloudfront.net
```

### 3. Add Distribution ID to GitHub Secrets
```bash
# In GitHub repository settings, add secret:
# CLOUDFRONT_DISTRIBUTION_ID = E1234567890ABC
```

## Caching Strategy

### Static Assets (`/static/*`)
- **Cache Duration**: 24 hours (86400 seconds)
- **Max Cache**: 1 year
- **Compression**: Enabled
- **Methods**: GET, HEAD only

### Health Endpoint (`/health`)
- **Cache Duration**: 0 seconds (no caching)
- **Purpose**: Always fresh for monitoring

### API Endpoints (`/api/*`)
- **Cache Duration**: 0 seconds (no caching)
- **Headers**: Forward all including Authorization
- **Methods**: All HTTP methods allowed

### Default Behavior
- **Cache Duration**: 5 minutes (300 seconds)
- **Max Cache**: 24 hours
- **Compression**: Enabled
- **HTTPS**: Redirect HTTP to HTTPS

## Invalidation

### Manual Invalidation
```bash
# Invalidate all content
./invalidate-cloudfront.sh E1234567890ABC

# Invalidate specific paths
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/index.html" "/static/css/*"
```

### Automatic Invalidation
- Integrated into GitHub Actions workflow
- Runs after successful deployment
- Invalidates: `/*`, `/index.html`, `/static/*`

## Benefits

### Performance
- **Global Edge Locations**: 400+ locations worldwide
- **Reduced Latency**: Content served from nearest edge
- **Compression**: Automatic gzip compression
- **HTTP/2**: Modern protocol support

### Security
- **DDoS Protection**: AWS Shield Standard included
- **SSL/TLS**: Free SSL certificates
- **Origin Protection**: Hide ALB from direct access

### Cost Optimization
- **Reduced ALB Traffic**: Static content served from edge
- **Data Transfer**: Lower costs for global users
- **Bandwidth**: Efficient content delivery

## Monitoring

### CloudWatch Metrics
- Cache hit ratio
- Origin latency
- Error rates
- Data transfer

### Real User Monitoring
```bash
# Check cache headers
curl -I https://d1234567890abc.cloudfront.net/
# Look for: X-Cache: Hit from cloudfront
```

## Troubleshooting

### Cache Issues
```bash
# Force refresh (bypass cache)
curl -H "Cache-Control: no-cache" https://your-domain.com/

# Check cache status
curl -I https://your-domain.com/ | grep X-Cache
```

### Distribution Status
```bash
# Check deployment status
aws cloudfront get-distribution --id E1234567890ABC \
  --query 'Distribution.Status'
```

## Configuration Files

- `cloudfront-config.json`: Distribution configuration
- `invalidate-cloudfront.sh`: Manual invalidation script
- `.github/workflows/blue-green-deploy.yml`: Auto-invalidation integration

## Next Steps

1. Create the CloudFront distribution
2. Wait for deployment (15-20 minutes)
3. Update DNS to point to CloudFront
4. Add distribution ID to GitHub secrets
5. Test caching and invalidation

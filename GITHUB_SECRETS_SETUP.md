# GitHub Secrets Setup for CloudFront

## Required Secret

Add this secret to your GitHub repository:

### CLOUDFRONT_DISTRIBUTION_ID
**Value:** `E2ZSE2AJK14WZ2`

## How to Add the Secret

1. Go to your GitHub repository: https://github.com/1104262/ecogrid-website
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Name: `CLOUDFRONT_DISTRIBUTION_ID`
6. Value: `E2ZSE2AJK14WZ2`
7. Click **Add secret**

## CloudFront Distribution Details

- **Distribution ID:** E2ZSE2AJK14WZ2
- **CloudFront Domain:** d2a18turzymr9c.cloudfront.net
- **Status:** InProgress (deploying)
- **Deployment Time:** 15-20 minutes

## DNS Update (After Deployment)

Update your DNS settings to point to CloudFront:

### Option 1: CNAME Record
```
Type: CNAME
Name: whatsnewcustomer.com
Value: d2a18turzymr9c.cloudfront.net
```

### Option 2: Keep Current Setup
You can also keep the current DNS and access CloudFront directly:
- **Current:** http://whatsnewcustomer.com (direct to ALB)
- **CloudFront:** https://d2a18turzymr9c.cloudfront.net (via CDN)

## Testing After Deployment

```bash
# Test CloudFront distribution
curl -I https://d2a18turzymr9c.cloudfront.net/

# Look for cache headers
curl -I https://d2a18turzymr9c.cloudfront.net/ | grep X-Cache

# Test invalidation
./invalidate-cloudfront.sh E2ZSE2AJK14WZ2
```

## Automatic Invalidation

Once the GitHub secret is added, every deployment will automatically:
1. Deploy new code to ECS
2. Invalidate CloudFront cache
3. Ensure users get the latest version

## Benefits Active After Deployment

- ✅ Global CDN caching
- ✅ HTTPS redirect
- ✅ Compression enabled
- ✅ DDoS protection
- ✅ Faster load times worldwide
- ✅ Automatic cache invalidation

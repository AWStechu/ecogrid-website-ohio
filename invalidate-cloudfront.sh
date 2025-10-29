#!/bin/bash

# CloudFront Invalidation Script for EcoGrid
DISTRIBUTION_ID=${1:-"YOUR_DISTRIBUTION_ID"}

if [ "$DISTRIBUTION_ID" = "YOUR_DISTRIBUTION_ID" ]; then
    echo "Usage: ./invalidate-cloudfront.sh <distribution-id>"
    echo "Example: ./invalidate-cloudfront.sh E1234567890ABC"
    exit 1
fi

echo "Creating CloudFront invalidation for distribution: $DISTRIBUTION_ID"

# Create invalidation for common paths
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*" "/index.html" "/static/*" \
  --region us-east-1 \
  --query 'Invalidation.{Id:Id,Status:Status,CreateTime:CreateTime}'

echo "Invalidation created! Cache will be cleared within 5-15 minutes."

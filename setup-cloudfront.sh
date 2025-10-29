#!/bin/bash

echo "Setting up CloudFront distribution for EcoGrid..."

# Create CloudFront distribution
aws cloudfront create-distribution \
  --distribution-config '{
    "CallerReference": "ecogrid-'$(date +%s)'",
    "Comment": "EcoGrid Dynamics CloudFront Distribution",
    "DefaultRootObject": "index.html",
    "Origins": {
      "Quantity": 1,
      "Items": [
        {
          "Id": "ecogrid-alb-origin",
          "DomainName": "ecogrid-alb-492743554.us-east-1.elb.amazonaws.com",
          "CustomOriginConfig": {
            "HTTPPort": 80,
            "HTTPSPort": 443,
            "OriginProtocolPolicy": "http-only",
            "OriginSslProtocols": {
              "Quantity": 1,
              "Items": ["TLSv1.2"]
            }
          }
        }
      ]
    },
    "DefaultCacheBehavior": {
      "TargetOriginId": "ecogrid-alb-origin",
      "ViewerProtocolPolicy": "redirect-to-https",
      "TrustedSigners": {
        "Enabled": false,
        "Quantity": 0
      },
      "ForwardedValues": {
        "QueryString": true,
        "Cookies": {
          "Forward": "none"
        },
        "Headers": {
          "Quantity": 3,
          "Items": ["Host", "CloudFront-Forwarded-Proto", "User-Agent"]
        }
      },
      "MinTTL": 0,
      "DefaultTTL": 300,
      "MaxTTL": 86400,
      "Compress": true
    },
    "CacheBehaviors": {
      "Quantity": 2,
      "Items": [
        {
          "PathPattern": "/static/*",
          "TargetOriginId": "ecogrid-alb-origin",
          "ViewerProtocolPolicy": "redirect-to-https",
          "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
          },
          "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
              "Forward": "none"
            }
          },
          "MinTTL": 0,
          "DefaultTTL": 86400,
          "MaxTTL": 31536000,
          "Compress": true
        },
        {
          "PathPattern": "/health",
          "TargetOriginId": "ecogrid-alb-origin",
          "ViewerProtocolPolicy": "redirect-to-https",
          "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
          },
          "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
              "Forward": "none"
            }
          },
          "MinTTL": 0,
          "DefaultTTL": 0,
          "MaxTTL": 0,
          "Compress": false
        }
      ]
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100"
  }' \
  --region us-east-1 \
  --query 'Distribution.{Id:Id,DomainName:DomainName,Status:Status}' > cloudfront-output.json

echo "CloudFront distribution created!"
cat cloudfront-output.json

#!/bin/bash

echo "🔐 Setting up AWS Cognito for EcoGrid authentication..."

# Create Cognito User Pool
USER_POOL_ID=$(aws cognito-idp create-user-pool \
  --pool-name "ecogrid-users" \
  --policies '{
    "PasswordPolicy": {
      "MinimumLength": 8,
      "RequireUppercase": false,
      "RequireLowercase": false,
      "RequireNumbers": false,
      "RequireSymbols": false
    }
  }' \
  --auto-verified-attributes email \
  --username-attributes email \
  --region us-east-1 \
  --query 'UserPool.Id' \
  --output text)

echo "✅ User Pool created: $USER_POOL_ID"

# Create User Pool Client
CLIENT_ID=$(aws cognito-idp create-user-pool-client \
  --user-pool-id $USER_POOL_ID \
  --client-name "ecogrid-web-client" \
  --generate-secret \
  --explicit-auth-flows ADMIN_NO_SRP_AUTH ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --region us-east-1 \
  --query 'UserPoolClient.ClientId' \
  --output text)

echo "✅ User Pool Client created: $CLIENT_ID"

# Get Client Secret
CLIENT_SECRET=$(aws cognito-idp describe-user-pool-client \
  --user-pool-id $USER_POOL_ID \
  --client-id $CLIENT_ID \
  --region us-east-1 \
  --query 'UserPoolClient.ClientSecret' \
  --output text)

# Create sample users
echo "👥 Creating sample users..."

USERS=(
  "admin:admin@ecogrid.com:password123"
  "john_doe:john@ecogrid.com:energy2025"
  "sarah_green:sarah@ecogrid.com:solar123"
  "mike_wind:mike@ecogrid.com:turbine456"
  "lisa_hydro:lisa@ecogrid.com:water789"
)

for user_data in "${USERS[@]}"; do
  IFS=':' read -r username email password <<< "$user_data"
  
  aws cognito-idp admin-create-user \
    --user-pool-id $USER_POOL_ID \
    --username $username \
    --user-attributes Name=email,Value=$email Name=email_verified,Value=true \
    --temporary-password $password \
    --message-action SUPPRESS \
    --region us-east-1
  
  # Set permanent password
  aws cognito-idp admin-set-user-password \
    --user-pool-id $USER_POOL_ID \
    --username $username \
    --password $password \
    --permanent \
    --region us-east-1
  
  echo "✅ Created user: $username"
done

# Save configuration
cat > cognito-config.json << EOF
{
  "USER_POOL_ID": "$USER_POOL_ID",
  "CLIENT_ID": "$CLIENT_ID",
  "CLIENT_SECRET": "$CLIENT_SECRET",
  "REGION": "us-east-1"
}
EOF

echo ""
echo "🎉 Cognito setup completed!"
echo "User Pool ID: $USER_POOL_ID"
echo "Client ID: $CLIENT_ID"
echo "Configuration saved to: cognito-config.json"
echo ""
echo "Sample users created:"
echo "- admin / password123"
echo "- john_doe / energy2025"
echo "- sarah_green / solar123"
echo "- mike_wind / turbine456"
echo "- lisa_hydro / water789"

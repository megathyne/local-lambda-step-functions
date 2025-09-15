#!/bin/bash

# Configuration
LOCALSTACK_ENDPOINT="http://localhost:4566"
AWS_REGION="us-east-1"
AWS_PROFILE="localstack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting LocalStack Step Functions POC Deployment${NC}"

# Function to check if LocalStack is running
check_localstack() {
    echo -e "${YELLOW}Checking if LocalStack is running...${NC}"
    if curl -s "$LOCALSTACK_ENDPOINT/health" > /dev/null; then
        echo -e "${GREEN}✅ LocalStack is running${NC}"
    else
        echo -e "${RED}❌ LocalStack is not running. Please start it with: docker-compose up -d${NC}"
        exit 1
    fi
}

# Function to create Lambda deployment packages
create_lambda_packages() {
    echo -e "${YELLOW}📦 Creating Lambda deployment packages...${NC}"
    
    # Create packages for each Lambda function
    for func_dir in lambda-functions/*/; do
        func_name=$(basename "$func_dir")
        echo -e "${YELLOW}Creating package for $func_name...${NC}"
        
        cd "$func_dir"
        zip -r "../${func_name}.zip" . -x "*.pyc" "__pycache__/*"
        cd - > /dev/null
    done
    
    echo -e "${GREEN}✅ Lambda packages created${NC}"
}

# Function to create IAM role for Lambda functions
create_iam_role() {
    echo -e "${YELLOW}🔐 Creating IAM role for Lambda functions...${NC}"
    
    # Create trust policy
    cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create execution policy
    cat > execution-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF

    # Create role
    aws --endpoint-url="$LOCALSTACK_ENDPOINT" iam create-role \
        --role-name lambda-execution-role \
        --assume-role-policy-document file://trust-policy.json \
        --region "$AWS_REGION" || echo "Role may already exist"

    # Attach policy
    aws --endpoint-url="$LOCALSTACK_ENDPOINT" iam put-role-policy \
        --role-name lambda-execution-role \
        --policy-name lambda-execution-policy \
        --policy-document file://execution-policy.json \
        --region "$AWS_REGION" || echo "Policy may already exist"

    # Clean up
    rm -f trust-policy.json execution-policy.json
    
    echo -e "${GREEN}✅ IAM role created${NC}"
}

# Function to deploy Lambda functions
deploy_lambda_functions() {
    echo -e "${YELLOW}⚡ Deploying Lambda functions...${NC}"
    
    local role_arn="arn:aws:iam::000000000000:role/lambda-execution-role"
    
    # Deploy each Lambda function
    for zip_file in lambda-functions/*.zip; do
        func_name=$(basename "$zip_file" .zip)
        echo -e "${YELLOW}Deploying $func_name...${NC}"
        
        aws --endpoint-url="$LOCALSTACK_ENDPOINT" lambda create-function \
            --function-name "$func_name-function" \
            --runtime nodejs18.x \
            --role "$role_arn" \
            --handler index.handler \
            --zip-file fileb://"$zip_file" \
            --region "$AWS_REGION" || echo "Function may already exist, updating..."
        
        # Update function code if it already exists
        aws --endpoint-url="$LOCALSTACK_ENDPOINT" lambda update-function-code \
            --function-name "$func_name-function" \
            --zip-file fileb://"$zip_file" \
            --region "$AWS_REGION" 2>/dev/null || true
    done
    
    echo -e "${GREEN}✅ Lambda functions deployed${NC}"
}

# Function to create Step Functions state machine
create_step_function() {
    echo -e "${YELLOW}🔄 Creating Step Functions state machine...${NC}"
    
    # Create IAM role for Step Functions
    cat > stepfunctions-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    cat > stepfunctions-execution-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "arn:aws:lambda:us-east-1:000000000000:function:*"
    }
  ]
}
EOF

    # Create Step Functions role
    aws --endpoint-url="$LOCALSTACK_ENDPOINT" iam create-role \
        --role-name stepfunctions-execution-role \
        --assume-role-policy-document file://stepfunctions-trust-policy.json \
        --region "$AWS_REGION" || echo "Step Functions role may already exist"

    aws --endpoint-url="$LOCALSTACK_ENDPOINT" iam put-role-policy \
        --role-name stepfunctions-execution-role \
        --policy-name stepfunctions-execution-policy \
        --policy-document file://stepfunctions-execution-policy.json \
        --region "$AWS_REGION" || echo "Step Functions policy may already exist"

    # Wait a moment for role to be available
    sleep 2

    # Create state machine
    local stepfunctions_role_arn="arn:aws:iam::000000000000:role/stepfunctions-execution-role"
    
    aws --endpoint-url="$LOCALSTACK_ENDPOINT" stepfunctions create-state-machine \
        --name "hello-world-workflow" \
        --definition file://step-function-definition.json \
        --role-arn "$stepfunctions_role_arn" \
        --region "$AWS_REGION" || echo "State machine may already exist"

    # Clean up
    rm -f stepfunctions-trust-policy.json stepfunctions-execution-policy.json
    
    echo -e "${GREEN}✅ Step Functions state machine created${NC}"
}

# Main deployment flow
main() {
    check_localstack
    create_lambda_packages
    create_iam_role
    deploy_lambda_functions
    create_step_function
    
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "${YELLOW}You can now test the Step Functions workflow using the test script.${NC}"
}

# Run main function
main

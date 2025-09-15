#!/bin/bash

# Configuration
LOCALSTACK_ENDPOINT="http://localhost:4566"
AWS_REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Step Functions Workflow${NC}"

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

# Function to test individual Lambda functions
test_lambda_functions() {
    echo -e "${YELLOW}🔍 Testing individual Lambda functions...${NC}"
    
    # Test hello-world function
    echo -e "${BLUE}Testing hello-world function...${NC}"
    local hello_payload='{"name": "LocalStack", "message": "Hello"}'
    local hello_response=$(aws --endpoint-url="$LOCALSTACK_ENDPOINT" lambda invoke \
        --function-name hello-world-function \
        --payload "$hello_payload" \
        --region "$AWS_REGION" \
        /tmp/hello-response.json)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ hello-world function test passed${NC}"
        cat /tmp/hello-response.json | jq '.'
    else
        echo -e "${RED}❌ hello-world function test failed${NC}"
    fi
    
    # Test process-data function
    echo -e "${BLUE}Testing process-data function...${NC}"
    local process_payload='{"body": {"greeting": "Hello, LocalStack!", "timestamp": "test-123"}}'
    local process_response=$(aws --endpoint-url="$LOCALSTACK_ENDPOINT" lambda invoke \
        --function-name process-data-function \
        --payload "$process_payload" \
        --region "$AWS_REGION" \
        /tmp/process-response.json)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ process-data function test passed${NC}"
        cat /tmp/process-response.json | jq '.'
    else
        echo -e "${RED}❌ process-data function test failed${NC}"
    fi
    
    # Test notify-completion function
    echo -e "${BLUE}Testing notify-completion function...${NC}"
    local notify_payload='{"body": {"original_greeting": "Hello, LocalStack!", "processing_time": 1.5, "word_count": 2, "character_count": 17}}'
    local notify_response=$(aws --endpoint-url="$LOCALSTACK_ENDPOINT" lambda invoke \
        --function-name notify-completion-function \
        --payload "$notify_payload" \
        --region "$AWS_REGION" \
        /tmp/notify-response.json)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ notify-completion function test passed${NC}"
        cat /tmp/notify-response.json | jq '.'
    else
        echo -e "${RED}❌ notify-completion function test failed${NC}"
    fi
}

# Function to test Step Functions workflow
test_step_functions() {
    echo -e "${YELLOW}🔄 Testing Step Functions workflow...${NC}"
    
    # Get state machine ARN
    local state_machine_arn=$(aws --endpoint-url="$LOCALSTACK_ENDPOINT" stepfunctions list-state-machines \
        --region "$AWS_REGION" \
        --query 'stateMachines[0].stateMachineArn' \
        --output text)
    
    if [ "$state_machine_arn" = "None" ] || [ -z "$state_machine_arn" ]; then
        echo -e "${RED}❌ No state machine found. Please run the deployment script first.${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Found state machine: $state_machine_arn${NC}"
    
    # Start execution
    local input_payload='{"name": "Step Functions", "message": "Hello from"}'
    local execution_arn=$(aws --endpoint-url="$LOCALSTACK_ENDPOINT" stepfunctions start-execution \
        --state-machine-arn "$state_machine_arn" \
        --name "test-execution-$(date +%s)" \
        --input "$input_payload" \
        --region "$AWS_REGION" \
        --query 'executionArn' \
        --output text)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Step Functions execution started${NC}"
        echo -e "${BLUE}Execution ARN: $execution_arn${NC}"
        
        # Wait for execution to complete
        echo -e "${YELLOW}Waiting for execution to complete...${NC}"
        local status="RUNNING"
        local attempts=0
        local max_attempts=30
        
        while [ "$status" = "RUNNING" ] && [ $attempts -lt $max_attempts ]; do
            sleep 2
            status=$(aws --endpoint-url="$LOCALSTACK_ENDPOINT" stepfunctions describe-execution \
                --execution-arn "$execution_arn" \
                --region "$AWS_REGION" \
                --query 'status' \
                --output text)
            attempts=$((attempts + 1))
            echo -e "${BLUE}Status: $status (attempt $attempts/$max_attempts)${NC}"
        done
        
        # Get execution result
        if [ "$status" = "SUCCEEDED" ]; then
            echo -e "${GREEN}🎉 Step Functions execution completed successfully!${NC}"
            aws --endpoint-url="$LOCALSTACK_ENDPOINT" stepfunctions describe-execution \
                --execution-arn "$execution_arn" \
                --region "$AWS_REGION" \
                --query 'output' \
                --output text | jq '.'
        else
            echo -e "${RED}❌ Step Functions execution failed with status: $status${NC}"
            aws --endpoint-url="$LOCALSTACK_ENDPOINT" stepfunctions describe-execution \
                --execution-arn "$execution_arn" \
                --region "$AWS_REGION" \
                --query 'error' \
                --output text
        fi
    else
        echo -e "${RED}❌ Failed to start Step Functions execution${NC}"
    fi
}

# Function to list all resources
list_resources() {
    echo -e "${YELLOW}📋 Listing deployed resources...${NC}"
    
    echo -e "${BLUE}Lambda Functions:${NC}"
    aws --endpoint-url="$LOCALSTACK_ENDPOINT" lambda list-functions \
        --region "$AWS_REGION" \
        --query 'Functions[].FunctionName' \
        --output table
    
    echo -e "${BLUE}Step Functions State Machines:${NC}"
    aws --endpoint-url="$LOCALSTACK_ENDPOINT" stepfunctions list-state-machines \
        --region "$AWS_REGION" \
        --query 'stateMachines[].{Name:name,Arn:stateMachineArn}' \
        --output table
    
    echo -e "${BLUE}IAM Roles:${NC}"
    aws --endpoint-url="$LOCALSTACK_ENDPOINT" iam list-roles \
        --region "$AWS_REGION" \
        --query 'Roles[].RoleName' \
        --output table
}

# Function to clean up test files
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up test files...${NC}"
    rm -f /tmp/*-response.json
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Main test flow
main() {
    case "${1:-all}" in
        "lambda")
            check_localstack
            test_lambda_functions
            ;;
        "stepfunctions")
            check_localstack
            test_step_functions
            ;;
        "list")
            check_localstack
            list_resources
            ;;
        "all")
            check_localstack
            test_lambda_functions
            echo ""
            test_step_functions
            echo ""
            list_resources
            ;;
        *)
            echo -e "${RED}Usage: $0 [lambda|stepfunctions|list|all]${NC}"
            echo -e "${YELLOW}  lambda        - Test only Lambda functions${NC}"
            echo -e "${YELLOW}  stepfunctions - Test only Step Functions workflow${NC}"
            echo -e "${YELLOW}  list          - List all deployed resources${NC}"
            echo -e "${YELLOW}  all           - Run all tests (default)${NC}"
            exit 1
            ;;
    esac
    
    cleanup
}

# Run main function
main "$@"

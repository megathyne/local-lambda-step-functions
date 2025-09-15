#!/bin/bash

# Configuration
LOCALSTACK_ENDPOINT="http://localhost:4566"
AWS_REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Cleaning up LocalStack resources...${NC}"

# Function to check if LocalStack is running
check_localstack() {
    if curl -s "$LOCALSTACK_ENDPOINT/health" > /dev/null; then
        echo -e "${GREEN}✅ LocalStack is running${NC}"
        return 0
    else
        echo -e "${RED}❌ LocalStack is not running${NC}"
        return 1
    fi
}

# Function to delete Step Functions executions and state machine
cleanup_stepfunctions() {
    echo -e "${YELLOW}Deleting Step Functions resources...${NC}"
    
    # List and delete executions
    local executions=$(aws --endpoint-url="$LOCALSTACK_ENDPOINT" stepfunctions list-executions \
        --state-machine-arn "arn:aws:states:us-east-1:000000000000:stateMachine:hello-world-workflow" \
        --region "$AWS_REGION" \
        --query 'executions[].executionArn' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$executions" ]; then
        for execution_arn in $executions; do
            echo -e "${YELLOW}Stopping execution: $execution_arn${NC}"
            aws --endpoint-url="$LOCALSTACK_ENDPOINT" stepfunctions stop-execution \
                --execution-arn "$execution_arn" \
                --region "$AWS_REGION" 2>/dev/null || true
        done
    fi
    
    # Delete state machine
    aws --endpoint-url="$LOCALSTACK_ENDPOINT" stepfunctions delete-state-machine \
        --state-machine-arn "arn:aws:states:us-east-1:000000000000:stateMachine:hello-world-workflow" \
        --region "$AWS_REGION" 2>/dev/null || echo "State machine may not exist"
    
    echo -e "${GREEN}✅ Step Functions resources cleaned up${NC}"
}

# Function to delete Lambda functions
cleanup_lambda() {
    echo -e "${YELLOW}Deleting Lambda functions...${NC}"
    
    local functions=("hello-world-function" "process-data-function" "notify-completion-function")
    
    for func in "${functions[@]}"; do
        echo -e "${YELLOW}Deleting function: $func${NC}"
        aws --endpoint-url="$LOCALSTACK_ENDPOINT" lambda delete-function \
            --function-name "$func" \
            --region "$AWS_REGION" 2>/dev/null || echo "Function $func may not exist"
    done
    
    echo -e "${GREEN}✅ Lambda functions cleaned up${NC}"
}

# Function to delete IAM roles
cleanup_iam() {
    echo -e "${YELLOW}Deleting IAM roles...${NC}"
    
    local roles=("lambda-execution-role" "stepfunctions-execution-role")
    
    for role in "${roles[@]}"; do
        echo -e "${YELLOW}Deleting role: $role${NC}"
        
        # Delete inline policies first
        aws --endpoint-url="$LOCALSTACK_ENDPOINT" iam delete-role-policy \
            --role-name "$role" \
            --policy-name "${role}-policy" 2>/dev/null || true
        
        aws --endpoint-url="$LOCALSTACK_ENDPOINT" iam delete-role-policy \
            --role-name "$role" \
            --policy-name "lambda-execution-policy" 2>/dev/null || true
        
        aws --endpoint-url="$LOCALSTACK_ENDPOINT" iam delete-role-policy \
            --role-name "$role" \
            --policy-name "stepfunctions-execution-policy" 2>/dev/null || true
        
        # Delete role
        aws --endpoint-url="$LOCALSTACK_ENDPOINT" iam delete-role \
            --role-name "$role" \
            --region "$AWS_REGION" 2>/dev/null || echo "Role $role may not exist"
    done
    
    echo -e "${GREEN}✅ IAM roles cleaned up${NC}"
}

# Function to clean up local files
cleanup_files() {
    echo -e "${YELLOW}Cleaning up local files...${NC}"
    
    # Remove Lambda packages
    rm -f lambda-functions/*.zip
    
    # Remove temporary files
    rm -f /tmp/*-response.json
    rm -f *.json
    
    echo -e "${GREEN}✅ Local files cleaned up${NC}"
}

# Function to stop LocalStack
stop_localstack() {
    echo -e "${YELLOW}Stopping LocalStack...${NC}"
    docker-compose down
    echo -e "${GREEN}✅ LocalStack stopped${NC}"
}

# Main cleanup flow
main() {
    case "${1:-resources}" in
        "resources")
            if check_localstack; then
                cleanup_stepfunctions
                cleanup_lambda
                cleanup_iam
                cleanup_files
            fi
            ;;
        "all")
            if check_localstack; then
                cleanup_stepfunctions
                cleanup_lambda
                cleanup_iam
            fi
            cleanup_files
            stop_localstack
            ;;
        "files")
            cleanup_files
            ;;
        *)
            echo -e "${RED}Usage: $0 [resources|all|files]${NC}"
            echo -e "${YELLOW}  resources - Clean up AWS resources only (default)${NC}"
            echo -e "${YELLOW}  all       - Clean up everything including LocalStack${NC}"
            echo -e "${YELLOW}  files     - Clean up local files only${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}🎉 Cleanup completed!${NC}"
}

# Run main function
main "$@"

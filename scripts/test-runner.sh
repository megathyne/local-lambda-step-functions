#!/bin/bash

# Test runner script for the Step Functions POC
# This script provides different test execution modes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if LocalStack is running
check_localstack() {
    if curl -s http://localhost:4566/health > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for LocalStack
wait_for_localstack() {
    print_status "Waiting for LocalStack to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if check_localstack; then
            print_success "LocalStack is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - LocalStack not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "LocalStack failed to start within $max_attempts attempts"
    return 1
}

# Function to run unit tests
run_unit_tests() {
    print_status "Running unit tests..."
    npm run test:unit
    print_success "Unit tests completed"
}

# Function to run integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    
    if ! check_localstack; then
        print_error "LocalStack is not running. Please start it first with 'make start'"
        exit 1
    fi
    
    npm run test:integration
    print_success "Integration tests completed"
}

# Function to run end-to-end tests
run_e2e_tests() {
    print_status "Running end-to-end tests..."
    
    if ! check_localstack; then
        print_error "LocalStack is not running. Please start it first with 'make start'"
        exit 1
    fi
    
    npm run test:e2e
    print_success "End-to-end tests completed"
}

# Function to run all tests
run_all_tests() {
    print_status "Running all tests..."
    
    # Run unit tests first (no dependencies)
    run_unit_tests
    
    # Check if LocalStack is needed for integration/e2e tests
    if check_localstack; then
        run_integration_tests
        run_e2e_tests
    else
        print_warning "LocalStack is not running. Skipping integration and e2e tests."
        print_warning "To run all tests, start LocalStack with 'make start' and deploy with 'make deploy'"
    fi
    
    print_success "All available tests completed"
}

# Function to run tests with coverage
run_coverage_tests() {
    print_status "Running tests with coverage..."
    npm run test:coverage
    print_success "Coverage tests completed"
}

# Function to run linting
run_lint() {
    print_status "Running ESLint..."
    npm run lint
    print_success "Linting completed"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing test dependencies..."
    npm install
    print_success "Dependencies installed"
}

# Main script logic
case "${1:-all}" in
    "unit")
        run_unit_tests
        ;;
    "integration")
        run_integration_tests
        ;;
    "e2e")
        run_e2e_tests
        ;;
    "all")
        run_all_tests
        ;;
    "coverage")
        run_coverage_tests
        ;;
    "lint")
        run_lint
        ;;
    "install")
        install_dependencies
        ;;
    "ci")
        print_status "Running CI tests..."
        npm run test:ci
        print_success "CI tests completed"
        ;;
    "help"|"-h"|"--help")
        echo "Test Runner for Step Functions POC"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  unit        - Run unit tests only"
        echo "  integration - Run integration tests (requires LocalStack)"
        echo "  e2e         - Run end-to-end tests (requires LocalStack)"
        echo "  all         - Run all available tests (default)"
        echo "  coverage    - Run tests with coverage report"
        echo "  lint        - Run ESLint"
        echo "  install     - Install test dependencies"
        echo "  ci          - Run CI tests (no watch mode)"
        echo "  help        - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                    # Run all available tests"
        echo "  $0 unit              # Run only unit tests"
        echo "  $0 integration        # Run integration tests"
        echo "  $0 coverage           # Run tests with coverage"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' to see available commands"
        exit 1
        ;;
esac

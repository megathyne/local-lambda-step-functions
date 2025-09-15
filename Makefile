# Makefile for LocalStack Step Functions POC

.PHONY: help start stop deploy test clean list status install test-unit test-integration test-e2e test-all lint

# Default target
help:
	@echo "AWS Step Functions POC with LocalStack"
	@echo ""
	@echo "Available commands:"
	@echo "  start   - Start LocalStack container"
	@echo "  stop    - Stop LocalStack container"
	@echo "  deploy  - Deploy Lambda functions and Step Functions"
	@echo "  test    - Test the complete workflow"
	@echo "  clean   - Clean up all resources"
	@echo "  list    - List deployed resources"
	@echo "  status  - Check LocalStack status"
	@echo "  logs    - Show LocalStack logs"
	@echo ""
	@echo "Testing commands:"
	@echo "  install         - Install test dependencies"
	@echo "  test-unit       - Run unit tests"
	@echo "  test-integration - Run integration tests (requires LocalStack)"
	@echo "  test-e2e        - Run end-to-end tests (requires LocalStack)"
	@echo "  test-all        - Run all tests"
	@echo "  lint            - Run ESLint"
	@echo ""

# Start LocalStack
start:
	@echo "🚀 Starting LocalStack..."
	docker-compose up -d
	@echo "⏳ Waiting for LocalStack to be ready..."
	@timeout 60 bash -c 'until curl -s http://localhost:4566/health > /dev/null; do sleep 2; done' || echo "⚠️  LocalStack may still be starting"
	@echo "✅ LocalStack is ready!"

# Stop LocalStack
stop:
	@echo "🛑 Stopping LocalStack..."
	docker-compose down
	@echo "✅ LocalStack stopped"

# Deploy resources
deploy:
	@echo "📦 Deploying resources..."
	@./scripts/deploy.sh
	@echo "✅ Deployment completed"

# Test workflow
test:
	@echo "🧪 Testing workflow..."
	@./scripts/test-workflow.sh workflow
	@echo "✅ Testing completed"

# Clean up resources
clean:
	@echo "🧹 Cleaning up resources..."
	@./scripts/cleanup.sh
	@echo "✅ Cleanup completed"

# List resources
list:
	@echo "📋 Listing resources..."
	@./scripts/test.sh list

# Check status
status:
	@echo "🔍 Checking LocalStack status..."
	@curl -s http://localhost:4566/health | jq '.' || echo "❌ LocalStack is not running"

# Show logs
logs:
	@echo "📜 Showing LocalStack logs..."
	docker-compose logs -f localstack

# Full workflow: start, deploy, test
all: start deploy test
	@echo "🎉 Full workflow completed!"

# Quick test (assumes LocalStack is already running)
quick-test:
	@echo "⚡ Running quick test..."
	@./scripts/test.sh

# Install test dependencies
install:
	@echo "📦 Installing test dependencies..."
	@npm install
	@echo "✅ Dependencies installed"

# Run unit tests
test-unit:
	@echo "🧪 Running unit tests..."
	@npm run test:unit
	@echo "✅ Unit tests completed"

# Run integration tests (requires LocalStack)
test-integration:
	@echo "🔗 Running integration tests..."
	@npm run test:integration
	@echo "✅ Integration tests completed"

# Run end-to-end tests (requires LocalStack)
test-e2e:
	@echo "🎯 Running end-to-end tests..."
	@npm run test:e2e
	@echo "✅ End-to-end tests completed"

# Run all tests
test-all: test-unit test-integration test-e2e
	@echo "🎉 All tests completed!"

# Run linting
lint:
	@echo "🔍 Running ESLint..."
	@npm run lint
	@echo "✅ Linting completed"

# Test with coverage
test-coverage:
	@echo "📊 Running tests with coverage..."
	@npm run test:coverage
	@echo "✅ Coverage report generated"

# CI test (no watch mode)
test-ci:
	@echo "🤖 Running CI tests..."
	@npm run test:ci
	@echo "✅ CI tests completed"

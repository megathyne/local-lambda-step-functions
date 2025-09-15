# Makefile for LocalStack Step Functions POC

.PHONY: help start stop deploy test clean list status

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

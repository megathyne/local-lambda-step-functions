# AWS Step Functions with Lambda POC using LocalStack

This project demonstrates how to test AWS Step Functions with Lambda functions locally using LocalStack. It provides a complete POC (Proof of Concept) setup for local development and testing of serverless workflows.

## 🏗️ Architecture

The POC implements a simple 3-step workflow:

1. **Hello World Lambda** - Generates a greeting message
2. **Process Data Lambda** - Processes the greeting and adds metadata
3. **Notify Completion Lambda** - Sends a completion notification with summary

```
Input → Hello World → Process Data → Notify Completion → Output
```

## 📁 Project Structure

```
local-stack/
├── docker-compose.yml              # LocalStack configuration
├── step-function-definition.json   # Step Functions state machine definition
├── lambda-functions/               # Lambda function code
│   ├── hello-world/
│   │   ├── index.js
│   │   └── package.json
│   ├── process-data/
│   │   ├── index.js
│   │   └── package.json
│   └── notify-completion/
│       ├── index.js
│       └── package.json
├── scripts/                        # Deployment and testing scripts
│   ├── deploy.sh                   # Deploy all resources
│   ├── test.sh                     # Test the workflow
│   └── cleanup.sh                  # Clean up resources
└── tmp/                           # Temporary files (created by LocalStack)
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- AWS CLI v2
- jq (for JSON processing)
- curl
- Node.js 18+ (for Lambda function development)
- npm (for testing dependencies)

### 1. Start LocalStack

```bash
docker-compose up -d
```

Wait for LocalStack to be ready (usually takes 30-60 seconds).

### 2. Deploy Resources

```bash
./scripts/deploy.sh
```

This script will:
- Create IAM roles for Lambda and Step Functions
- Package and deploy Lambda functions
- Create the Step Functions state machine

### 3. Test the Workflow

```bash
./scripts/test.sh
```

This will test both individual Lambda functions and the complete Step Functions workflow.

### 4. Run Tests

```bash
# Install test dependencies
make install

# Run all tests
make test-all

# Or run specific test types
make test-unit        # Unit tests only
make test-integration # Integration tests (requires LocalStack)
make test-e2e         # End-to-end tests (requires LocalStack)
```

### 5. Clean Up

```bash
./scripts/cleanup.sh
```

## 🧪 Testing

This project includes a comprehensive testing suite with three levels of testing:

### Test Types

1. **Unit Tests** - Test individual Lambda functions in isolation
2. **Integration Tests** - Test Lambda functions and Step Functions with LocalStack
3. **End-to-End Tests** - Test complete workflow execution

### Quick Test Commands

```bash
# Install test dependencies
make install

# Run all available tests
make test-all

# Run specific test types
make test-unit        # Unit tests only (fast, no dependencies)
make test-integration # Integration tests (requires LocalStack)
make test-e2e         # End-to-end tests (requires LocalStack)

# Run with coverage
make test-coverage

# Run linting
make lint
```

### Test Requirements

- **Unit Tests**: No external dependencies, run anywhere
- **Integration Tests**: Requires LocalStack running and resources deployed
- **End-to-End Tests**: Requires LocalStack running and resources deployed

For detailed testing information, see [TESTING.md](TESTING.md).

## 🔧 Detailed Usage

### Testing Individual Components

Test only Lambda functions:
```bash
./scripts/test.sh lambda
```

Test only Step Functions workflow:
```bash
./scripts/test.sh stepfunctions
```

List all deployed resources:
```bash
./scripts/test.sh list
```

### Manual Testing with AWS CLI

You can also test components manually using AWS CLI:

```bash
# Set LocalStack endpoint
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# Test a Lambda function
aws lambda invoke \
  --function-name hello-world-function \
  --payload '{"name": "Test", "message": "Hello"}' \
  response.json

# Start Step Functions execution
aws stepfunctions start-execution \
  --state-machine-arn "arn:aws:states:us-east-1:000000000000:stateMachine:hello-world-workflow" \
  --name "manual-test" \
  --input '{"name": "Manual Test", "message": "Hello"}'
```

### LocalStack Web UI

LocalStack provides a web interface at `http://localhost:4566/_localstack/health` for monitoring services.

## 📊 Expected Output

When you run the test script, you should see output similar to:

```
🧪 Testing Step Functions Workflow
✅ LocalStack is running
🔍 Testing individual Lambda functions...
✅ hello-world function test passed
✅ process-data function test passed
✅ notify-completion function test passed

🔄 Testing Step Functions workflow...
✅ Step Functions execution started
Status: RUNNING (attempt 1/30)
Status: SUCCEEDED (attempt 2/30)
🎉 Step Functions execution completed successfully!
```

The final output will include a JSON summary of the completed workflow.

## 🛠️ Customization

### Adding New Lambda Functions

1. Create a new directory in `lambda-functions/`
2. Add your `index.js` file with the Lambda handler
3. Add a `package.json` file for the function
4. Update `step-function-definition.json` to include the new function
5. Update the deployment script to package the new function

### Modifying the Workflow

Edit `step-function-definition.json` to:
- Add new states
- Modify transitions
- Add error handling
- Change retry policies

### Environment Configuration

Modify `docker-compose.yml` to:
- Change ports
- Add environment variables
- Configure additional services

## 🔍 Troubleshooting

### Common Issues

1. **LocalStack not starting**
   ```bash
   docker-compose logs localstack
   ```

2. **Lambda functions not deploying**
   - Check if Docker is running
   - Verify LocalStack is healthy: `curl http://localhost:4566/_localstack/health`

3. **Lambda execution errors (NoSuchContainer)**
   - This is a known issue with LocalStack Lambda execution
   - The Step Functions workflow should still work despite individual Lambda test failures
   - Try restarting LocalStack: `docker-compose restart`

4. **Step Functions execution failing**
   - Check Lambda function logs in LocalStack
   - Verify IAM roles are created correctly
   - Ensure all Lambda functions are deployed successfully

5. **Permission errors**
   - Ensure scripts are executable: `chmod +x scripts/*.sh`

6. **Docker volume issues**
   - If you see "Device or resource busy" errors, remove volume mounts from docker-compose.yml
   - LocalStack works fine with its internal temporary directories

### Debugging

Enable debug mode in LocalStack by setting `DEBUG=1` in `docker-compose.yml`.

Check LocalStack logs:
```bash
docker-compose logs -f localstack
```

## 📚 Learning Resources

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [AWS Step Functions Developer Guide](https://docs.aws.amazon.com/step-functions/)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)

## 🤝 Contributing

Feel free to extend this POC with:
- Additional Lambda functions
- More complex Step Functions workflows
- Error handling scenarios
- Performance testing
- Integration with other AWS services

### Development Workflow

1. **Make changes** to Lambda functions or Step Functions definition
2. **Run unit tests** frequently: `make test-unit`
3. **Start LocalStack** and deploy: `make start && make deploy`
4. **Run integration tests**: `make test-integration`
5. **Run end-to-end tests**: `make test-e2e`
6. **Check coverage**: `make test-coverage`
7. **Run linting**: `make lint`
8. **Commit changes** when all tests pass

### CI/CD

The project includes GitHub Actions workflows that automatically:
- Run unit tests on every push/PR
- Run integration and e2e tests with LocalStack
- Generate coverage reports
- Provide test summaries

## 📄 License

This project is for educational and development purposes. Use it as a starting point for your own LocalStack-based development workflows.

# Testing Guide

This document provides comprehensive information about the testing suite implemented for the AWS Step Functions POC project.

## 🧪 Testing Strategy

The project implements a **hybrid testing approach** with three levels of testing:

1. **Unit Tests** - Test individual Lambda functions in isolation
2. **Integration Tests** - Test Lambda functions and Step Functions with LocalStack
3. **End-to-End Tests** - Test complete workflow execution

## 📁 Test Structure

```
tests/
├── setup.js                    # Global test configuration
├── unit/                       # Unit tests
│   ├── hello-world.test.js
│   ├── process-data.test.js
│   └── notify-completion.test.js
├── integration/               # Integration tests
│   ├── lambda-functions.test.js
│   └── step-functions.test.js
└── e2e/                       # End-to-end tests
    └── workflow.test.js
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Docker and Docker Compose
- npm

### Installation

```bash
# Install test dependencies
make install
# or
npm install
```

### Running Tests

```bash
# Run all available tests
make test-all

# Run specific test types
make test-unit        # Unit tests only
make test-integration # Integration tests (requires LocalStack)
make test-e2e         # End-to-end tests (requires LocalStack)

# Run with coverage
make test-coverage

# Run linting
make lint
```

## 📋 Test Types

### Unit Tests

**Purpose**: Test individual Lambda functions in isolation with mocked dependencies.

**Features**:
- Fast execution (no external dependencies)
- Comprehensive input validation
- Error handling scenarios
- Mocked AWS context objects

**Example**:
```bash
npm run test:unit
```

**Coverage**: Tests all Lambda function handlers with various input scenarios.

### Integration Tests

**Purpose**: Test Lambda functions and Step Functions using LocalStack.

**Requirements**:
- LocalStack running (`make start`)
- Resources deployed (`make deploy`)

**Features**:
- Tests actual AWS service interactions
- Validates Lambda function deployment
- Tests Step Functions state machine
- Verifies retry policies and error handling

**Example**:
```bash
# Start LocalStack and deploy resources first
make start
make deploy

# Then run integration tests
npm run test:integration
```

### End-to-End Tests

**Purpose**: Test complete workflow execution from start to finish.

**Requirements**:
- LocalStack running (`make start`)
- Resources deployed (`make deploy`)

**Features**:
- Complete workflow validation
- Data integrity across steps
- Concurrent execution testing
- Performance validation

**Example**:
```bash
# Start LocalStack and deploy resources first
make start
make deploy

# Then run e2e tests
npm run test:e2e
```

## 🛠️ Test Configuration

### Jest Configuration

Located in `package.json`:

```json
{
  "jest": {
    "testEnvironment": "node",
    "collectCoverageFrom": [
      "lambda-functions/**/*.js",
      "!lambda-functions/**/node_modules/**",
      "!lambda-functions/**/*.test.js"
    ],
    "coverageDirectory": "coverage",
    "coverageReporters": ["text", "lcov", "html"],
    "testMatch": ["**/tests/**/*.test.js"],
    "setupFilesAfterEnv": ["<rootDir>/tests/setup.js"],
    "testTimeout": 30000
  }
}
```

### ESLint Configuration

Located in `.eslintrc.js`:

```javascript
module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true,
  },
  extends: ['airbnb-base'],
  rules: {
    'no-console': 'off',
    'import/no-extraneous-dependencies': ['error', { devDependencies: true }],
  },
};
```

## 🔧 Test Scripts

### Available Scripts

| Script | Description |
|--------|-------------|
| `npm test` | Run all tests |
| `npm run test:unit` | Run unit tests only |
| `npm run test:integration` | Run integration tests |
| `npm run test:e2e` | Run end-to-end tests |
| `npm run test:watch` | Run tests in watch mode |
| `npm run test:coverage` | Run tests with coverage |
| `npm run test:ci` | Run tests for CI (no watch) |
| `npm run lint` | Run ESLint |
| `npm run lint:fix` | Run ESLint with auto-fix |

### Makefile Commands

| Command | Description |
|---------|-------------|
| `make install` | Install test dependencies |
| `make test-unit` | Run unit tests |
| `make test-integration` | Run integration tests |
| `make test-e2e` | Run end-to-end tests |
| `make test-all` | Run all available tests |
| `make test-coverage` | Run tests with coverage |
| `make test-ci` | Run CI tests |
| `make lint` | Run linting |

## 📊 Coverage Reports

Coverage reports are generated in the `coverage/` directory:

- **HTML Report**: `coverage/lcov-report/index.html`
- **LCOV Report**: `coverage/lcov.info`
- **Text Report**: Displayed in terminal

### Coverage Targets

- **Statements**: > 90%
- **Branches**: > 85%
- **Functions**: > 90%
- **Lines**: > 90%

## 🐛 Debugging Tests

### Enable Debug Output

```bash
# Enable debug logging for tests
DEBUG_TESTS=1 npm test
```

### Test Individual Files

```bash
# Run specific test file
npx jest tests/unit/hello-world.test.js

# Run tests matching pattern
npx jest --testNamePattern="should return greeting"
```

### LocalStack Debugging

```bash
# Check LocalStack status
make status

# View LocalStack logs
make logs

# Restart LocalStack
make stop
make start
```

## 🔄 CI/CD Integration

### GitHub Actions

The project includes a GitHub Actions workflow (`.github/workflows/test.yml`) that:

1. Runs unit tests on every push/PR
2. Runs integration tests with LocalStack
3. Runs end-to-end tests with LocalStack
4. Generates coverage reports
5. Provides test summary

### Local Development

```bash
# Full development workflow
make start      # Start LocalStack
make deploy     # Deploy resources
make test-all   # Run all tests
make clean      # Clean up
```

## 📝 Writing Tests

### Unit Test Example

```javascript
const { handler } = require('../../lambda-functions/hello-world/index');

describe('Hello World Lambda Function', () => {
  let mockContext;

  beforeEach(() => {
    mockContext = {
      awsRequestId: 'test-request-id-123',
      // ... other context properties
    };
  });

  test('should return greeting with provided name and message', async () => {
    const event = { name: 'John', message: 'Hello' };
    const result = await handler(event, mockContext);
    
    expect(result.statusCode).toBe(200);
    expect(result.body.greeting).toBe('Hello, John!');
  });
});
```

### Integration Test Example

```javascript
const AWS = require('aws-sdk');

const lambda = new AWS.Lambda({
  endpoint: 'http://localhost:4566',
  region: 'us-east-1',
  accessKeyId: 'test',
  secretAccessKey: 'test',
});

describe('Lambda Functions Integration Tests', () => {
  test('hello-world function should be deployed and invokable', async () => {
    const result = await lambda.invoke({
      FunctionName: 'hello-world-function',
      Payload: JSON.stringify({ name: 'Test', message: 'Hello' })
    }).promise();

    expect(result.StatusCode).toBe(200);
  });
});
```

## 🚨 Troubleshooting

### Common Issues

1. **LocalStack not starting**
   ```bash
   docker-compose logs localstack
   ```

2. **Tests timing out**
   - Increase timeout in Jest config
   - Check LocalStack health

3. **Coverage not generated**
   - Ensure tests are running successfully
   - Check Jest configuration

4. **ESLint errors**
   ```bash
   npm run lint:fix
   ```

### Performance Tips

- Run unit tests frequently during development
- Use `npm run test:watch` for continuous testing
- Run integration/e2e tests before committing
- Use `make test-ci` for CI environments

## 📚 Additional Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [AWS SDK Mock](https://github.com/dwyl/aws-sdk-mock)
- [LocalStack Documentation](https://docs.localstack.cloud/)
- [ESLint Configuration](https://eslint.org/docs/user-guide/configuring)

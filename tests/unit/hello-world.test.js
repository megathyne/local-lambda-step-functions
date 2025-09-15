const { handler } = require('../../lambda-functions/hello-world/index');

describe('Hello World Lambda Function', () => {
  let mockContext;

  beforeEach(() => {
    mockContext = {
      awsRequestId: 'test-request-id-123',
      functionName: 'hello-world-function',
      functionVersion: '$LATEST',
      invokedFunctionArn: 'arn:aws:lambda:us-east-1:123456789012:function:hello-world-function',
      memoryLimitInMB: '128',
      remainingTimeInMillis: 30000,
      logGroupName: '/aws/lambda/hello-world-function',
      logStreamName: '2023/01/01/[$LATEST]test-stream',
      getRemainingTimeInMillis: () => 30000,
      done: jest.fn(),
      fail: jest.fn(),
      succeed: jest.fn()
    };
  });

  test('should return greeting with provided name and message', async () => {
    const event = {
      name: 'John',
      message: 'Hello'
    };

    const result = await handler(event, mockContext);

    expect(result).toEqual({
      statusCode: 200,
      body: {
        greeting: 'Hello, John!',
        timestamp: 'test-request-id-123',
        step: 'hello-world',
        processed: true
      }
    });
  });

  test('should use default values when name and message are not provided', async () => {
    const event = {};

    const result = await handler(event, mockContext);

    expect(result).toEqual({
      statusCode: 200,
      body: {
        greeting: 'Hello, World!',
        timestamp: 'test-request-id-123',
        step: 'hello-world',
        processed: true
      }
    });
  });

  test('should handle empty string inputs', async () => {
    const event = {
      name: '',
      message: ''
    };

    const result = await handler(event, mockContext);

    expect(result).toEqual({
      statusCode: 200,
      body: {
        greeting: 'Hello, World!',
        timestamp: 'test-request-id-123',
        step: 'hello-world',
        processed: true
      }
    });
  });

  test('should handle null and undefined inputs', async () => {
    const event = {
      name: null,
      message: undefined
    };

    const result = await handler(event, mockContext);

    expect(result).toEqual({
      statusCode: 200,
      body: {
        greeting: 'Hello, World!',
        timestamp: 'test-request-id-123',
        step: 'hello-world',
        processed: true
      }
    });
  });

  test('should use context awsRequestId as timestamp', async () => {
    const customContext = {
      ...mockContext,
      awsRequestId: 'custom-request-id-456'
    };

    const event = { name: 'Test', message: 'Hi' };
    const result = await handler(event, customContext);

    expect(result.body.timestamp).toBe('custom-request-id-456');
  });
});

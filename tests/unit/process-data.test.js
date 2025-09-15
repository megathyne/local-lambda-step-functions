const { handler } = require('../../lambda-functions/process-data/index');

describe('Process Data Lambda Function', () => {
  let mockContext;

  beforeEach(() => {
    mockContext = {
      awsRequestId: 'test-request-id-123',
      functionName: 'process-data-function',
      functionVersion: '$LATEST',
      invokedFunctionArn: 'arn:aws:lambda:us-east-1:123456789012:function:process-data-function',
      memoryLimitInMB: '128',
      remainingTimeInMillis: 30000,
      logGroupName: '/aws/lambda/process-data-function',
      logStreamName: '2023/01/01/[$LATEST]test-stream',
      getRemainingTimeInMillis: () => 30000,
      done: jest.fn(),
      fail: jest.fn(),
      succeed: jest.fn()
    };

    // Mock setTimeout to avoid actual delays in tests
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  test('should process greeting data correctly', async () => {
    const event = {
      body: {
        greeting: 'Hello, World!',
        timestamp: 'test-timestamp-123',
        step: 'hello-world',
        processed: true
      }
    };

    const resultPromise = handler(event, mockContext);

    // Fast-forward timers to complete the setTimeout
    jest.runAllTimers();

    const result = await resultPromise;

    expect(result.statusCode).toBe(200);
    expect(result.body).toMatchObject({
      original_greeting: 'Hello, World!',
      processed_at: 'test-timestamp-123',
      processing_time: expect.any(Number),
      word_count: 2,
      character_count: 13,
      step: 'process-data',
      status: 'completed'
    });
    expect(result.body.processing_time).toBeGreaterThanOrEqual(0.5);
    expect(result.body.processing_time).toBeLessThanOrEqual(2.0);
  });

  test('should handle partial body data', async () => {
    const event = {
      body: {
        greeting: 'Hi there'
      }
    };

    const resultPromise = handler(event, mockContext);
    jest.runAllTimers();
    const result = await resultPromise;

    expect(result.statusCode).toBe(200);
    expect(result.body).toMatchObject({
      original_greeting: 'Hi there',
      processed_at: '',
      processing_time: expect.any(Number),
      word_count: 2,
      character_count: 8,
      step: 'process-data',
      status: 'completed'
    });
  });

});

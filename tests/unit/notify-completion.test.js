const { handler } = require('../../lambda-functions/notify-completion/index');

describe('Notify Completion Lambda Function', () => {
  let mockContext;

  beforeEach(() => {
    mockContext = {
      awsRequestId: 'test-request-id-123',
      functionName: 'notify-completion-function',
      functionVersion: '$LATEST',
      invokedFunctionArn: 'arn:aws:lambda:us-east-1:123456789012:function:notify-completion-function',
      memoryLimitInMB: '128',
      remainingTimeInMillis: 30000,
      logGroupName: '/aws/lambda/notify-completion-function',
      logStreamName: '2023/01/01/[$LATEST]test-stream',
      getRemainingTimeInMillis: () => 30000,
      done: jest.fn(),
      fail: jest.fn(),
      succeed: jest.fn()
    };
  });

  test('should create completion summary with processed data', async () => {
    const event = {
      body: {
        original_greeting: 'Hello, World!',
        processed_at: 'test-timestamp-123',
        processing_time: 1.5,
        word_count: 2,
        character_count: 13,
        step: 'process-data',
        status: 'completed'
      }
    };

    const result = await handler(event, mockContext);

    expect(result).toEqual({
      statusCode: 200,
      body: {
        workflow_status: 'completed',
        final_step: 'notify-completion',
        summary: {
          original_greeting: 'Hello, World!',
          processing_time: 1.5,
          word_count: 2,
          character_count: 13,
          total_steps: 3,
          completion_message: 'Workflow completed successfully!'
        },
        timestamp: 'test-request-id-123'
      }
    });
  });

  test('should handle missing body data gracefully', async () => {
    const event = {};

    const result = await handler(event, mockContext);

    expect(result).toEqual({
      statusCode: 200,
      body: {
        workflow_status: 'completed',
        final_step: 'notify-completion',
        summary: {
          original_greeting: '',
          processing_time: 0,
          word_count: 0,
          character_count: 0,
          total_steps: 3,
          completion_message: 'Workflow completed successfully!'
        },
        timestamp: 'test-request-id-123'
      }
    });
  });

  test('should handle partial body data', async () => {
    const event = {
      body: {
        original_greeting: 'Hi there',
        processing_time: 0.8
      }
    };

    const result = await handler(event, mockContext);

    expect(result.body.summary).toMatchObject({
      original_greeting: 'Hi there',
      processing_time: 0.8,
      word_count: 0,
      character_count: 0,
      total_steps: 3,
      completion_message: 'Workflow completed successfully!'
    });
  });

  test('should use context awsRequestId as timestamp', async () => {
    const customContext = {
      ...mockContext,
      awsRequestId: 'custom-request-id-456'
    };

    const event = {
      body: {
        original_greeting: 'Test'
      }
    };

    const result = await handler(event, customContext);

    expect(result.body.timestamp).toBe('custom-request-id-456');
  });

  test('should always return total_steps as 3', async () => {
    const event = {
      body: {
        original_greeting: 'Test'
      }
    };

    const result = await handler(event, mockContext);

    expect(result.body.summary.total_steps).toBe(3);
  });

  test('should always return workflow_status as completed', async () => {
    const event = {
      body: {
        original_greeting: 'Test'
      }
    };

    const result = await handler(event, mockContext);

    expect(result.body.workflow_status).toBe('completed');
    expect(result.body.final_step).toBe('notify-completion');
  });
});

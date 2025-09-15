const AWS = require('aws-sdk');

// Configure AWS SDK for LocalStack
const lambda = new AWS.Lambda({
  endpoint: process.env.AWS_ENDPOINT_URL || 'http://localhost:4566',
  region: process.env.AWS_REGION || 'us-east-1',
  accessKeyId: 'test',
  secretAccessKey: 'test',
});

const stepFunctions = new AWS.StepFunctions({
  endpoint: process.env.AWS_ENDPOINT_URL || 'http://localhost:4566',
  region: process.env.AWS_REGION || 'us-east-1',
  accessKeyId: 'test',
  secretAccessKey: 'test',
});

describe('Lambda Functions Integration Tests', () => {
  const testTimeout = 30000;

  beforeAll(async () => {
    // Wait for LocalStack to be ready
    await waitForLocalStack();
  });

  test('hello-world function should be deployed and invokable', async () => {
    const testEvent = {
      name: 'Integration Test',
      message: 'Hello'
    };

    const result = await lambda.invoke({
      FunctionName: 'hello-world-function',
      Payload: JSON.stringify(testEvent)
    }).promise();

    expect(result.StatusCode).toBe(200);
    
    const response = JSON.parse(result.Payload);
    expect(response.statusCode).toBe(200);
    expect(response.body.greeting).toBe('Hello, Integration Test!');
    expect(response.body.step).toBe('hello-world');
    expect(response.body.processed).toBe(true);
  }, testTimeout);

  test('process-data function should be deployed and invokable', async () => {
    const testEvent = {
      body: {
        greeting: 'Hello, Integration Test!',
        timestamp: 'test-timestamp',
        step: 'hello-world',
        processed: true
      }
    };

    const result = await lambda.invoke({
      FunctionName: 'process-data-function',
      Payload: JSON.stringify(testEvent)
    }).promise();

    expect(result.StatusCode).toBe(200);
    
    const response = JSON.parse(result.Payload);
    expect(response.statusCode).toBe(200);
    expect(response.body.original_greeting).toBe('Hello, Integration Test!');
    expect(response.body.step).toBe('process-data');
    expect(response.body.status).toBe('completed');
    expect(response.body.word_count).toBe(3);
    expect(response.body.character_count).toBe(24);
  }, testTimeout);

  test('notify-completion function should be deployed and invokable', async () => {
    const testEvent = {
      body: {
        original_greeting: 'Hello, Integration Test!',
        processed_at: 'test-timestamp',
        processing_time: 1.5,
        word_count: 3,
        character_count: 22,
        step: 'process-data',
        status: 'completed'
      }
    };

    const result = await lambda.invoke({
      FunctionName: 'notify-completion-function',
      Payload: JSON.stringify(testEvent)
    }).promise();

    expect(result.StatusCode).toBe(200);
    
    const response = JSON.parse(result.Payload);
    expect(response.statusCode).toBe(200);
    expect(response.body.workflow_status).toBe('completed');
    expect(response.body.final_step).toBe('notify-completion');
    expect(response.body.summary.total_steps).toBe(3);
    expect(response.body.summary.completion_message).toBe('Workflow completed successfully!');
  }, testTimeout);

  test('lambda functions should handle error cases gracefully', async () => {
    // Test with malformed input
    const malformedEvent = 'invalid json';

    const result = await lambda.invoke({
      FunctionName: 'hello-world-function',
      Payload: malformedEvent
    }).promise();

    // Should still return a response (Lambda handles JSON parsing)
    expect(result.StatusCode).toBe(200);
  }, testTimeout);
});

// Helper function to wait for LocalStack
async function waitForLocalStack(maxAttempts = 30) {
  for (let i = 0; i < maxAttempts; i++) {
    try {
      // Use a simple HTTP health check instead of AWS SDK calls
      const response = await fetch('http://localhost:4566/_localstack/health');
      if (response.ok) {
        const health = await response.json();
        if (health.services && health.services.lambda === 'running') {
          return;
        }
      }
    } catch (error) {
      // Ignore errors and continue
    }
    
    if (i === maxAttempts - 1) {
      throw new Error('LocalStack is not ready after maximum attempts');
    }
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
}

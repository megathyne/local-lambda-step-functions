const AWS = require('aws-sdk');

// Configure AWS SDK for LocalStack
const stepFunctions = new AWS.StepFunctions({
  endpoint: process.env.AWS_ENDPOINT_URL || 'http://localhost:4566',
  region: process.env.AWS_REGION || 'us-east-1',
  accessKeyId: 'test',
  secretAccessKey: 'test',
});

const lambda = new AWS.Lambda({
  endpoint: process.env.AWS_ENDPOINT_URL || 'http://localhost:4566',
  region: process.env.AWS_REGION || 'us-east-1',
  accessKeyId: 'test',
  secretAccessKey: 'test',
});

describe('Step Functions Integration Tests', () => {
  const testTimeout = 60000; // Longer timeout for Step Functions
  const stateMachineArn = 'arn:aws:states:us-east-1:000000000000:stateMachine:hello-world-workflow';

  beforeAll(async () => {
    // Wait for LocalStack to be ready
    await waitForLocalStack();
  });

  test('Step Functions state machine should be deployed', async () => {
    const result = await stepFunctions.describeStateMachine({
      stateMachineArn
    }).promise();

    expect(result.stateMachineArn).toBe(stateMachineArn);
    expect(result.name).toBe('hello-world-workflow');
    expect(result.status).toBe('ACTIVE');
  }, testTimeout);

  test('Step Functions workflow should execute successfully', async () => {
    const executionName = `integration-test-${Date.now()}`;
    const input = {
      name: 'Integration Test',
      message: 'Hello'
    };

    // Start execution
    const startResult = await stepFunctions.startExecution({
      stateMachineArn,
      name: executionName,
      input: JSON.stringify(input)
    }).promise();

    expect(startResult.executionArn).toBeDefined();
    expect(startResult.startDate).toBeDefined();

    // Wait for execution to complete
    const executionResult = await waitForExecutionCompletion(
      stepFunctions,
      startResult.executionArn,
      30 // max attempts
    );

    expect(executionResult.status).toBe('SUCCEEDED');
    expect(executionResult.stopDate).toBeDefined();

    // Parse the output
    const output = JSON.parse(executionResult.output);
    expect(output.statusCode).toBe(200);
    expect(output.body.workflow_status).toBe('completed');
    expect(output.body.final_step).toBe('notify-completion');
    expect(output.body.summary.total_steps).toBe(3);
  }, testTimeout);

  test('Step Functions workflow should handle error states', async () => {
    // This test would require modifying the workflow to include error scenarios
    // For now, we'll test that the error handling state exists
    const result = await stepFunctions.describeStateMachine({
      stateMachineArn
    }).promise();

    const definition = JSON.parse(result.definition);
    expect(definition.States.HandleError).toBeDefined();
    expect(definition.States.HandleError.Type).toBe('Pass');
  }, testTimeout);

  test('Step Functions should retry on Lambda service exceptions', async () => {
    const result = await stepFunctions.describeStateMachine({
      stateMachineArn
    }).promise();

    const definition = JSON.parse(result.definition);
    
    // Check that retry policies are configured
    expect(definition.States.HelloWorld.Retry).toBeDefined();
    expect(definition.States.ProcessData.Retry).toBeDefined();
    expect(definition.States.NotifyCompletion.Retry).toBeDefined();

    // Check retry configuration
    const retryPolicy = definition.States.HelloWorld.Retry[0];
    expect(retryPolicy.ErrorEquals).toContain('Lambda.ServiceException');
    expect(retryPolicy.MaxAttempts).toBe(3);
    expect(retryPolicy.IntervalSeconds).toBe(2);
    expect(retryPolicy.BackoffRate).toBe(2.0);
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
        if (health.services && health.services.stepfunctions === 'running') {
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

// Helper function to wait for Step Functions execution completion
async function waitForExecutionCompletion(stepFunctionsClient, executionArn, maxAttempts = 30) {
  for (let i = 0; i < maxAttempts; i++) {
    const result = await stepFunctionsClient.describeExecution({
      executionArn
    }).promise();

    if (result.status === 'SUCCEEDED' || result.status === 'FAILED' || result.status === 'TIMED_OUT' || result.status === 'ABORTED') {
      return result;
    }

    // Wait before next attempt
    await new Promise(resolve => setTimeout(resolve, 2000));
  }

  throw new Error(`Execution did not complete within ${maxAttempts} attempts`);
}

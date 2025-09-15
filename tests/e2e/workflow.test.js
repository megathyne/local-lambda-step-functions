const AWS = require('aws-sdk');
const { execSync } = require('child_process');

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

describe('End-to-End Workflow Tests', () => {
  const testTimeout = 120000; // 2 minutes for E2E tests
  const stateMachineArn = 'arn:aws:states:us-east-1:000000000000:stateMachine:hello-world-workflow';

  beforeAll(async () => {
    // Ensure LocalStack is running and resources are deployed
    await ensureEnvironmentReady();
  });

  test('Complete workflow should execute from start to finish', async () => {
    const executionName = `e2e-test-${Date.now()}`;
    const input = {
      name: 'E2E Test User',
      message: 'Hello from E2E'
    };

    // Start the complete workflow
    const startResult = await stepFunctions.startExecution({
      stateMachineArn,
      name: executionName,
      input: JSON.stringify(input)
    }).promise();

    expect(startResult.executionArn).toBeDefined();

    // Wait for complete execution
    const executionResult = await waitForExecutionCompletion(
      stepFunctions,
      startResult.executionArn,
      60 // max attempts (2 minutes)
    );

    expect(executionResult.status).toBe('SUCCEEDED');

    // Verify the complete workflow output
    const output = JSON.parse(executionResult.output);
    expect(output.statusCode).toBe(200);
    expect(output.body.workflow_status).toBe('completed');
    expect(output.body.final_step).toBe('notify-completion');
    
    // Verify the data flow through all steps
    const summary = output.body.summary;
    expect(summary.original_greeting).toBe('Hello from E2E, E2E Test User!');
    expect(summary.processing_time).toBeGreaterThan(0);
    expect(summary.word_count).toBeGreaterThan(0);
    expect(summary.character_count).toBeGreaterThan(0);
    expect(summary.total_steps).toBe(3);
    expect(summary.completion_message).toBe('Workflow completed successfully!');
  }, testTimeout);

  test('Workflow should handle different input variations', async () => {
    const testCases = [
      {
        name: 'Alice',
        message: 'Hi',
        expectedGreeting: 'Hi, Alice!'
      },
      {
        name: 'Bob',
        message: 'Good morning',
        expectedGreeting: 'Good morning, Bob!'
      },
      {
        name: '',
        message: 'Hello',
        expectedGreeting: 'Hello, World!'
      }
    ];

    for (const testCase of testCases) {
      const executionName = `e2e-variation-${Date.now()}-${Math.random()}`;
      
      const startResult = await stepFunctions.startExecution({
        stateMachineArn,
        name: executionName,
        input: JSON.stringify(testCase)
      }).promise();

      const executionResult = await waitForExecutionCompletion(
        stepFunctions,
        startResult.executionArn,
        30
      );

      expect(executionResult.status).toBe('SUCCEEDED');
      
      const output = JSON.parse(executionResult.output);
      expect(output.body.summary.original_greeting).toBe(testCase.expectedGreeting);
    }
  }, testTimeout);

  test('Workflow should maintain data integrity across steps', async () => {
    const executionName = `e2e-data-integrity-${Date.now()}`;
    const input = {
      name: 'Data Integrity Test',
      message: 'Testing data flow'
    };

    const startResult = await stepFunctions.startExecution({
      stateMachineArn,
      name: executionName,
      input: JSON.stringify(input)
    }).promise();

    const executionResult = await waitForExecutionCompletion(
      stepFunctions,
      startResult.executionArn,
      30
    );

    expect(executionResult.status).toBe('SUCCEEDED');

    const output = JSON.parse(executionResult.output);
    const summary = output.body.summary;

    // Verify data consistency
    expect(summary.original_greeting).toContain('Testing data flow');
    expect(summary.original_greeting).toContain('Data Integrity Test');
    expect(summary.word_count).toBe(summary.original_greeting.split(' ').length);
    expect(summary.character_count).toBe(summary.original_greeting.length);
    expect(summary.processing_time).toBeGreaterThan(0.5);
    expect(summary.processing_time).toBeLessThan(2.5);
  }, testTimeout);

  test('Workflow should handle concurrent executions', async () => {
    const concurrentExecutions = 3;
    const executionPromises = [];

    for (let i = 0; i < concurrentExecutions; i++) {
      const executionName = `e2e-concurrent-${Date.now()}-${i}`;
      const input = {
        name: `Concurrent User ${i}`,
        message: `Message ${i}`
      };

      const promise = stepFunctions.startExecution({
        stateMachineArn,
        name: executionName,
        input: JSON.stringify(input)
      }).promise().then(startResult => 
        waitForExecutionCompletion(stepFunctions, startResult.executionArn, 30)
      );

      executionPromises.push(promise);
    }

    const results = await Promise.all(executionPromises);

    // All executions should succeed
    results.forEach(result => {
      expect(result.status).toBe('SUCCEEDED');
    });

    // Verify each execution has unique output
    const outputs = results.map(result => JSON.parse(result.output));
    const greetings = outputs.map(output => output.body.summary.original_greeting);
    
    // All greetings should be unique
    const uniqueGreetings = [...new Set(greetings)];
    expect(uniqueGreetings.length).toBe(concurrentExecutions);
  }, testTimeout);
});

// Helper function to ensure environment is ready
async function ensureEnvironmentReady() {
  try {
    // Check if LocalStack is running using health endpoint
    const response = await fetch('http://localhost:4566/_localstack/health');
    if (!response.ok) {
      throw new Error('LocalStack health check failed');
    }
    
    const health = await response.json();
    if (health.services.stepfunctions !== 'running') {
      throw new Error('Step Functions service not running');
    }
    
    // Verify the state machine exists
    const stateMachines = await stepFunctions.listStateMachines().promise();
    const ourStateMachine = stateMachines.stateMachines.find(
      sm => sm.name === 'hello-world-workflow'
    );
    
    if (!ourStateMachine) {
      throw new Error('State machine not found. Please run deployment first.');
    }
  } catch (error) {
    throw new Error(`Environment not ready: ${error.message}. Please ensure LocalStack is running and resources are deployed.`);
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

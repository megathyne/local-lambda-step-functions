// Global test setup
const AWS = require('aws-sdk');

// Set up test environment variables
process.env.AWS_REGION = 'us-east-1';
process.env.AWS_ACCESS_KEY_ID = 'test';
process.env.AWS_SECRET_ACCESS_KEY = 'test';
process.env.AWS_ENDPOINT_URL = 'http://localhost:4566';

// Global test timeout
jest.setTimeout(30000);

// Console log suppression for cleaner test output
const originalConsoleLog = console.log;
const originalConsoleError = console.error;

beforeAll(() => {
  // Suppress console logs during tests unless explicitly needed
  if (process.env.NODE_ENV === 'test' && !process.env.DEBUG_TESTS) {
    console.log = jest.fn();
    console.error = jest.fn();
  }
});

afterAll(() => {
  // Restore console functions
  console.log = originalConsoleLog;
  console.error = originalConsoleError;
});

// Clean up after each test
afterEach(() => {
  jest.clearAllMocks();
});

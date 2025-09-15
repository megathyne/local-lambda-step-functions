exports.handler = async (event, context) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    // Extract input data
    const name = event.name || 'World';
    const message = event.message || 'Hello';
    
    // Process the input
    const response = {
        statusCode: 200,
        body: {
            greeting: `${message}, ${name}!`,
            timestamp: context.awsRequestId,
            step: 'hello-world',
            processed: true
        }
    };
    
    console.log('Returning response:', JSON.stringify(response, null, 2));
    return response;
};

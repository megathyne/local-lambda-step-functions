exports.handler = async (event, context) => {
    console.log('Received event:', JSON.stringify(event, null, 2));

    // Extract input data
    const name = event.name && event.name.trim() !== '' ? event.name : 'World';
    const message = event.message && event.message.trim() !== '' ? event.message : 'Hello';

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

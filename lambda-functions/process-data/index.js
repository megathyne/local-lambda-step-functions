exports.handler = async (event, context) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    // Extract data from previous step
    const greeting = event.body?.greeting || '';
    const timestamp = event.body?.timestamp || '';
    
    // Simulate some processing time
    const processingTime = Math.random() * 1.5 + 0.5;
    await new Promise(resolve => setTimeout(resolve, processingTime * 1000));
    
    // Process the data
    const processedData = {
        original_greeting: greeting,
        processed_at: timestamp,
        processing_time: Math.round(processingTime * 100) / 100,
        word_count: greeting.split(' ').length,
        character_count: greeting.length,
        step: 'process-data',
        status: 'completed'
    };
    
    const response = {
        statusCode: 200,
        body: processedData
    };
    
    console.log('Returning response:', JSON.stringify(response, null, 2));
    return response;
};

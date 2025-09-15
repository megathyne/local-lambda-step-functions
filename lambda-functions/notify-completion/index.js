exports.handler = async (event, context) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    // Extract processed data
    const processedData = event.body || {};
    
    // Create completion summary
    const summary = {
        workflow_status: 'completed',
        final_step: 'notify-completion',
        summary: {
            original_greeting: processedData.original_greeting || '',
            processing_time: processedData.processing_time || 0,
            word_count: processedData.word_count || 0,
            character_count: processedData.character_count || 0,
            total_steps: 3,
            completion_message: 'Workflow completed successfully!'
        },
        timestamp: context.awsRequestId
    };
    
    const response = {
        statusCode: 200,
        body: summary
    };
    
    console.log('Workflow completed! Summary:', JSON.stringify(summary, null, 2));
    return response;
};

const { app } = require('@azure/functions');
const getReviewSummary = require("../common/azurelogic");

app.http('reviewsummary', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        context.log(`Http function processed request for url "${request.url}"`);
        const summary = await getReviewSummary();

        return { body: JSON.stringify(summary)  };
    }
});

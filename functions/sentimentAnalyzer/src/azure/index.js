const { app } = require('@azure/functions');
const getReviewAnalysis = require("./azurelogic");

app.http('sentimentanalysis', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        context.log(`Http function processed request for url "${request.url}"`);
        const sentAnalysis = await getReviewAnalysis();

        return { body: JSON.stringify(sentAnalysis)  };
    }
});


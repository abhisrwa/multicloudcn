const { QueueServiceClient } = require("@azure/storage-queue");
const config = require("../config");

async function sendMessageToQueue(message) {
    let response;
    console.log('HTTP trigger function processed a request.');

    const queueName = config.azqueue.queuename; // Replace with your queue name
    const connectionString = config.azqueue.queueurl; // Get connection string from environment

    if (!connectionString) {
        response = {
            status: 500,
            body: "Azure Storage connection string is missing. Ensure the 'AzureWebJobsStorage' application setting is configured."
        };
        return;
    }

    try {
        const queueServiceClient = QueueServiceClient.fromConnectionString(connectionString);
        const queueClient = queueServiceClient.getQueueClient(queueName);
        if (message) {
            const enqueueResult = await queueClient.sendMessage(message);
            console.log(`Enqueued message ID: ${enqueueResult.messageId}`);

            response = {
                status: 200,
                body: `Message "${message}" enqueued successfully with ID: ${enqueueResult.messageId}`
            };
        } else {
            response = {
                status: 400,
                body: "Please pass a 'message' in the request body or query string."
            };
        }
    } catch (error) {
        console.log("Error sending message to queue:", error);
        response = {
            status: 500,
            body: `Error sending message to queue: ${error.message}`
        };
    }
};

module.exports = {
    sendMessageToQueue
};

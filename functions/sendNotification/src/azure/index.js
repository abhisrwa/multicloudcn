const { app } = require('@azure/functions');
const { sendmail } = require('../notifications/sendmail');
const config = require('../config');

app.storageQueue('sendmail', {
    queueName: config.azqueue.queuename,
    connection: config.azqueue.queueurl,
    handler: async (queueItem, context) => {
        context.log('Storage queue function processed work item:', queueItem);
        const notification = await sendmail();

        return { body: JSON.stringify(notification)  };
    }
});

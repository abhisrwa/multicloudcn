// Import the SQS client and SendMessageCommand
const { SQSClient, SendMessageCommand } = require('@aws-sdk/client-sqs');
const config = require('../config');

// Set the AWS region
const region = config.awsregion;

// Create an SQS client
const sqsClient = new SQSClient({ region });

// Replace with your SQS queue URL
const queueURL = config.sqsURL;

async function sendMessageToSQS(messageBody) {
  const params = {
    DelaySeconds: 0, // Optional: The number of seconds to delay the delivery of the message (0-900). Default is 0.
    MessageBody: messageBody,
    QueueUrl: queueURL,
    MessageGroupId: 'SENTIMENT_ANALYSIS'
  };

  try {
    const command = new SendMessageCommand(params);
    const data = await sqsClient.send(command);
    console.log('Success, message ID:', data.MessageId);
    return data.MessageId;
  } catch (err) {
    console.error('Error sending message:', err);
  }
}

module.exports = {
    sendMessageToSQS
}
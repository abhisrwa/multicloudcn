const reviews = require("../adapter/itunes");
const ddb = require("../das/ddbv3")
const config = require("../config")
const utils = require("../utils")
const sqs = require("../notifications/sqs")

async function getReviewAnalysis() {
    const appId = config.appId;
    const table = config.ddb.reviewtable;
    const appReviews = await reviews.getAppReviews();
    console.log("App reviews retrieved", appReviews);
    for (const item of appReviews) {
    try {
        const ts = item.updated.label;
        const newItem = {
            "PK": { S : "APP#" + appId },
            "SK": { S: "CR#" + utils.stringToTimeString(ts) },
            "id": { S:item.id.label },
            "title": { S : item.title.label },
            "content": { S : item.content.label },
            "updated": { S : item.updated.label }
        };
        console.log(newItem);
        await ddb.createItem(newItem, table);
    } catch (error) {
        console.error('Error processing item:', error);
    }
  }
  console.log('All items processed.');
  const items = await ddb.queryDynamoDBByPartitionKey({ S : "APP#" + appId }, table);
  const sentAnalysis = await reviews.getSentimentAnalysis(items);
  // Save in summary table
  await saveSummary(sentAnalysis);
  

// Example usage:
const message = {
    orderId: '98765',
    customerId: '43210',
    items: ['productA', 'productB', 'productC'],
    total: 75.50
  };
  
  sqs.sendMessageToSQS(JSON.stringify(message));
  return sentAnalysis;
};

async function saveSummary(summary) {
    const appId = config.appId;
    const table = config.ddb.summarytable;
    try {
    const newItem = {
            "PK": { S : "APP#" + appId },
            "SK": { S: "SUMM#" + new Date().getTime() },
            "summary": { S : summary },
            "updated": { S : new Date() }
        };
        console.log(newItem);
        await ddb.createItem(newItem, table);
    } catch (error) {
        console.error('Error processing item:', error);
    }
};

module.exports = getReviewAnalysis;
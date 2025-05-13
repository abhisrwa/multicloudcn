const ddb = require("../das/ddbv3");
const config = require("../config");

async function getSummary() {
    const appId = config.appId;
    const table = config.ddb.summarytable;
    try {
        const items = await ddb.queryDynamoDBByPartitionKey({ S : "APP#" + appId }, table);
        return items ? items[0].summary : {};
    } catch (error) {
        console.error('Error processing item:', error);
    }
};

module.exports = getSummary;
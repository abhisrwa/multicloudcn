const ddb = require("../das/ddbv3");
const config = require("../config");

async function getSummary() {
    const appId = config.appId;
    const table = config.ddb.summarytable;
    try {
        const items = await ddb.queryDynamoDBByPartitionKey({ S : "APP#" + appId }, table);
        console.log(items[0]);
        return items[0];
    } catch (error) {
        console.error('Error processing item:', error);
    }
};

module.exports = getSummary;
const reviews = require('../adapter/itunes');
const config = require('../config');
const cosmosdas = require('../das/cosmosdb');
const { sendMessageToQueue } = require('../notifications/storagequeue');

async function getReviewAnalysis() {
    const { container } = await cosmosdas.getDatabaseAndContainer(config.cosmosdb.containerId);
        console.log("Container retrieved");
        const appReviews = await reviews.getAppReviews();
        console.log("App reviews retrieved");
        for (const item of appReviews) {
            try {
                const newItem = {
                    id: item.id.label,
                    title: item.title.label,
                    content: item.content.label,
                    updated: item.updated.label,
                };
                const readResult = await cosmosdas.readItem(container, newItem.id, newItem.id);
                if (!readResult) {
                    await cosmosdas.createItem(container, newItem);
                }
            } catch (error) {
                console.error('Error processing item:', error);
            }
          }
        console.log('All items processed.');
        const items = await cosmosdas.listItems(container);
        await sendMessageToQueue('Hello');
        const sentAnalysis = await reviews.getSentimentAnalysis(items);
        console.log('summary retrieved', sentAnalysis);
        // Save in summary table
        await saveSummary(sentAnalysis);
        console.log('Summary saved.');
        return sentAnalysis;
}


async function saveSummary(summary) {
    const { container } = await cosmosdas.getDatabaseAndContainer(config.cosmosdb.summcontainerId);
    console.log("Container retrieved");
    try {
        const newItem = {
            id: config.appId,
            summary,
            updated: new Date().getTime()
        };
        await cosmosdas.createItem(container, newItem);
    } catch (error) {
        console.error('Error processing item:', error);
    }
}

module.exports = getReviewAnalysis;
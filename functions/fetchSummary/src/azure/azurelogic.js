const config = require('../config');
const cosmosdas = require('../das/cosmosdb');

async function getSummary() {
    const { container } = await cosmosdas.getDatabaseAndContainer(config.cosmosdb.summcontainerId);
    console.log("Container retrieved");
    let summary;
    try {
        summary  = await cosmosdas.getLatestItem(container);
    } catch (error) {
        console.error('Error processing item:', error);
    }
    return summary;
}

module.exports = getSummary;
module.exports = {
    appId : process.env.APPID || '389801252',
    cosmosdb : {
        endpoint : process.env.DB_ENDPOINT,
        key : process.env.DB_KEY,
        databaseId : process.env.DB_ID || 'cosmicworks',
        containerId : process.env.DB_CONTAINERID || 'customerreviews',
        summcontainerId : process.env.DB_SUMMCONTAINERID || 'reviewsummary'
    },
    awsregion : process.env.REGION || 'us-east-1',
    sqsURL : process.env.SQSURL,
    ddb : {
        reviewtable: process.env.DB_REVIEW_TABLE || 'customerreviews',
        summarytable: process.env.DB_SUMM_TABLE || 'reviewsummary'
    },
    azqueue : {
        queuename : 'js-queue-items',
        queueurl : ''
    }
}
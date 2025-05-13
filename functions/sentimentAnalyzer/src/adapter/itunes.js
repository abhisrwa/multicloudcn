const axios = require('axios');
const Sentiment = require('sentiment');
const summarizer = require('./summarize');
const config = require('../config');


const sentiment = new Sentiment();

async function getAppReviews() {
    try {
        const response = await axios.get('https://itunes.apple.com/us/rss/customerreviews/id=' + config.appId + '/json');
        console.log('Received app reviews');
        const feeds = response.data.feed.entry;
        return feeds;
    } catch (error) {
        console.log(error);
    }
}

async function getSentimentAnalysis(feeds) {
    let summary;
    try {
        let comment = '';
        feeds.forEach(element => {
            comment += ". " + element.content;
        });
        console.log('trying to get summaries', comment);
        summary = await summarizer.getReviewSummary(comment);
        console.log('summary received', summary);
    } catch (error) {
        console.log(error);
    }    
    return summary;
}

module.exports = {
    getAppReviews,
    getSentimentAnalysis
};
const SummarizerManager = require("node-summarizer").SummarizerManager;

async function getReviewSummary(customerReviews) {
  try {
  let Summarizer = new SummarizerManager(customerReviews,2);
  let summary = await Summarizer.getSummaryByRank();
  console.log('Summary retrieved', summary);
  return summary ? summary.summary : '';
  } catch(error) {
    console.log(error);
  }

}

module.exports = {
  getReviewSummary
};

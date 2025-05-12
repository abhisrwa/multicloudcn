const getReviewAnalysis = require("./src/aws/awslogic");

// Lambda function handler
exports.handler = async (event) => {
  console.log(event);
  const sentAnalysis = await getReviewAnalysis();
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*', // Adjust CORS as needed
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
    },
    body: JSON.stringify(sentAnalysis),
  };
};
  
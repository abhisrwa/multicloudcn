#!/bin/bash
set -e

BUCKET_NAME="mcloudcodebucket"
FUNCTIONS=("sentimentAnalyzer" "fetchSummary" "sendNotification")

for func in "${FUNCTIONS[@]}"; do
  cd ../../functions/$func ##
  npm install --omit=dev
  zip -r ../../terraform/azure/$func.zip . -x "*.test.js"
  aws s3 cp ../../terraform/azure/$func.zip s3://$BUCKET_NAME/$func.zip
  cd - >/dev/null 
<<<<<<< HEAD
done ## End
=======
done ## End
>>>>>>> 6cd4a82211fbb8b0aeb435148734a71d270b0adc

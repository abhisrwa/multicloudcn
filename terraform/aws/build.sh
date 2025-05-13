#!/bin/bash
set -e

BUCKET_NAME="mcloud-code-bucket"
FUNCTIONS=("sentimentAnalyzer" "fetchSummary" "sendNotification")

for func in "${FUNCTIONS[@]}"; do
  cd ../../functions/$func
  npm install --omit=dev
  zip -r ../../aws/$func.zip . -x "*.test.js"
  aws s3 cp ../../aws/$func.zip s3://$BUCKET_NAME/$func.zip
  cd - >/dev/null ##
done

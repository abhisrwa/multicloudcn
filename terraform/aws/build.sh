#!/bin/bash
set -e

BUCKET_NAME="mcloud-code-bucket"
FUNCTIONS=("sentimentAnalyzer" "fetchSummary" "sendNotification")

for func in "${FUNCTIONS[@]}"; do
<<<<<<< HEAD
  cd ../../functions/$func ##
  npm install --omit=dev
  zip -r ../../terraform/aws/$func.zip . -x "*.test.js"
  aws s3 cp ../../terraform//aws/$func.zip s3://$BUCKET_NAME/$func.zip
  cd - >/dev/null 
done
=======
  cd ../../functions/$func
  npm install --omit=dev
  zip -r ../../terraform/aws/$func.zip . -x "*.test.js"
  aws s3 cp ../../terraform//aws/$func.zip s3://$BUCKET_NAME/$func.zip
  cd - >/dev/null ##
done
>>>>>>> d5a25626b91066fa213438c319ca0685981cb06d

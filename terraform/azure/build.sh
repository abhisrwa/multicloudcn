#!/bin/bash
set -e

RESOURCE_GROUP="DefaultResourceGroup-CCAN"
FUNC_PREFIX="az"
FUNCTIONS=("sentimentAnalyzer" "fetchSummary" "sendNotification")

for func in "${FUNCTIONS[@]}"; do
  cd ../functions/$func
  npm install --omit=dev
  zip -r ../../azure/$func.zip . -x "*.test.js"
  az functionapp deployment source config-zip \
    --name "$FUNC_PREFIX-$func" \
    --resource-group "$RESOURCE_GROUP" \
    --src ../../azure/$func.zip
  cd - >/dev/null
done

const { DynamoDBClient,
  PutItemCommand,
  GetItemCommand,
  UpdateItemCommand,
  DeleteItemCommand,
  QueryCommand } = require("@aws-sdk/client-dynamodb");
const { marshall, unmarshall } = require("@aws-sdk/util-dynamodb");  // Important for v3!
const config = require("../config")

// Configure AWS SDK v3
const client = new DynamoDBClient({
  region: config.awsregion
});

// Helper function to handle errors
const handleError = (err) => {
  console.error("Error:", err);
  throw err;
};

// Create (Put) a new item
async function createItem(item, tableName) {
  const params = {
    TableName: tableName,
    Item: item
  };

  try {
    const command = new PutItemCommand(params);
    const result = await client.send(command);
    console.log("Item Created:", result);
    return result;
  } catch (error) {
    return handleError(error);
  }
}

// Read (Get) an item
async function getItem(key, tableName) {
  const params = {
    TableName: tableName,
    Key: marshall(key), //  Marshall the key!
  };

  try {
    const command = new GetItemCommand(params);
    const result = await client.send(command);

    if (result.Item) {
      const unmarshalledItem = unmarshall(result.Item); // Unmarshall the result
      console.log("Item Retrieved:", unmarshalledItem);
      return unmarshalledItem;
    } else {
      console.log("Item not found.");
      return null;
    }
  } catch (error) {
    return handleError(error);
  }
}

// Update an item
async function updateItem(key, updateExpression, expressionAttributeValues, returnValues = "ALL_NEW", tableName) {
  const params = {
    TableName: tableName,
    Key: marshall(key),
    UpdateExpression: updateExpression,
    ExpressionAttributeValues: marshall(expressionAttributeValues), //  Marshall the values!
    ReturnValues: returnValues //  "NONE", "ALL_OLD", "ALL_NEW", "UPDATED_OLD", "UPDATED_NEW"
  };

  try {
    const command = new UpdateItemCommand(params);
    const result = await client.send(command);
    console.log("Item Updated:", result);
    const updatedItem = result.Attributes ? unmarshall(result.Attributes) : null;
    return updatedItem;

  } catch (error) {
    return handleError(error);
  }
}

// Delete an item
async function deleteItem(key) {
  const params = {
    TableName: tableName,
    Key: marshall(key),
  };

  try {
    const command = new DeleteItemCommand(params);
    const result = await client.send(command);
    console.log("Item Deleted:", result);
    return result;
  } catch (error) {
    return handleError(error);
  }
}

async function queryDynamoDBByPartitionKey(partitionKeyValue, tableName) {
  const params = {
      TableName: tableName,
      KeyConditionExpression: '#PK = :pk_value',
      ExpressionAttributeNames: {
          '#PK': "PK"
      },
      ExpressionAttributeValues: {
          ':pk_value': partitionKeyValue
      }
  };

  try {
      const command = new QueryCommand(params);
      const result = await client.send(command);
      console.log("Query succeeded.");
      console.log("Retrieved items:", result.Items);
      return result.Items ? result.Items.map(item => unmarshall(item)) : []; // Unmarshall
  } catch (err) {
      console.error("Unable to query. Error JSON:", JSON.stringify(err, null, 2));
      return null;
  }
}

module.exports = {
  createItem,
  getItem,
  updateItem,
  deleteItem,
  queryDynamoDBByPartitionKey
};
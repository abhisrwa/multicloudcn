const { CosmosClient } = require("@azure/cosmos");
const config = require("../config")

const endpoint = config.cosmosdb.endpoint;
const key = config.cosmosdb.key;
const databaseId = config.cosmosdb.databaseId;

// Create a Cosmos DB client
const client = new CosmosClient({ endpoint, key });

/**
 * Gets or creates the database and container.
 * @returns {Promise<{ database: Database, container: Container }>}
 */
async function getDatabaseAndContainer(containerId) {
    const { database } = await client.databases.createIfNotExists({
        id: databaseId,
    });
    const { container } = await database.containers.createIfNotExists({
        id: containerId,
        partitionKey: { path: "/id" }, //  Partition key is IMPORTANT for scalability
    });
    return { database, container };
}

// CRUD Operations

/**
 * Creates an item in the container.
 * @param {Container} container
 * @param {object} item - The item to create.  Must include an 'id' property.
 * @returns {Promise<void>}
 */
async function createItem(container, item) {
    try {
        const { resource } = await container.items.create(item);
    } catch (error) {
        console.error("Error creating item:", error);
    }
}

/**
 * Reads an item from the container by its id.
 * @param {Container} container
 * @param {string} id - The id of the item to read.
 * @param {string} partitionKey -  The partition key value for the item.
 * @returns {Promise<object | null>} - The item, or null if not found.
 */
async function readItem(container, id, partitionKey) {
    try {
        const { resource } = await container.item(id, partitionKey).read();
        return resource;
    } catch (error) {
        if (error.code === 404) {
            console.log(`Item with id ${id} not found.`);
            return null;
        } else {
            console.error("Error reading item:", error);
            throw error; // Re-throw the error to be handled by the caller
        }
    }
}

/**
 * Updates an item in the container.
 * @param {Container} container
 * @param {object} item - The updated item.  Must include the 'id' of the item to update.
 * @returns {Promise<void>}
 */
async function updateItem(container, item) {
    try {
        const { resource } = await container.item(item.id, item.id).replace(item); // Partition key must be included in the item
        console.log("Item updated:", resource);
    } catch (error) {
        console.error("Error updating item:", error);
    }
}

/**
 * Deletes an item from the container by its id.
 * @param {Container} container
 * @param {string} id - The id of the item to delete.
 * @param {string} partitionKey -  The partition key value for the item.
 * @returns {Promise<void>}
 */
async function deleteItem(container, id, partitionKey) {
    try {
        const { statusCode } = await container.item(id, partitionKey).delete();
        console.log("Item deleted. Status code:", statusCode);
    } catch (error) {
        console.error("Error deleting item:", error);
    }
}

/**
 * Lists all items in the container.  Use this cautiously in production with large datasets.
 * @param {Container} container
 * @returns {Promise<any[]>}
 */
async function listItems(container) {
    try {
        const { resources } = await container.items.readAll().fetchAll();
        return resources;
    } catch (error) {
        console.error("Error listing items:", error);
        throw error; //  Important: Re-throw the error so the caller knows.
    }
}

module.exports = {
    getDatabaseAndContainer,
    createItem,
    readItem,
    listItems
};

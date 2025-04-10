/**
 * Redis Client Utility
 * Handles connections and operations for exam data in Redis
 */

const { createClient } = require('redis');
const logger = require('./logger');

// Redis key prefixes for different data types
const KEYS = {
  EXAM_INFO: 'exam:info:',     // For storing JSON exam information
  EXAM_STATUS: 'exam:status:', // For storing exam status string
  CURRENT_EXAM_ID: 'current-exam-id', // For storing current exam ID (single key)
  EXAM_RESULT: 'exam:result:', // For storing exam evaluation results
};

// Create Redis client using environment variables
const redisClient = createClient({
  url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`
});

// Handle Redis connection events
redisClient.on('connect', () => {
  logger.info('Redis client connected');
});

redisClient.on('error', (err) => {
  logger.error(`Redis client error: ${err}`);
});

// Initialize connection
async function connect() {
  if (!redisClient.isOpen) {
    try {
      await redisClient.connect();
    } catch (error) {
      logger.error(`Failed to connect to Redis: ${error.message}`);
      throw error;
    }
  }
  return redisClient;
}

/**
 * Ensure the Redis client is connected before performing operations
 */
async function getClient() {
  return redisClient.isOpen ? redisClient : await connect();
}

/**
 * Persist exam information (JSON)
 * @param {string} examId - Exam identifier
 * @param {Object} examInfo - JSON object containing exam information
 * @param {number} [ttl=3600] - Time to live in seconds (default: 1 hour)
 * @returns {Promise<string>} - Returns 'OK' if successful
 */
async function persistExamInfo(examId, examInfo, ttl = 36000) {
  try {
    const client = await getClient();
    const key = `${KEYS.EXAM_INFO}${examId}`;
    const result = await client.setEx(key, ttl, JSON.stringify(examInfo));
    
    logger.debug(`Persisted exam info for exam ${examId}`);
    return result;
  } catch (error) {
    logger.error(`Failed to persist exam info: ${error.message}`);
    throw error;
  }
}

/**
 * Persist exam status (string)
 * @param {string} examId - Exam identifier
 * @param {string} status - Exam status string
 * @param {number} [ttl=3600] - Time to live in seconds (default: 1 hour)
 * @returns {Promise<string>} - Returns 'OK' if successful
 */
async function persistExamStatus(examId, status, ttl = 36000) {
  try {
    const client = await getClient();
    const key = `${KEYS.EXAM_STATUS}${examId}`;
    const result = await client.setEx(key, ttl, status);
    logger.debug(`Persisted exam status for exam ${examId}: ${status}`);
    return result;
  } catch (error) {
    logger.error(`Failed to persist exam status: ${error.message}`);
    throw error;
  }
}

/**
 * Persist exam evaluation result
 * @param {string} examId - Exam identifier
 * @param {Object} result - Exam evaluation result object
 * @param {number} [ttl=3600] - Time to live in seconds (default: 1 hour)
 * @returns {Promise<string>} - Returns 'OK' if successful
 */
async function persistExamResult(examId, result, ttl = 36000) {
  try {
    const client = await getClient();
    const key = `${KEYS.EXAM_RESULT}${examId}`;
    const resultStr = JSON.stringify(result);
    const resultSet = await client.setEx(key, ttl, resultStr);
    
    logger.debug(`Persisted exam result for exam ${examId}`);
    return resultSet;
  } catch (error) {
    logger.error(`Failed to persist exam result: ${error.message}`);
    throw error;
  }
}

/**
 * Set the current exam ID
 * @param {string} examId - Exam identifier
 * @param {number} [ttl=3600] - Time to live in seconds (default: 1 hour)
 * @returns {Promise<string>} - Returns 'OK' if successful
 */
async function setCurrentExamId(examId, ttl = 36000) {
  try {
    const client = await getClient();
    const result = await client.setEx(KEYS.CURRENT_EXAM_ID, ttl, examId);
    logger.debug(`Set current exam ID to ${examId}`);
    return result;
  } catch (error) {
    logger.error(`Failed to set current exam ID: ${error.message}`);
    throw error;
  }
}

/**
 * Get exam information
 * @param {string} examId - Exam identifier
 * @returns {Promise<Object|null>} - Returns parsed JSON object or null if not found
 */
async function getExamInfo(examId) {
  try {
    const client = await getClient();
    const key = `${KEYS.EXAM_INFO}${examId}`;
    const data = await client.get(key);
    return data ? JSON.parse(data) : null;
  } catch (error) {
    logger.error(`Failed to get exam info: ${error.message}`);
    throw error;
  }
}

/**
 * Get exam status
 * @param {string} examId - Exam identifier
 * @returns {Promise<string|null>} - Returns status string or null if not found
 */
async function getExamStatus(examId) {
  try {
    const client = await getClient();
    const key = `${KEYS.EXAM_STATUS}${examId}`;
    return await client.get(key);
  } catch (error) {
    logger.error(`Failed to get exam status: ${error.message}`);
    throw error;
  }
}

/**
 * Get exam evaluation result
 * @param {string} examId - Exam identifier
 * @returns {Promise<Object|null>} - Returns parsed result object or null if not found
 */
async function getExamResult(examId) {
  try {
    const client = await getClient();
    const key = `${KEYS.EXAM_RESULT}${examId}`;
    const data = await client.get(key);
    return data ? JSON.parse(data) : null;
  } catch (error) {
    logger.error(`Failed to get exam result: ${error.message}`);
    throw error;
  }
}

/**
 * Get the current exam ID
 * @returns {Promise<string|null>} - Returns exam ID string or null if not found
 */
async function getCurrentExamId() {
  try {
    const client = await getClient();
    return await client.get(KEYS.CURRENT_EXAM_ID);
  } catch (error) {
    logger.error(`Failed to get current exam ID: ${error.message}`);
    throw error;
  }
}

/**
 * Update exam information
 * @param {string} examId - Exam identifier
 * @param {Object} examInfo - Updated exam information
 * @param {number} [ttl=3600] - Time to live in seconds (default: 1 hour)
 * @returns {Promise<string>} - Returns 'OK' if successful
 */
async function updateExamInfo(examId, examInfo) {
  return persistExamInfo(examId, examInfo);
}

/**
 * Update exam status
 * @param {string} examId - Exam identifier
 * @param {string} status - Updated exam status
 * @param {number} [ttl=3600] - Time to live in seconds (default: 1 hour)
 * @returns {Promise<string>} - Returns 'OK' if successful
 */
async function updateExamStatus(examId, status) {
  return persistExamStatus(examId, status);
}

/**
 * Update the current exam ID
 * @param {string} examId - Updated exam identifier
 * @param {number} [ttl=3600] - Time to live in seconds (default: 1 hour)
 * @returns {Promise<string>} - Returns 'OK' if successful
 */
async function updateCurrentExamId(examId) {
  return setCurrentExamId(examId);
}

/**
 * Delete exam information
 * @param {string} examId - Exam identifier
 * @returns {Promise<number>} - Returns 1 if successful, 0 if key didn't exist
 */
async function deleteExamInfo(examId) {
  try {
    const client = await getClient();
    const key = `${KEYS.EXAM_INFO}${examId}`;
    const result = await client.del(key);
    logger.debug(`Deleted exam info for exam ${examId}`);
    return result;
  } catch (error) {
    logger.error(`Failed to delete exam info: ${error.message}`);
    throw error;
  }
}

/**
 * Delete exam status
 * @param {string} examId - Exam identifier
 * @returns {Promise<number>} - Returns 1 if successful, 0 if key didn't exist
 */
async function deleteExamStatus(examId) {
  try {
    const client = await getClient();
    const key = `${KEYS.EXAM_STATUS}${examId}`;
    const result = await client.del(key);
    logger.debug(`Deleted exam status for exam ${examId}`);
    return result;
  } catch (error) {
    logger.error(`Failed to delete exam status: ${error.message}`);
    throw error;
  }
}

/**
 * Delete exam evaluation result
 * @param {string} examId - Exam identifier
 * @returns {Promise<number>} - Returns 1 if successful, 0 if key didn't exist
 */
async function deleteExamResult(examId) {
  try {
    const client = await getClient();
    const key = `${KEYS.EXAM_RESULT}${examId}`;
    const result = await client.del(key);
    logger.debug(`Deleted exam result for exam ${examId}`);
    return result;
  } catch (error) {
    logger.error(`Failed to delete exam result: ${error.message}`);
    throw error;
  }
}

/**
 * Delete the current exam ID
 * @returns {Promise<number>} - Returns 1 if successful, 0 if key didn't exist
 */
async function deleteCurrentExamId() {
  try {
    const client = await getClient();
    const result = await client.del(KEYS.CURRENT_EXAM_ID);
    logger.debug(`Deleted current exam ID`);
    return result;
  } catch (error) {
    logger.error(`Failed to delete current exam ID: ${error.message}`);
    throw error;
  }
}

/**
 * Delete all exam data
 * @param {string} examId - Exam identifier
 * @returns {Promise<number>} - Returns the number of keys deleted
 */
async function deleteAllExamData(examId) {
  try {
    const client = await getClient();
    
    // Delete all related keys
    const keys = [
      `${KEYS.EXAM_INFO}${examId}`,
      `${KEYS.EXAM_STATUS}${examId}`,
      `${KEYS.EXAM_RESULT}${examId}`
    ];
    const result = await client.del(keys);
    logger.debug(`Deleted all data for exam ${examId}`);
    return result;
  } catch (error) {
    logger.error(`Failed to delete all exam data: ${error.message}`);
    throw error;
  }
}

module.exports = {
  // Connection
  connect,
  getClient,
  
  // Create operations
  persistExamInfo,
  persistExamStatus,
  persistExamResult,
  setCurrentExamId,
  
  // Read operations
  getExamInfo,
  getExamStatus,
  getExamResult,
  getCurrentExamId,
  
  // Update operations
  updateExamInfo,
  updateExamStatus,
  updateCurrentExamId,
  
  // Delete operations
  deleteExamInfo,
  deleteExamStatus,
  deleteExamResult,
  deleteCurrentExamId,
  deleteAllExamData,
  
  // Constants
  KEYS
}; 
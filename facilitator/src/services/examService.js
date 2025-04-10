/**
 * Exam Service
 * Handles all business logic for exam operations
 */

const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');
const redisClient = require('../utils/redisClient');
const config = require('../config');
const jumphostService = require('./jumphostService');
const sshService = require('./sshService');
const MetricService = require('./metricService');

/**
 * Create a new exam
 * @param {Object} examData - The exam data
 * @returns {Promise<Object>} Result object with success status and data
 */
async function createExam(examData) {
  try {
    // Check if there's already an active exam
    const currentExamId = await redisClient.getCurrentExamId();
    
    // If currentExamId exists, don't allow creating a new exam
    if (currentExamId) {
      logger.warn(`Attempted to create a new exam while exam ${currentExamId} is still active`);
      return {
        success: false,
        error: 'Exam already exists',
        message: 'Only one exam can be active at a time. End the current exam before creating a new one.',
        currentExamId
      };
    }
    
    const examId = uuidv4();
    
    // fetch exam config from the asset path and append it to the examData
    const examConfig = fs.readFileSync(path.join(process.cwd(),  examData.assetPath, 'config.json'), 'utf8');
    examData.config = JSON.parse(examConfig); 
    delete examData.answers;

    //persist created at time
    examData.createdAt = new Date().toISOString();
    // Store exam information in Redis
    await redisClient.persistExamInfo(examId, examData);
    
    // Set initial exam status
    await redisClient.persistExamStatus(examId, 'CREATED');
    
    // Set as current exam ID
    await redisClient.setCurrentExamId(examId);
    
    logger.info(`Exam created successfully with ID: ${examId}`);
    
    // Determine number of nodes required for the exam (default to 1 if not specified)
    const nodeCount = examData.nodeCount || 1;
    
    // Set up the exam environment asynchronously
    // This will happen in the background while the response is sent back to the client
    setupExamEnvironmentAsync(examId, nodeCount);
    
    // send metrics to metric server
    MetricService.sendMetrics(examId, {
      category: examData.category,
      labId: examData.config.lab,
      examName: examData.name,
    });

    return {
      success: true,
      data: {
        id: examId,
        status: 'CREATED',
        message: 'Exam created successfully and environment preparation started'
      }
    };
  } catch (error) {
    logger.error('Error creating exam', { error: error.message });
    return {
      success: false,
      error: 'Failed to create exam',
      message: error.message
    };
  }
}

/**
 * Set up the exam environment asynchronously
 * This function runs in the background and doesn't block the response
 * 
 * @param {string} examId - The exam ID
 * @param {number} nodeCount - Number of nodes to prepare
 */
async function setupExamEnvironmentAsync(examId, nodeCount) {
  try {
    // Call the jumphost service to set up the exam environment
    const result = await jumphostService.setupExamEnvironment(examId, nodeCount);     
    
    if (!result.success) {
      logger.error(`Failed to set up exam environment for exam ${examId}`, {
        error: result.error,
        details: result.details
      });
      // The jumphostService already updates the exam status on failure
      return;
    }
    
    logger.info(`Exam environment set up successfully for exam ${examId}`);
    // The jumphostService already updates the exam status on success
  } catch (error) {
    logger.error(`Unexpected error setting up exam environment for exam ${examId}`, {
      error: error.message
    });
    
    // Update exam status to PREPARATION_FAILED if not already done
    try {
      const currentStatus = await redisClient.getExamStatus(examId);
      if (currentStatus !== 'PREPARATION_FAILED') {
        await redisClient.persistExamStatus(examId, 'PREPARATION_FAILED');
      }
    } catch (statusError) {
      logger.error(`Failed to update exam status for exam ${examId}`, {
        error: statusError.message
      });
    }
  }
}

/**
 * Get the current active exam
 * @returns {Promise<Object>} Result object with success status and data
 */
async function getCurrentExam() {
  try {
    // Get the current exam ID
    const examId = await redisClient.getCurrentExamId();
    
    // based on the path include 
    if (!examId) {
      logger.info('No current exam is set');
      return {
        success: false,
        error: 'Not Found',
        message: 'No current exam is active'
      };
    }
    
    // Get exam information and status
    const examInfo = await redisClient.getExamInfo(examId);
    const examStatus = await redisClient.getExamStatus(examId);
    
    return {
      success: true,
      data: {
        id: examId,
        status: examStatus,
        info: examInfo
      }
    };
  } catch (error) {
    logger.error('Error retrieving current exam', { error: error.message });
    return {
      success: false,
      error: 'Failed to retrieve current exam',
      message: error.message
    };
  }
}

/**
 * Get exam assets
 * @param {string} examId - The exam ID
 * @returns {Promise<Object>} Result object with success status and data
 */
async function getExamAssets(examId) {
  try {
    // Check if exam exists in Redis
    const examInfo = await redisClient.getExamInfo(examId);
    
    if (!examInfo) {
      logger.error(`Exam not found with ID: ${examId}`);
      return {
        success: false,
        error: 'Not Found',
        message: 'Exam not found'
      };
    }
    
    // Placeholder implementation - will be implemented later
    return {
      success: true,
      data: {
        examId,
        assets: []
      }
    };
  } catch (error) {
    logger.error('Error retrieving exam assets', { error: error.message });
    return {
      success: false,
      error: 'Failed to retrieve exam assets',
      message: error.message
    };
  }
}

/**
 * Get exam questions
 * @param {string} examId - The exam ID
 * @returns {Promise<Object>} Result object with success status and data
 */
async function getExamQuestions(examId) {
  try {
    // Check if exam exists and get status
    const examStatus = await redisClient.getExamStatus(examId);
    const examInfo = await redisClient.getExamInfo(examId);
    
    if (!examStatus || !examInfo) {
      logger.error(`Exam not found with ID: ${examId}`);
      return {
        success: false,
        error: 'Not Found',
        message: 'Exam not found'
      };
    }
    
    // Get asset path from exam info
    const assetPath = examInfo.assetPath;
    if (!assetPath) {
      logger.error(`Asset path not found for exam: ${examId}`);
      return {
        success: false,
        error: 'Configuration Error',
        message: 'Exam asset path not defined'
      };
    }
    
    // Read the config.json file to find the questions.json path
    const configPath = path.join(process.cwd(), assetPath, 'config.json');
    
    if (!fs.existsSync(configPath)) {
      logger.error(`Config file not found at path: ${configPath}`);
      return {
        success: false,
        error: 'File Not Found',
        message: 'Exam configuration file not found'
      };
    }
    
    // Read and parse config.json
    const configData = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(configData);
    
    // Get the questions file path from config
    const questionsFilePath = config.questions || 'assessment.json';
    const fullQuestionsPath = path.join(process.cwd(), assetPath, questionsFilePath);
    
    if (!fs.existsSync(fullQuestionsPath)) {
      logger.error(`Questions file not found at path: ${fullQuestionsPath}`);
      return {
        success: false,
        error: 'File Not Found',
        message: 'Exam questions file not found'
      };
    }
    
    // Read and parse questions.json
    const questionsData = fs.readFileSync(fullQuestionsPath, 'utf8');
    const questions = JSON.parse(questionsData);
    
    logger.info(`Successfully retrieved questions for exam ${examId}`);
    
    return {
      success: true,
      data: {
        questions: questions.questions || []
      }
    };
  } catch (error) {
    logger.error('Error retrieving exam questions', { error: error.message });
    return {
      success: false,
      error: 'Failed to retrieve exam questions',
      message: error.message
    };
  }
}

/**
 * Evaluate an exam
 * @param {string} examId - The exam ID
 * @param {Object} evaluationData - The evaluation data
 * @returns {Promise<Object>} Result object with success status and data
 */
async function evaluateExam(examId, evaluationData) {
  try {
    // Update exam status to EVALUATING
    await redisClient.updateExamStatus(examId, 'EVALUATING');

    MetricService.sendMetrics(examId, {
      event: {
        examEvaluationState: 'EVALUATING'
      }
    });
    
    // Get exam data and question information
    const examInfo = await redisClient.getExamInfo(examId);
    if (!examInfo) {
      throw new Error(`Exam not found with ID: ${examId}`);
    }
    
    // Get exam questions data
    const questionsResponse = await getExamQuestions(examId);
    if (!questionsResponse.success) {
      throw new Error('Failed to get exam questions');
    }
    
    // Get assessment path information
    const assetPath = examInfo.assetPath;
    if (!assetPath) {
      throw new Error('Asset path not defined in exam info');
    }
    
    // Start evaluation asynchronously using Promise
    // This will happen in the background while the response is sent back to the client
    Promise.resolve().then(async () => {
      try {
        // Call the jumphost service to perform the evaluation
        await jumphostService.evaluateExamOnJumphost(examId, questionsResponse.data.questions);
      } catch (error) {
        logger.error(`Error in async exam evaluation for exam ${examId}`, { error: error.message });
        // Update exam status to EVALUATION_FAILED
        await redisClient.updateExamStatus(examId, 'EVALUATION_FAILED');
      }
    });
    
    return {
      success: true,
      data: {
        examId,
        status: 'EVALUATING',
        message: 'Exam evaluation started'
      }
    };
  } catch (error) {
    logger.error('Error starting exam evaluation', { error: error.message });
    return {
      success: false,
      error: 'Failed to start exam evaluation',
      message: error.message
    };
  }
}

/**
 * Get exam evaluation result
 * @param {string} examId - The exam ID
 * @returns {Promise<Object>} Result object with success status and data
 */
async function getExamResult(examId) {
  try {
    const result = await redisClient.getExamResult(examId);
    if (!result) {
      logger.warn(`No evaluation result found for exam ${examId}`);
      return {
        success: false,
        error: 'Not Found',
        message: 'Exam evaluation result not found'
      };
    }
    
    return {
      success: true,
      data: result
    };
  } catch (error) {
    logger.error('Error retrieving exam result', { error: error.message });
    return {
      success: false,
      error: 'Failed to retrieve exam result',
      message: error.message
    };
  }
}

/**
 * End an exam
 * @param {string} examId - The exam ID
 * @returns {Promise<Object>} Result object with success status and data
 */
async function endExam(examId) {
  try {
    // Get current exam ID to verify this is the active exam
    const currentExamId = await redisClient.getCurrentExamId();
    
    if (currentExamId !== examId) {
      logger.warn(`Attempted to end exam ${examId} but current exam is ${currentExamId || 'not set'}`);
    }

    // Clean up the exam environment
    try {
      await jumphostService.cleanupExamEnvironment(examId);
      
      // Clear the current exam info 
      await redisClient.deleteCurrentExamId();
      await redisClient.deleteAllExamData(examId);
    } catch (cleanupError) {
      logger.error(`Error cleaning up exam environment for exam ${examId}`, {
        error: cleanupError.message
      });
      // Continue with ending the exam even if cleanup fails
    }
    
    logger.info(`Exam ${examId} completed`);
    
    return {
      success: true,
      data: {
        examId,
        status: 'COMPLETED',
        message: 'Exam completed successfully'
      }
    };
  } catch (error) {
    logger.error('Error ending exam', { error: error.message });
    return {
      success: false,
      error: 'Failed to end exam',
      message: error.message
    };
  }
}

module.exports = {
  createExam,
  getCurrentExam,
  getExamAssets,
  getExamQuestions,
  evaluateExam,
  endExam,
  getExamResult
}; 
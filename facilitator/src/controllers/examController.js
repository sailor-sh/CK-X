const logger = require('../utils/logger');
const examService = require('../services/examService');
const fs = require('fs');
const path = require('path');
const redisClient = require('../utils/redisClient');
const MetricService = require('../services/metricService');

/**
 * Create a new exam
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function createExam(req, res) {
  logger.info('Received request to create a new exam', { examData: req.body });
  
  const result = await examService.createExam(req.body);
  
  if (!result.success) {
    // Handle the specific case of an exam already existing
    if (result.error === 'Exam already exists') {
      return res.status(409).json({ 
        error: result.error,
        message: result.message,
        currentExamId: result.currentExamId
      });
    }
    
    // Handle other errors
    return res.status(500).json({ 
      error: result.error,
      message: result.message
    });
  }
  
  return res.status(201).json(result.data);
}

/**
 * Get the current exam
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getCurrentExam(req, res) {
  logger.info('Received request to get current exam');
  
  const result = await examService.getCurrentExam();
  
  if (!result.success) {
    if (result.error === 'Not Found') {
      return res.status(404).json({ message: result.message });
    }
    return res.status(500).json({ 
      error: result.error,
      message: result.message
    });
  }
  
  return res.status(200).json(result.data);
}

/**
 * Get exam assets
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getExamAssets(req, res) {
  const examId = req.params.examId;
  
  logger.info('Received request to get exam assets', { examId });
  
  try {
    // Check if exam exists
    const examInfo = await redisClient.getExamInfo(examId);
    
    if (!examInfo) {
      logger.error(`Exam not found with ID: ${examId}`);
      return res.status(404).json({ 
        error: 'Not Found',
        message: 'Exam not found' 
      });
    }
    
    // Get asset path from exam info
    const assetPath = examInfo.assetPath;
    if (!assetPath) {
      logger.error(`Asset path not found for exam: ${examId}`);
      return res.status(500).json({ 
        error: 'Configuration Error',
        message: 'Exam asset path not defined'
      });
    }
    
    // Construct the path to the assets.zip file (actually a tar archive)
    const assetsZipPath = path.join(process.cwd(), assetPath, 'assets.tar.gz');
    
    if (!fs.existsSync(assetsZipPath)) {
      logger.error(`Assets file not found at path: ${assetsZipPath}`);
      return res.status(500).json({ 
        error: 'File Not Found',
        message: 'Exam assets file not found'
      });
    }
    
    logger.info(`Sending assets file for exam ${examId} from path ${assetsZipPath}`);
    
    // Set the content type for tar.gz file and send it
    res.setHeader('Content-Type', 'application/gzip');
    res.setHeader('Content-Disposition', `attachment; filename="assets-${examId}.tar.gz"`);
    return res.sendFile(assetsZipPath);
  } catch (error) {
    logger.error('Error retrieving exam assets', { error: error.message });
    return res.status(500).json({ 
      error: 'Failed to retrieve exam assets',
      message: error.message
    });
  }
}

/**
 * Get exam questions
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getExamQuestions(req, res) {
  const examId = req.params.examId;
  
  logger.info('Received request to get exam questions', { examId });
  
  const result = await examService.getExamQuestions(examId);
  
  if (!result.success) {
    if (result.error === 'Not Found') {
      return res.status(404).json({ error: 'Exam not found' });
    }
    return res.status(500).json({ 
      error: result.error,
      message: result.message
    });
  }
  
  return res.status(200).json(result.data);
}

/**
 * Evaluate an exam
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function evaluateExam(req, res) {
  const examId = req.params.examId;
  
  logger.info('Received request to evaluate exam', { examId, data: req.body });
  
  const result = await examService.evaluateExam(examId, req.body);
  
  if (!result.success) {
    return res.status(500).json({ 
      error: result.error,
      message: result.message
    });
  }
  
  return res.status(200).json(result.data);
}

/**
 * End an exam
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function endExam(req, res) {
  const examId = req.params.examId;
  
  logger.info('Received request to end exam', { examId });
  
  const result = await examService.endExam(examId);
  
  if (!result.success) {
    return res.status(500).json({ 
      error: result.error,
      message: result.message
    });
  }
  
  return res.status(200).json(result.data);
}

/**
 * Get exam answers
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getExamAnswers(req, res) {
  const examId = req.params.examId;
  
  logger.info('Received request to get exam answers', { examId });
  
  try {
    // Check if exam exists
    const examInfo = await redisClient.getExamInfo(examId);
    
    if (!examInfo) {
      logger.error(`Exam not found with ID: ${examId}`);
      return res.status(404).json({ 
        error: 'Not Found',
        message: 'Exam not found' 
      });
    }
    
    // Get answers path directly from the exam info config
    if (!examInfo.config || !examInfo.config.answers) {
      logger.error(`Answers path not found in config for exam: ${examId}`);
      return res.status(500).json({ 
        error: 'Configuration Error',
        message: 'Answers path not defined in exam configuration'
      });
    }
    
    const answersFilePath = examInfo.config.answers;
    const fullAnswersPath = path.join(process.cwd(), answersFilePath);
    
    if (!fs.existsSync(fullAnswersPath)) {
      logger.error(`Answers file not found at path: ${fullAnswersPath}`);
      return res.status(500).json({ 
        error: 'File Not Found',
        message: 'Exam answers file not found'
      });
    }
    
    logger.info(`Sending answers file for exam ${examId} from path ${fullAnswersPath}`);
    
    // Send the file directly instead of a JSON response
    return res.sendFile(fullAnswersPath);
  } catch (error) {
    logger.error('Error retrieving exam answers', { error: error.message });
    return res.status(500).json({ 
      error: 'Failed to retrieve exam answers',
      message: error.message
    });
  }
}

/**
 * Get exam status
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getExamStatus(req, res) {
  const examId = req.params.examId;
  
  logger.info('Received request to get exam status', { examId });
  
  try {
    // Check if exam exists
    const examInfo = await redisClient.getExamInfo(examId);
    //get exam status form redis
    const examStatus = await redisClient.getExamStatus(examId);
    
    if (!examInfo) {
      logger.error(`Exam not found with ID: ${examId}`);
      return res.status(404).json({ 
        error: 'Not Found',
        message: 'Exam not found' 
      });
    }

    // Return the exam status and any additional info
    return res.status(200).json({
      id: examId,
      status: examStatus || 'UNKNOWN',
      warmUpTimeInSeconds: examInfo.warmUpTimeInSeconds || 30,
      message: examStatus === 'READY' ? 'Exam environment is ready' : 'Exam environment is being prepared'
    });
  } catch (error) {
    logger.error('Error retrieving exam status', { error: error.message });
    return res.status(500).json({ 
      error: 'Failed to retrieve exam status',
      message: error.message
    });
  }
}

/**
 * Get exam result
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getExamResult(req, res) {
  const examId = req.params.examId;
  
  logger.info('Received request to get exam result', { examId });
  
  const result = await examService.getExamResult(examId);
  
  if (!result.success) {
    // Handle the case when result isn't found
    if (result.error === 'Not Found') {
      return res.status(404).json({
        error: result.error,
        message: result.message
      });
    }
    
    // Handle other errors
    return res.status(500).json({
      error: result.error,
      message: result.message
    });
  }
  
  return res.status(200).json(result);
}

/**
 * Update exam events
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function updateExamEvents(req, res) {
  const examId = req.params.examId;
  const { events } = req.body;
  
  logger.info('Received request to update exam events', { examId, events });
  
  try {
    // Get the current exam info
    const examInfo = await redisClient.getExamInfo(examId);
    
    if (!examInfo) {
      logger.error(`Exam not found with ID: ${examId}`);
      return res.status(404).json({ 
        error: 'Not Found',
        message: 'Exam not found' 
      });
    }
    
    // Update the events in the exam info
    if (!examInfo.events) {
      examInfo.events = {};
    }
    
    // Merge the events from the request with existing events
    examInfo.events = {
      ...examInfo.events,
      ...events
    };
    
    // send metrics to metric server
    MetricService.sendMetrics(examId, {
      event: {
        ...examInfo.events
      }
    });

    // Update the exam info in Redis
    await redisClient.updateExamInfo(examId, examInfo);
    
    // Return success response with the same structure as other endpoints
    return res.status(200).json({
      success: true,
      data: {
        id: examId,
        message: 'Exam events updated successfully'
      }
    });
  } catch (error) {
    logger.error('Error updating exam events', { error: error.message });
    return res.status(500).json({ 
      success: false,
      error: 'Failed to update exam events',
      message: error.message
    });
  }
}

/**
 * Submit feedback metrics for an exam
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function submitMetrics(req, res) {
  const examId = req.params.examId;
  const feedbackData = req.body;
  
  logger.info('Received feedback metrics submission', { examId, type: feedbackData.type });
  
  try {
    // Send the feedback data to the metric service
    const result = await MetricService.sendMetrics(examId, { event: { ...feedbackData } });
    
    return res.status(200).json({ 
      success: true,
      message: 'Feedback submitted successfully'
    });
  } catch (error) {
    logger.error('Error submitting feedback metrics', { error: error.message });
    return res.status(500).json({ 
      error: 'Failed to submit feedback',
      message: error.message
    });
  }
}

module.exports = {
  createExam,
  getCurrentExam,
  getExamAssets,
  getExamQuestions,
  evaluateExam,
  endExam,
  getExamAnswers,
  getExamStatus,
  getExamResult,
  updateExamEvents,
  submitMetrics
}; 
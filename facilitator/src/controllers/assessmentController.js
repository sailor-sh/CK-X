const logger = require('../utils/logger');
const { discoverLabs } = require('../services/labsService');

/**
 * Get all assessments
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
async function getAssessments(req, res) {
  logger.info('Received request to get all assessments');
  
  try {
    const labs = discoverLabs();

    logger.info(`Discovered ${labs.length} labs`);

    return res.status(200).json(labs);
  } catch (error) {
    logger.error('Error reading labs data', { error: error.message });
    return res.status(500).json({
      error: 'Failed to retrieve labs data',
      message: error.message
    });
  }
}

module.exports = {
  getAssessments
}; 
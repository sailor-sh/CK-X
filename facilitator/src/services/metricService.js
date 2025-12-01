/**
 * Metric Service
 * Handles sending metrics to the CK-X metric server
 */

const axios = require('axios');
const logger = require('../utils/logger');

class MetricService {
    constructor() {
        this.METRIC_SERVER_URL = 'https://ck-x-metric-server.onrender.com/api/v1/collect';
        this.TRACK_METRICS = process.env.TRACK_METRICS ? process.env.TRACK_METRICS === 'true' : true;
    }
    
    /**
     * Send metrics to the metric server for analytics purposes do not collect any personal data
     * @param {string} examId - The exam ID
     * @param {Object} data - The metric data to send
     * @returns {Promise} - Response from the metric server
     */
    async sendMetrics(examId, data) {
        data.cloud = "ck-x-cloud";
        data.version = "1.0.0";
        if (!this.TRACK_METRICS) return;
        try {
            const metricData = {
                examId: examId,
                timestamp: new Date().toISOString(),
                ...data
            };

            const response = await axios.post(this.METRIC_SERVER_URL, metricData, {
                headers: {
                    'Content-Type': 'application/json',
                }
            });
            return response.data;
        } catch (error) {
            logger.error('Error sending metrics:', error);
            // Don't throw the error to prevent disrupting the exam flow
            return null;
        }
    }
}

// Create and export a singleton instance
const metricService = new MetricService();
module.exports = metricService; 
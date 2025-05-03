const express = require('express');
const examController = require('../controllers/examController');
const { validateCreateExam, validateEvaluateExam, validateExamEvents } = require('../middleware/validators');

const router = express.Router();

/**
 * @route POST /api/v1/exams
 * @desc Create a new exam
 * @access Public
 */
router.post('/', validateCreateExam, examController.createExam);

/**
 * @route GET /api/v1/exams/current
 * @desc Get the current active exam
 * @access Public
 */
router.get('/current', examController.getCurrentExam);

/**
 * @route GET /api/v1/exams/:examId/assets
 * @desc Get exam assets
 * @access Public
 */
router.get('/:examId/assets', examController.getExamAssets);

/**
 * @route GET /api/v1/exams/:examId/questions
 * @desc Get exam questions
 * @access Public
 */
router.get('/:examId/questions', examController.getExamQuestions);

/**
 * @route POST /api/v1/exams/:examId/evaluate
 * @desc Evaluate an exam
 * @access Public
 */
router.post('/:examId/evaluate', validateEvaluateExam, examController.evaluateExam);

/**
 * @route POST /api/v1/exams/:examId/terminate
 * @desc End an exam
 * @access Public
 */
router.post('/:examId/terminate', examController.endExam);

/**
 * @route GET /api/v1/exams/:examId/answers
 * @desc Get exam answers
 * @access Public
 */
router.get('/:examId/answers', examController.getExamAnswers);

/**
 * @route GET /api/v1/exams/:examId/status
 * @desc Get exam status
 * @access Public
 */
router.get('/:examId/status', examController.getExamStatus);

/**
 * @route GET /api/v1/exams/:examId/result
 * @desc Get exam result
 * @access Public
 */
router.get('/:examId/result', examController.getExamResult);

/**
 * @route POST /api/v1/exams/:examId/events
 * @desc Update exam events
 * @access Public
 */
router.post('/:examId/events', validateExamEvents, examController.updateExamEvents);

/**
 * @route POST /api/v1/exams/metrics/:examId
 * @desc Submit feedback metrics for an exam
 * @access Public
 */
router.post('/metrics/:examId', examController.submitMetrics);

module.exports = router; 
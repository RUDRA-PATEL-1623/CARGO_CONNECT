const { body, query } = require('express-validator');

const paginationValidator = [
  query('page')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer')
    .toInt(),
  query('limit')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1, max: 50 })
    .withMessage('Limit must be between 1 and 50')
    .toInt(),
];

const submitFeedbackValidator = [
  body('shipmentId')
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
  body('rating')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5')
    .toInt(),
  body('experienceTags')
    .optional({ nullable: true })
    .isArray({ max: 12 })
    .withMessage('Experience tags must be an array with up to 12 items'),
  body('experienceTags.*')
    .optional()
    .trim()
    .isLength({ min: 2, max: 40 })
    .withMessage('Each experience tag must be 2-40 characters'),
  body('comments')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 1500 })
    .withMessage('Comments must be 1500 characters or less'),
  body('wouldRecommend')
    .optional()
    .isBoolean()
    .withMessage('Recommend flag must be true or false')
    .toBoolean(),
];

const feedbackListValidator = [
  ...paginationValidator,
  query('shipmentId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
  query('rating')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5')
    .toInt(),
];

module.exports = {
  feedbackListValidator,
  submitFeedbackValidator,
};

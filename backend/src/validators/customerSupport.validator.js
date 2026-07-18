const { body, query } = require('express-validator');

const allowedIssueTypes = [
  'booking',
  'payment',
  'driver',
  'delay',
  'damage',
  'invoice',
  'other',
];

const allowedPriorities = ['low', 'medium', 'high', 'urgent'];
const allowedStatuses = ['open', 'in_review', 'resolved', 'closed'];

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

const createSupportIssueValidator = [
  body('shipmentId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
  body('issueType')
    .isIn(allowedIssueTypes)
    .withMessage(`Issue type must be one of: ${allowedIssueTypes.join(', ')}`),
  body('priority')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedPriorities)
    .withMessage(`Priority must be one of: ${allowedPriorities.join(', ')}`),
  body('subject')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 3, max: 160 })
    .withMessage('Subject must be 3-160 characters'),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ min: 10, max: 2000 })
    .withMessage('Description must be 10-2000 characters'),
  body('attachmentUrl')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Attachment URL must be 500 characters or less')
    .custom((value) => {
      if (/^\/uploads\//.test(value)) {
        return true;
      }

      try {
        const parsed = new URL(value);
        return ['http:', 'https:'].includes(parsed.protocol);
      } catch (error) {
        return false;
      }
    })
    .withMessage('Attachment URL must be an http(s) URL or local /uploads path'),
];

const supportIssueListValidator = [
  ...paginationValidator,
  query('status')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedStatuses)
    .withMessage(`Status must be one of: ${allowedStatuses.join(', ')}`),
  query('priority')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedPriorities)
    .withMessage(`Priority must be one of: ${allowedPriorities.join(', ')}`),
  query('issueType')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedIssueTypes)
    .withMessage(`Issue type must be one of: ${allowedIssueTypes.join(', ')}`),
  query('shipmentId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
  query('search')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 120 })
    .withMessage('Search must be 120 characters or less'),
];

module.exports = {
  createSupportIssueValidator,
  supportIssueListValidator,
};

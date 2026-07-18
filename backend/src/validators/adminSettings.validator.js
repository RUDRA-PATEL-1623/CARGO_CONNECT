const { body, query } = require('express-validator');

const allowedValueTypes = ['string', 'number', 'boolean', 'json'];

const settingsQueryValidator = [
  query('settingGroup')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 80 })
    .withMessage('Setting group must be 2-80 characters'),
  query('group')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 80 })
    .withMessage('Group must be 2-80 characters'),
];

const updateSettingsValidator = [
  body()
    .custom((value) => {
      if (!value || typeof value !== 'object' || Array.isArray(value)) {
        throw new Error('Settings payload must be an object');
      }

      const settings = value.settings || value;
      if (Array.isArray(settings)) {
        if (settings.length === 0) {
          throw new Error('Settings array cannot be empty');
        }

        settings.forEach((setting) => {
          if (!setting.settingGroup || !setting.settingKey) {
            throw new Error('Each setting must include settingGroup and settingKey');
          }

          if (!allowedValueTypes.includes(setting.valueType || 'json')) {
            throw new Error(`Setting value type must be one of: ${allowedValueTypes.join(', ')}`);
          }
        });

        return true;
      }

      if (!settings || typeof settings !== 'object' || Array.isArray(settings)) {
        throw new Error('Settings must be an object or an array');
      }

      const groups = Object.keys(settings);
      if (groups.length === 0) {
        throw new Error('At least one setting group is required');
      }

      groups.forEach((group) => {
        if (!settings[group] || typeof settings[group] !== 'object' || Array.isArray(settings[group])) {
          throw new Error('Each setting group must be an object of key/value pairs');
        }
      });

      return true;
    }),
  body('settings.*.settingGroup')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 80 })
    .withMessage('Setting group must be 2-80 characters'),
  body('settings.*.settingKey')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 120 })
    .withMessage('Setting key must be 2-120 characters'),
  body('settings.*.description')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 255 })
    .withMessage('Description must be 255 characters or less'),
  body('settings.*.valueType')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedValueTypes)
    .withMessage(`Value type must be one of: ${allowedValueTypes.join(', ')}`),
  body('settings.*.isPublic')
    .optional({ nullable: true })
    .isBoolean()
    .withMessage('isPublic must be a boolean')
    .toBoolean(),
  body('settings.*.isActive')
    .optional({ nullable: true })
    .isBoolean()
    .withMessage('isActive must be a boolean')
    .toBoolean(),
];

module.exports = {
  settingsQueryValidator,
  updateSettingsValidator,
};

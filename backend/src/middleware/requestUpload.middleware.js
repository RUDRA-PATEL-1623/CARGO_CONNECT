const fs = require('fs');
const path = require('path');
const multer = require('multer');

const env = require('../config/env');
const AppError = require('../utils/appError');

const allowedFiles = new Map([
  ['image/jpeg', new Set(['.jpg', '.jpeg'])],
  ['image/png', new Set(['.png'])],
  ['image/webp', new Set(['.webp'])],
  ['application/pdf', new Set(['.pdf'])],
]);

const ensureDirectory = (directory) => {
  fs.mkdirSync(directory, { recursive: true });
  return directory;
};

const createUpload = ({ folder, fieldName }) => {
  const uploadDirectory = ensureDirectory(path.join(env.uploads.directory, folder));

  const storage = multer.diskStorage({
    destination(req, file, callback) {
      callback(null, uploadDirectory);
    },
    filename(req, file, callback) {
      const extension = path.extname(file.originalname || '').toLowerCase();
      const safeBaseName = path
        .basename(file.originalname || fieldName, extension)
        .replace(/[^a-zA-Z0-9_-]/g, '-')
        .slice(0, 40);
      const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;

      callback(null, `${safeBaseName || fieldName}-${uniqueSuffix}${extension}`);
    },
  });

  return multer({
    storage,
    limits: {
      fileSize: env.uploads.maxFileSizeMb * 1024 * 1024,
      files: 1,
    },
    fileFilter(req, file, callback) {
      const allowedExtensions = allowedFiles.get(file.mimetype);
      const extension = path.extname(file.originalname || '').toLowerCase();

      if (!allowedExtensions || !allowedExtensions.has(extension)) {
        return callback(
          new AppError('Attachment must be a JPG, PNG, WEBP, or PDF file with a matching extension', 422),
        );
      }

      return callback(null, true);
    },
  });
};

const runUpload = (upload, fieldName) => (req, res, next) => {
  upload.single(fieldName)(req, res, (error) => {
    if (!error) {
      return next();
    }

    if (error instanceof multer.MulterError) {
      const messageByCode = {
        LIMIT_FILE_SIZE: `File exceeds the ${env.uploads.maxFileSizeMb} MB limit`,
        LIMIT_FILE_COUNT: 'Only one file can be uploaded',
        LIMIT_UNEXPECTED_FILE: `Unexpected file field. Use form field "${fieldName}"`,
      };

      return next(new AppError(
        messageByCode[error.code] || 'File upload failed',
        error.code === 'LIMIT_FILE_SIZE' ? 413 : 400,
        { code: error.code },
      ));
    }

    return next(error);
  });
};

const uploadReportAttachment = runUpload(
  createUpload({ folder: 'reports', fieldName: 'attachment' }),
  'attachment',
);

const uploadFuelBill = runUpload(
  createUpload({ folder: 'fuel-bills', fieldName: 'bill' }),
  'bill',
);

const cleanupUploadedFile = (file) => {
  if (!file?.path) {
    return;
  }

  fs.unlink(file.path, () => {});
};

module.exports = {
  cleanupUploadedFile,
  uploadFuelBill,
  uploadReportAttachment,
};

const fs = require('fs');
const path = require('path');
const multer = require('multer');

const env = require('../config/env');
const AppError = require('../utils/appError');

const proofUploadDirectory = path.join(env.uploads.directory, 'proofs');
const allowedFiles = new Map([
  ['image/jpeg', new Set(['.jpg', '.jpeg'])],
  ['image/png', new Set(['.png'])],
  ['image/webp', new Set(['.webp'])],
]);

fs.mkdirSync(proofUploadDirectory, { recursive: true });

const storage = multer.diskStorage({
  destination(req, file, callback) {
    callback(null, proofUploadDirectory);
  },
  filename(req, file, callback) {
    const extension = path.extname(file.originalname || '').toLowerCase();
    const safeBaseName = path
      .basename(file.originalname || 'proof', extension)
      .replace(/[^a-zA-Z0-9_-]/g, '-')
      .slice(0, 40);
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;

    callback(null, `${safeBaseName || 'proof'}-${uniqueSuffix}${extension}`);
  },
});

const proofUpload = multer({
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
        new AppError('Proof file must be a JPG, PNG, or WEBP image with a matching extension', 422),
      );
    }

    return callback(null, true);
  },
});

const uploadProofFile = (req, res, next) => {
  proofUpload.single('proof')(req, res, (error) => {
    if (!error) {
      return next();
    }

    if (error instanceof multer.MulterError) {
      const messageByCode = {
        LIMIT_FILE_SIZE: `Proof file exceeds the ${env.uploads.maxFileSizeMb} MB limit`,
        LIMIT_FILE_COUNT: 'Only one proof file can be uploaded',
        LIMIT_UNEXPECTED_FILE: 'Unexpected proof file field. Use form field "proof"',
      };

      return next(new AppError(
        messageByCode[error.code] || 'Proof upload failed',
        error.code === 'LIMIT_FILE_SIZE' ? 413 : 400,
        { code: error.code },
      ));
    }

    return next(error);
  });
};

const cleanupUploadedFile = (file) => {
  if (!file?.path) {
    return;
  }

  fs.unlink(file.path, () => {});
};

module.exports = {
  cleanupUploadedFile,
  uploadProofFile,
};

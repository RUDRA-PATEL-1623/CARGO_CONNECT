const crypto = require('crypto');

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const env = require('../config/env');
const { OTP_PURPOSES } = require('../constants/auth.constants');

const normalizeEmail = (value) => {
  return value ? String(value).trim().toLowerCase() : null;
};

const normalizePhone = (value) => {
  return value ? String(value).trim().replace(/[\s-]+/g, '') : null;
};

const normalizeIdentifier = (value) => {
  if (!value) {
    return null;
  }

  const trimmed = String(value).trim();

  if (trimmed.includes('@')) {
    return normalizeEmail(trimmed);
  }

  if (/^\+?[0-9\s-]+$/.test(trimmed)) {
    return normalizePhone(trimmed);
  }

  return trimmed;
};

const hashPassword = async (password) => {
  return bcrypt.hash(password, 12);
};

const comparePassword = async (password, passwordHash) => {
  if (!passwordHash) {
    return false;
  }

  return bcrypt.compare(password, passwordHash);
};

const generateOtp = () => {
  return crypto.randomInt(0, 1000000).toString().padStart(6, '0');
};

const generateResetToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

const hashOtp = async (otp) => {
  return bcrypt.hash(otp, 10);
};

const compareOtp = async (otp, otpHash) => {
  if (!otpHash) {
    return false;
  }

  return bcrypt.compare(otp, otpHash);
};

const createPublicId = () => {
  return crypto.randomUUID();
};

const signAuthToken = (user) => {
  return jwt.sign(
    {
      sub: user.publicId,
      userId: user.id,
      role: user.role,
    },
    env.jwt.secret,
    { expiresIn: env.jwt.expiresIn },
  );
};

const verifyAuthToken = (token) => {
  return jwt.verify(token, env.jwt.secret);
};

const signPasswordResetToken = (user, expiresIn = '15m') => {
  return jwt.sign(
    {
      sub: user.publicId,
      userId: user.id,
      purpose: OTP_PURPOSES.RESET_PASSWORD,
    },
    env.jwt.secret,
    { expiresIn },
  );
};

const createAuthSession = (user) => {
  const token = signAuthToken(user);
  const decoded = jwt.decode(token);
  const expiresAt = decoded && decoded.exp
    ? new Date(decoded.exp * 1000).toISOString()
    : null;

  return {
    token,
    tokenType: 'Bearer',
    expiresIn: env.jwt.expiresIn,
    expiresAt,
  };
};

const sanitizeUser = (user) => {
  if (!user) {
    return null;
  }

  const { passwordHash, password_hash: passwordHashSnake, ...safeUser } = user;
  void passwordHash;
  void passwordHashSnake;
  return safeUser;
};

module.exports = {
  compareOtp,
  comparePassword,
  createAuthSession,
  createPublicId,
  generateResetToken,
  generateOtp,
  hashOtp,
  hashPassword,
  normalizeEmail,
  normalizeIdentifier,
  normalizePhone,
  sanitizeUser,
  signAuthToken,
  signPasswordResetToken,
  verifyAuthToken,
};

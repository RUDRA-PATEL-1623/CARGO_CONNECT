const env = require('../config/env');
const { getTransporter, hasSmtpConfig } = require('../config/mailer');

const sendMail = async ({ to, subject, text, html }) => {
  if (!hasSmtpConfig()) {
    console.log('[mail:fallback]', {
      to,
      subject,
      text,
    });

    return {
      delivered: false,
      fallback: 'console',
    };
  }

  const transporter = getTransporter();
  const info = await transporter.sendMail({
    from: env.mail.from,
    to,
    subject,
    text,
    html,
  });

  return {
    delivered: true,
    messageId: info.messageId,
  };
};

const sendCustomerRegistrationOtp = async ({ to, name, otp, expiresInMinutes }) => {
  const subject = 'Verify your CargoConnect customer account';
  const text = [
    `Hello ${name},`,
    '',
    `Your CargoConnect verification code is ${otp}.`,
    `This code expires in ${expiresInMinutes} minutes.`,
    '',
    'If you did not request this, you can ignore this email.',
  ].join('\n');
  const html = `
    <p>Hello ${name},</p>
    <p>Your CargoConnect verification code is <strong>${otp}</strong>.</p>
    <p>This code expires in ${expiresInMinutes} minutes.</p>
    <p>If you did not request this, you can ignore this email.</p>
  `;

  return sendMail({
    to,
    subject,
    text,
    html,
  });
};

const sendPasswordResetOtp = async ({ to, name, otp, expiresInMinutes }) => {
  const subject = 'Reset your CargoConnect password';
  const text = [
    `Hello ${name},`,
    '',
    `Your CargoConnect password reset code is ${otp}.`,
    `This code expires in ${expiresInMinutes} minutes.`,
    '',
    'If you did not request this, you can ignore this message.',
  ].join('\n');
  const html = `
    <p>Hello ${name},</p>
    <p>Your CargoConnect password reset code is <strong>${otp}</strong>.</p>
    <p>This code expires in ${expiresInMinutes} minutes.</p>
    <p>If you did not request this, you can ignore this message.</p>
  `;

  return sendMail({
    to,
    subject,
    text,
    html,
  });
};

module.exports = {
  sendCustomerRegistrationOtp,
  sendPasswordResetOtp,
  sendMail,
};

const nodemailer = require('nodemailer');

const env = require('./env');

let transporter;

const hasSmtpConfig = () => Boolean(env.mail.host);

const getTransporter = () => {
  if (!hasSmtpConfig()) {
    return null;
  }

  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: env.mail.host,
      port: env.mail.port,
      secure: env.mail.secure,
      auth:
        env.mail.user && env.mail.password
          ? {
              user: env.mail.user,
              pass: env.mail.password,
            }
          : undefined,
    });
  }

  return transporter;
};

module.exports = {
  getTransporter,
  hasSmtpConfig,
};

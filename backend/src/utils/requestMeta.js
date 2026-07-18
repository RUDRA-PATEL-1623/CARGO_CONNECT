const getRequestMeta = (req) => ({
  ipAddress: req.ip,
  userAgent: req.get('user-agent') || null,
});

module.exports = {
  getRequestMeta,
};

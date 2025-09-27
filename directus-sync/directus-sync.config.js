module.exports = {
  debug: true,
  dumpPath: './directus-config',

  directusUrl: process.env.DIRECTUS_URL_SYNC || 'http://directus:8055',
  directusEmail: process.env.DIRECTUS_EMAIL_SYNC || 'admin@example.com',
  directusPassword: process.env.DIRECTUS_PASSWORD_SYNC || 'd1r3ctu5'
};

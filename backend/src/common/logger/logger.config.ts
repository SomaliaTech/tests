// src/common/logger/logger.config.ts
export const loggerConfig = {
  development: {
    logLevel: ['log', 'error', 'warn', 'debug', 'verbose'],
    enableDebug: true,
    enableRequestLogs: true,
    enableResponseLogs: true,
  },
  production: {
    logLevel: ['error', 'warn'], // Only errors and warnings
    enableDebug: false,
    enableRequestLogs: false,
    enableResponseLogs: false,
  },
  test: {
    logLevel: ['error'], // Only errors
    enableDebug: false,
    enableRequestLogs: false,
    enableResponseLogs: false,
  },
};

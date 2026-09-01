// src/common/logger/secure-logger.service.ts
import { Injectable, LoggerService, LogLevel } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LogSanitizer } from '../utils/log-sanitizer.util';

@Injectable()
export class SecureLogger implements LoggerService {
  private readonly isProduction: boolean;
  private readonly consoleLogger = console as Console & {
    debug: (...args: any[]) => void;
    verbose: (...args: any[]) => void;
  };

  constructor(private configService: ConfigService) {
    this.isProduction = configService.get('NODE_ENV') === 'production';
  }

  log(message: any, ...optionalParams: any[]) {
    if (this.isProduction) return;
    const sanitized = LogSanitizer.sanitize(message);
    const sanitizedParams = optionalParams.map((p) => LogSanitizer.sanitize(p));
    this.consoleLogger.log(sanitized, ...sanitizedParams);
  }

  error(message: any, ...optionalParams: any[]) {
    const sanitized = LogSanitizer.sanitize(message);
    const sanitizedParams = optionalParams.map((p) => LogSanitizer.sanitize(p));
    this.consoleLogger.error(sanitized, ...sanitizedParams);
  }

  warn(message: any, ...optionalParams: any[]) {
    if (this.isProduction) return;
    const sanitized = LogSanitizer.sanitize(message);
    const sanitizedParams = optionalParams.map((p) => LogSanitizer.sanitize(p));
    this.consoleLogger.warn(sanitized, ...sanitizedParams);
  }

  debug(message: any, ...optionalParams: any[]) {
    if (this.isProduction) return;
    const sanitized = LogSanitizer.sanitize(message);
    const sanitizedParams = optionalParams.map((p) => LogSanitizer.sanitize(p));
    this.consoleLogger.debug(sanitized, ...sanitizedParams);
  }

  verbose(message: any, ...optionalParams: any[]) {
    if (this.isProduction) return;
    const sanitized = LogSanitizer.sanitize(message);
    const sanitizedParams = optionalParams.map((p) => LogSanitizer.sanitize(p));
    this.consoleLogger.verbose(sanitized, ...sanitizedParams);
  }
}

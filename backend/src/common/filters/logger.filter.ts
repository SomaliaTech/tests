// src/common/filters/logger.filter.ts
import { Catch, ArgumentsHost, Logger } from '@nestjs/common';
import { LogSanitizer } from '../utils/log-sanitizer.util';

@Catch()
export class SanitizedLoggerFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: any, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const request = ctx.getRequest();
    const response = ctx.getResponse();

    // ✅ Sanitize request data before logging
    const sanitizedRequest = {
      method: request.method,
      url: request.url,
      headers: LogSanitizer.sanitize(request.headers),
      body: LogSanitizer.sanitize(request.body),
      params: LogSanitizer.sanitize(request.params),
      query: LogSanitizer.sanitize(request.query),
    };

    // ✅ Sanitize error before logging
    const sanitizedError = LogSanitizer.sanitize({
      message: exception.message,
      stack: exception.stack,
      ...exception,
    });

    this.logger.error('Request failed', {
      request: sanitizedRequest,
      error: sanitizedError,
    });

    response.status(exception.status || 500).json({
      statusCode: exception.status || 500,
      message: exception.message || 'Internal server error',
    });
  }
}

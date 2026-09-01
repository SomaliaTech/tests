// src/common/utils/log-sanitizer.util.ts
export class LogSanitizer {
  private static readonly SENSITIVE_PATTERNS = [
    /(api[_-]?key\s*[=:]\s*)([^\s,;]+)/gi,
    /(apikey\s*[=:]\s*)([^\s,;]+)/gi,
    /(password\s*[=:]\s*)([^\s,;]+)/gi,
    /(passwd\s*[=:]\s*)([^\s,;]+)/gi,
    /(token\s*[=:]\s*)([^\s,;]+)/gi,
    /(access_token\s*[=:]\s*)([^\s,;]+)/gi,
    /(refresh_token\s*[=:]\s*)([^\s,;]+)/gi,
    /(bearer\s+)([a-zA-Z0-9._-]+)/gi,
    /(authorization\s*[=:]\s*)([^\s,;]+)/gi,
    /(\+?252\d{2})(\d{3})(\d{3})/g,
    /\b(\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4})\b/g,
    /\b(cvv\s*[=:]\s*)(\d{3,4})\b/gi,
    /\b(otp\s*[=:]\s*)(\d{4,6})\b/gi,
    /(secret\s*[=:]\s*)([^\s,;]+)/gi,
  ];

  static sanitize(data: any): any {
    if (typeof data === 'string') {
      return this.sanitizeString(data);
    }

    if (Array.isArray(data)) {
      return data.map((item) => this.sanitize(item));
    }

    if (typeof data === 'object' && data !== null) {
      return this.sanitizeObject(data);
    }

    return data;
  }

  static sanitizeString(str: string): string {
    let sanitized = str;

    for (const pattern of this.SENSITIVE_PATTERNS) {
      sanitized = sanitized.replace(pattern, (match, p1, p2) => {
        if (p1 && p2) {
          return `${p1}${this.maskValue(p2)}`;
        }
        if (p1 && !p2) {
          return this.maskValue(match);
        }
        return match;
      });
    }

    return sanitized;
  }

  static sanitizeObject(obj: Record<string, any>): Record<string, any> {
    const sanitized: Record<string, any> = {};
    const sensitiveKeys = [
      'password',
      'passwd',
      'token',
      'apikey',
      'api_key',
      'apiKey',
      'secret',
      'authorization',
      'access_token',
      'refresh_token',
      'cvv',
      'otp',
      'creditcard',
      'cardnumber',
      'card_number',
    ];

    for (const [key, value] of Object.entries(obj)) {
      const lowerKey = key.toLowerCase();

      if (sensitiveKeys.some((sk) => lowerKey.includes(sk))) {
        sanitized[key] = this.maskValue(value);
      } else if (typeof value === 'object' && value !== null) {
        sanitized[key] = this.sanitize(value);
      } else if (typeof value === 'string') {
        sanitized[key] = this.sanitizeString(value);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  static maskValue(value: any): string {
    if (typeof value !== 'string') {
      return '***';
    }

    if (value.length <= 4) {
      return '***';
    }

    const firstTwo = value.substring(0, 2);
    const lastTwo = value.substring(value.length - 2);
    const middleLength = value.length - 4;
    const masked = '*'.repeat(Math.min(middleLength, 10));

    return `${firstTwo}${masked}${lastTwo}`;
  }

  static maskPhoneNumber(phone: string): string {
    const cleaned = phone.replace(/\D/g, '');
    if (cleaned.length < 6) {
      return '***';
    }
    const firstThree = cleaned.substring(0, 3);
    const lastTwo = cleaned.substring(cleaned.length - 2);
    const middleLength = cleaned.length - 5;
    const masked = '*'.repeat(Math.min(middleLength, 8));

    return `${firstThree}${masked}${lastTwo}`;
  }

  static maskEmail(email: string): string {
    const [username, domain] = email.split('@');
    if (!domain) return '***';

    const firstChar = username.charAt(0);
    const lastChar = username.charAt(username.length - 1);
    const maskedUsername =
      username.length <= 2 ? `${firstChar}***` : `${firstChar}***${lastChar}`;

    return `${maskedUsername}@${domain}`;
  }

  static sanitizeForLog(data: any): any {
    return this.sanitize(data);
  }
}

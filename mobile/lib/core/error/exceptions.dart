class ServerException implements Exception {
  final String message;

  // 👇 ADDED 'const' BACK HERE
  const ServerException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;

  // 👇 ALSO MAKE THIS 'const'
  const UnauthorizedException(this.message);

  @override
  String toString() => message;
}
// 🚨 ADDED: Specific exception for 401 Unauthorized

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException(this.message);
}

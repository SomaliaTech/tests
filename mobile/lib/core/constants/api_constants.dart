class ApiConstants {
  // static const String baseUrl = 'http://162.0.225.86';
  // static const String baseUrl = 'http://localhost:8080';
  static const String baseUrl = 'http://192.168.1.101:8080';

  static const String products = '/products';
  static const String categories = '/categories';
  static const String search = '/products/search';
  static const String featured = '/products/featured';
  static const String subcategories = '/categories/sub';
  static const String notifications = '/notifications';

  static String get wsUrl => baseUrl
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://');

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

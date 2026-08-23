class ApiConstants {
  static const String baseUrl = 'http://10.20.30.206:8080';

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

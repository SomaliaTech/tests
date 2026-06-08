class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';
  static const String products = '/products';
  static const String categories = '/categories';
  static const String search = '/products/search';
  static const String featured = '/products/featured';

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
}

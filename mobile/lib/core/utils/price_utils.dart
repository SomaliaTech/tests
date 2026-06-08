import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';

class PriceUtils {
  static Either<Failure, double> parsePrice(dynamic value) {
    try {
      if (value == null) {
        return Left(ValidationFailure('Price cannot be null'));
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null) {
          return Left(ValidationFailure('Invalid price format: $value'));
        }
        return Right(parsed);
      }
      if (value is num) {
        return Right(value.toDouble());
      }
      return Left(
        ValidationFailure('Invalid price type: ${value.runtimeType}'),
      );
    } catch (e) {
      return Left(ValidationFailure('Error parsing price: $e'));
    }
  }

  static String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }
}

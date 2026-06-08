import 'package:fpdart/fpdart.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../error/failures.dart';

abstract class NetworkInfo {
  Future<Either<Failure, bool>> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection internetConnection;

  const NetworkInfoImpl({required this.internetConnection});

  @override
  Future<Either<Failure, bool>> get isConnected async {
    try {
      // ✅ This checks for actual data/internet access, not just connection status
      final hasAccess = await internetConnection.hasInternetAccess;
      return Right(hasAccess);
    } catch (e) {
      return Left(NetworkFailure('Failed to check network status: $e'));
    }
  }
}

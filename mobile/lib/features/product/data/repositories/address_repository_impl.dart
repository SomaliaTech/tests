import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_datasource.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource remoteDataSource;
  final StorageService storageService;

  const AddressRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  Future<String?> _getToken() async => await storageService.getAuthToken();

  @override
  ResultFuture<List<Address>> getAddresses() async {
    try {
      final token = await _getToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));
      final addresses = await remoteDataSource.getAddresses(token);
      return Right(addresses);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<Address> addAddress(Address address) async {
    try {
      final token = await _getToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));
      final newAddress = await remoteDataSource.addAddress(token, address);
      return Right(newAddress);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<Address> setDefaultAddress(String addressId) async {
    try {
      final token = await _getToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));
      final address = await remoteDataSource.setDefaultAddress(
        token,
        addressId,
      );
      return Right(address);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<void> deleteAddress(String addressId) async {
    try {
      final token = await _getToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));
      await remoteDataSource.deleteAddress(token, addressId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}

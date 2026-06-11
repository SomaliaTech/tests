import '../../../../core/utils/typedefs.dart';
import '../entities/address.dart';
import '../repositories/address_repository.dart';

class GetAddresses {
  final AddressRepository repository;
  const GetAddresses(this.repository);
  ResultFuture<List<Address>> call() => repository.getAddresses();
}

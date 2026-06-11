import '../../../../core/utils/typedefs.dart';
import '../entities/address.dart';
import '../repositories/address_repository.dart';

class AddAddress {
  final AddressRepository repository;
  const AddAddress(this.repository);
  ResultFuture<Address> call(Address address) => repository.addAddress(address);
}

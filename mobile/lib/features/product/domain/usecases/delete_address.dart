import '../../../../core/utils/typedefs.dart';
import '../repositories/address_repository.dart';

class DeleteAddress {
  final AddressRepository repository;
  const DeleteAddress(this.repository);
  ResultFuture<void> call(String addressId) =>
      repository.deleteAddress(addressId);
}

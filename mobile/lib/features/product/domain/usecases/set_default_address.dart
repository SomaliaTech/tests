import 'package:mobile/features/product/domain/entities/address.dart';

import '../../../../core/utils/typedefs.dart';
import '../repositories/address_repository.dart';

class SetDefaultAddress {
  final AddressRepository repository;
  const SetDefaultAddress(this.repository);
  ResultFuture<Address> call(String addressId) =>
      repository.setDefaultAddress(addressId);
}

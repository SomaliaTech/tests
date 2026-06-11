import '../../../../core/utils/typedefs.dart';
import '../entities/address.dart';

abstract class AddressRepository {
  ResultFuture<List<Address>> getAddresses();
  ResultFuture<Address> addAddress(Address address);
  ResultFuture<Address> setDefaultAddress(String addressId);
  ResultFuture<void> deleteAddress(String addressId);
}

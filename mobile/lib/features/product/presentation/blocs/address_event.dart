import 'package:equatable/equatable.dart';
import '../../domain/entities/address.dart';

abstract class AddressEvent extends Equatable {
  const AddressEvent();
  @override
  List<Object?> get props => [];
}

class LoadAddressesEvent extends AddressEvent {}

class AddAddressEvent extends AddressEvent {
  final Address address;
  const AddAddressEvent(this.address);
  @override
  List<Object?> get props => [address];
}

class SetDefaultAddressEvent extends AddressEvent {
  final String addressId;
  const SetDefaultAddressEvent(this.addressId);
  @override
  List<Object?> get props => [addressId];
}

class DeleteAddressEvent extends AddressEvent {
  final String addressId;
  const DeleteAddressEvent(this.addressId);
  @override
  List<Object?> get props => [addressId];
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/address.dart';

abstract class AddressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressesLoaded extends AddressState {
  final List<Address> addresses;
  AddressesLoaded(this.addresses);

  @override
  List<Object?> get props => [addresses];
}

class AddressAdded extends AddressState {
  final Address address;
  AddressAdded(this.address);

  @override
  List<Object?> get props => [address];
}

// ✅ ADDED: Missing state
class AddressDeleted extends AddressState {}

class AddressError extends AddressState {
  final String message;
  AddressError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/address.dart';

abstract class AddressState extends Equatable {
  const AddressState();
  @override
  List<Object?> get props => [];
}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressesLoaded extends AddressState {
  final List<Address> addresses;
  const AddressesLoaded(this.addresses);
  @override
  List<Object?> get props => [addresses];
}

class AddressAdded extends AddressState {
  final Address address;
  const AddressAdded(this.address);
  @override
  List<Object?> get props => [address];
}

class AddressDeleted extends AddressState {}

class AddressError extends AddressState {
  final String message;
  const AddressError(this.message);
  @override
  List<Object?> get props => [message];
}

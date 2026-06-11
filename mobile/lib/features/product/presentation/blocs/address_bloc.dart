import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/domain/usecases/add_address.dart';
import 'package:mobile/features/product/domain/usecases/delete_address.dart';
import 'package:mobile/features/product/domain/usecases/get_addresses.dart';
import 'package:mobile/features/product/domain/usecases/set_default_address.dart';

import 'address_event.dart';
import 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final GetAddresses getAddresses;
  final AddAddress addAddress;
  final SetDefaultAddress setDefaultAddress;
  final DeleteAddress deleteAddress;

  AddressBloc({
    required this.getAddresses,
    required this.addAddress,
    required this.setDefaultAddress,
    required this.deleteAddress,
  }) : super(AddressInitial()) {
    on<LoadAddressesEvent>(_onLoadAddresses);
    on<AddAddressEvent>(_onAddAddress);
    on<SetDefaultAddressEvent>(_onSetDefault);
    on<DeleteAddressEvent>(_onDelete);
  }

  Future<void> _onLoadAddresses(
    LoadAddressesEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading());
    final result = await getAddresses();
    result.fold(
      (failure) => emit(AddressError(failure.message)),
      (addresses) => emit(AddressesLoaded(addresses)),
    );
  }

  Future<void> _onAddAddress(
    AddAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading());
    final result = await addAddress(event.address);
    result.fold((failure) => emit(AddressError(failure.message)), (address) {
      emit(AddressAdded(address));
      // Automatically reload addresses after adding
      add(LoadAddressesEvent());
    });
  }

  Future<void> _onSetDefault(
    SetDefaultAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading());
    final result = await setDefaultAddress(event.addressId);
    result.fold(
      (failure) => emit(AddressError(failure.message)),
      (_) => add(LoadAddressesEvent()),
    );
  }

  Future<void> _onDelete(
    DeleteAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading());
    final result = await deleteAddress(event.addressId);
    result.fold((failure) => emit(AddressError(failure.message)), (_) {
      emit(AddressDeleted());
      add(LoadAddressesEvent());
    });
  }
}

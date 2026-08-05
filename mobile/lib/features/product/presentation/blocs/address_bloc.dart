// lib/features/product/presentation/blocs/address_bloc.dart
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
    print('📋 [Bloc] Loading addresses...');
    emit(AddressLoading());

    final result = await getAddresses();
    result.fold(
      (failure) {
        print('❌ [Bloc] Failed to load: ${failure.message}');
        emit(AddressError(failure.message));
      },
      (addresses) {
        print('✅ [Bloc] Loaded ${addresses.length} addresses');
        emit(AddressesLoaded(addresses));
      },
    );
  }

  Future<void> _onAddAddress(
    AddAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    print('📦 [Bloc] Adding address: ${event.address.fullAddress}');
    emit(AddressLoading());

    final result = await addAddress(event.address);
    result.fold(
      (failure) {
        print('❌ [Bloc] Failed to add: ${failure.message}');
        emit(AddressError(failure.message));
      },
      (address) {
        print('✅ [Bloc] Address added: ${address.fullAddress}');
        // ✅ First emit the added state
        emit(AddressAdded(address));

        // ✅ Then reload all addresses
        print('🔄 [Bloc] Reloading addresses...');
        add(LoadAddressesEvent());
      },
    );
  }

  Future<void> _onSetDefault(
    SetDefaultAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    print('📌 [Bloc] Setting default address: ${event.addressId}');
    emit(AddressLoading());

    final result = await setDefaultAddress(event.addressId);
    result.fold(
      (failure) {
        print('❌ [Bloc] Failed to set default: ${failure.message}');
        emit(AddressError(failure.message));
      },
      (_) {
        print('✅ [Bloc] Default address set');
        add(LoadAddressesEvent());
      },
    );
  }

  Future<void> _onDelete(
    DeleteAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    print('🗑️ [Bloc] Deleting address: ${event.addressId}');
    emit(AddressLoading());

    final result = await deleteAddress(event.addressId);
    result.fold(
      (failure) {
        print('❌ [Bloc] Failed to delete: ${failure.message}');
        emit(AddressError(failure.message));
      },
      (_) {
        print('✅ [Bloc] Address deleted');
        emit(AddressDeleted());
        add(LoadAddressesEvent());
      },
    );
  }
}

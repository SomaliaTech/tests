// lib/core/services/address_injection.dart
import 'package:get_it/get_it.dart';
import 'package:mobile/features/product/data/datasources/address_remote_datasource.dart';
import 'package:mobile/features/product/data/repositories/address_repository_impl.dart';
import 'package:mobile/features/product/domain/repositories/address_repository.dart';
import 'package:mobile/features/product/domain/usecases/add_address.dart';
import 'package:mobile/features/product/domain/usecases/delete_address.dart';
import 'package:mobile/features/product/domain/usecases/get_addresses.dart';
import 'package:mobile/features/product/domain/usecases/set_default_address.dart';
import 'package:mobile/features/product/presentation/blocs/address_bloc.dart';

void addressRegisterDependencies(GetIt sl) {
  // Data Sources
  if (!sl.isRegistered<AddressRemoteDataSource>()) {
    sl.registerLazySingleton<AddressRemoteDataSource>(
      () => AddressRemoteDataSourceImpl(client: sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<AddressRepository>()) {
    sl.registerLazySingleton<AddressRepository>(
      () => AddressRepositoryImpl(remoteDataSource: sl(), storageService: sl()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetAddresses>()) {
    sl.registerLazySingleton(() => GetAddresses(sl()));
  }
  if (!sl.isRegistered<AddAddress>()) {
    sl.registerLazySingleton(() => AddAddress(sl()));
  }
  if (!sl.isRegistered<SetDefaultAddress>()) {
    sl.registerLazySingleton(() => SetDefaultAddress(sl()));
  }
  if (!sl.isRegistered<DeleteAddress>()) {
    sl.registerLazySingleton(() => DeleteAddress(sl()));
  }

  // BLoCs
  if (!sl.isRegistered<AddressBloc>()) {
    sl.registerFactory(
      () => AddressBloc(
        getAddresses: sl(),
        addAddress: sl(),
        setDefaultAddress: sl(),
        deleteAddress: sl(),
      ),
    );
  }
}

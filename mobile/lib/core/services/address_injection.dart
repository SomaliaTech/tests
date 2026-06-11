// Inside initDependencies():

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
  sl.registerLazySingleton<AddressRemoteDataSource>(
    () => AddressRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(remoteDataSource: sl(), storageService: sl()),
  );
  sl.registerLazySingleton(() => GetAddresses(sl()));
  sl.registerLazySingleton(() => AddAddress(sl()));
  sl.registerLazySingleton(() => SetDefaultAddress(sl()));
  sl.registerLazySingleton(() => DeleteAddress(sl()));
  sl.registerFactory(
    () => AddressBloc(
      getAddresses: sl(),
      addAddress: sl(),
      setDefaultAddress: sl(),
      deleteAddress: sl(),
    ),
  );
}

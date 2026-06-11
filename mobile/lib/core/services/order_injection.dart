import 'package:get_it/get_it.dart';
import 'package:mobile/features/order/data/datasources/order_remote_datasource.dart';
import 'package:mobile/features/order/data/repositories/order_repository_impl.dart';
import 'package:mobile/features/order/domain/repositories/order_repository.dart';
import 'package:mobile/features/order/domain/usecases/create_order.dart';
import 'package:mobile/features/order/domain/usecases/process_payment.dart';
import 'package:mobile/features/order/presentation/bloc/order_bloc.dart';

void orderRegisterDependencies(GetIt sl) {
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(remoteDataSource: sl(), storageService: sl()),
  );

  sl.registerLazySingleton(() => CreateOrder(sl()));
  sl.registerLazySingleton(() => ProcessPayment(sl()));

  // FIXED: Use registerLazySingleton instead of registerFactory
  // This keeps the Bloc alive and preserves state across the app
  sl.registerLazySingleton<OrderBloc>(
    () => OrderBloc(createOrder: sl(), processPayment: sl()),
  );
}

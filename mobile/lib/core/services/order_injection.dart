import 'package:get_it/get_it.dart';
import 'package:mobile/features/order/data/datasources/order_details_remote_datasource.dart';
import 'package:mobile/features/order/data/datasources/order_remote_datasource.dart';
import 'package:mobile/features/order/data/repositories/order_details_repository_impl.dart';
import 'package:mobile/features/order/data/repositories/order_repository_impl.dart';
import 'package:mobile/features/order/domain/repositories/order_details_repository.dart';
import 'package:mobile/features/order/domain/repositories/order_repository.dart';
import 'package:mobile/features/order/domain/usecases/create_order.dart';
import 'package:mobile/features/order/domain/usecases/get_order_details.dart';
import 'package:mobile/features/order/domain/usecases/process_payment.dart';
import 'package:mobile/features/order/presentation/bloc/order_bloc.dart';
import 'package:mobile/features/order/presentation/bloc/order_details_bloc.dart';
import 'package:mobile/features/order/data/datasources/order_history_remote_datasource.dart';
import 'package:mobile/features/order/data/repositories/order_history_repository_impl.dart';
import 'package:mobile/features/order/domain/repositories/order_history_repository.dart';
import 'package:mobile/features/order/domain/usecases/get_order_by_id.dart';
import 'package:mobile/features/order/domain/usecases/get_orders.dart';
import 'package:mobile/features/order/presentation/bloc/order_history_bloc.dart';

void orderRegisterDependencies(GetIt sl) {
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(remoteDataSource: sl(), storageService: sl()),
  );

  sl.registerLazySingleton<OrderDetailsRemoteDataSource>(
    () => OrderDetailsRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<OrderDetailsRepository>(
    () => OrderDetailsRepositoryImpl(
      remoteDataSource: sl(),
      storageService: sl(),
    ),
  );

  sl.registerLazySingleton<OrderHistoryRemoteDataSource>(
    () => OrderHistoryRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<OrderHistoryRepository>(
    () => OrderHistoryRepositoryImpl(
      remoteDataSource: sl(),
      storageService: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetOrders(sl()));
  sl.registerLazySingleton(() => GetOrderById(sl()));
  sl.registerFactory(
    () => OrderHistoryBloc(getOrders: sl(), getOrderById: sl()),
  );

  sl.registerLazySingleton(() => GetOrderDetails(sl()));
  sl.registerFactory(() => OrderDetailsBloc(getOrderDetails: sl()));
  sl.registerLazySingleton(() => CreateOrder(sl()));
  sl.registerLazySingleton(() => ProcessPayment(sl()));

  // FIXED: Use registerLazySingleton instead of registerFactory
  // This keeps the Bloc alive and preserves state across the app
  sl.registerLazySingleton<OrderBloc>(
    () => OrderBloc(createOrder: sl(), processPayment: sl()),
  );
}

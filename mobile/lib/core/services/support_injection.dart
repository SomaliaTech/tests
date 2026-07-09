import 'package:get_it/get_it.dart';
import 'package:mobile/features/support/data/datasources/faq_remote_data_source.dart';
import 'package:mobile/features/support/data/repositories/faq_repository_impl.dart';
import 'package:mobile/features/support/domain/repositories/faq_repository.dart';
import 'package:mobile/features/support/domain/usecases/get_active_faqs.dart';
import 'package:mobile/features/support/presentation/bloc/faq_bloc.dart';

void registerSupportDependencies(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<FaqRemoteDataSource>(
    () => FaqRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );

  // Repository
  sl.registerLazySingleton<FaqRepository>(
    () => FaqRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetActiveFaqs(sl()));

  // BLoC
  sl.registerFactory(() => FaqBloc(getActiveFaqs: sl()));
}

import 'package:get_it/get_it.dart';
import 'package:mobile/features/admin/presentation/bloc/faq/admin_faq_bloc.dart';
import 'package:mobile/features/support/domain/usecases/get_all_faqs.dart';
import 'package:mobile/features/support/domain/usecases/create_faq.dart';
import 'package:mobile/features/support/domain/usecases/update_faq.dart';
import 'package:mobile/features/support/domain/usecases/delete_faq.dart';
import 'package:mobile/features/support/domain/usecases/toggle_faq_status.dart';

void registerAdminFaqDependencies(GetIt sl) {
  // Use cases
  sl.registerLazySingleton(() => GetAllFaqs(sl())); // ✅ Added
  sl.registerLazySingleton(() => CreateFaq(sl()));
  sl.registerLazySingleton(() => UpdateFaq(sl()));
  sl.registerLazySingleton(() => DeleteFaq(sl()));
  sl.registerLazySingleton(() => ToggleFaqStatus(sl()));

  // BLoC
  sl.registerFactory(
    () => AdminFaqBloc(
      getAllFaqs: sl(), // ✅ Changed from getActiveFaqs
      createFaq: sl(),
      updateFaq: sl(),
      deleteFaq: sl(),
      toggleFaqStatus: sl(),
    ),
  );
}

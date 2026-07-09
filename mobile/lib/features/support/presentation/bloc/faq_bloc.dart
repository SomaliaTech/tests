import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/common/entities/no_params.dart';
import 'package:mobile/features/support/domain/usecases/get_active_faqs.dart';
import 'faq_event.dart';
import 'faq_state.dart';

class FaqBloc extends Bloc<FaqEvent, FaqState> {
  final GetActiveFaqs getActiveFaqs;

  FaqBloc({required this.getActiveFaqs}) : super(FaqInitial()) {
    on<LoadActiveFaqsEvent>(_onLoadActiveFaqs);
  }

  Future<void> _onLoadActiveFaqs(
    LoadActiveFaqsEvent event,
    Emitter<FaqState> emit,
  ) async {
    emit(FaqsLoading());
    final result = await getActiveFaqs(const NoParams());
    result.fold(
      (failure) => emit(FaqError(failure.message)),
      (faqs) => emit(FaqsLoaded(faqs)),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/support/domain/usecases/get_all_faqs.dart';
import 'package:mobile/features/support/domain/usecases/create_faq.dart';
import 'package:mobile/features/support/domain/usecases/update_faq.dart';
import 'package:mobile/features/support/domain/usecases/delete_faq.dart';
import 'package:mobile/features/support/domain/usecases/toggle_faq_status.dart';
import 'package:mobile/core/common/entities/no_params.dart';
import 'admin_faq_event.dart';
import 'admin_faq_state.dart';

class AdminFaqBloc extends Bloc<AdminFaqEvent, AdminFaqState> {
  final GetAllFaqs getAllFaqs; // ✅ Changed from GetActiveFaqs
  final CreateFaq createFaq;
  final UpdateFaq updateFaq;
  final DeleteFaq deleteFaq;
  final ToggleFaqStatus toggleFaqStatus;

  AdminFaqBloc({
    required this.getAllFaqs, // ✅ Changed
    required this.createFaq,
    required this.updateFaq,
    required this.deleteFaq,
    required this.toggleFaqStatus,
  }) : super(AdminFaqInitial()) {
    on<LoadAllFaqsEvent>(_onLoadAllFaqs);
    on<CreateFaqEvent>(_onCreateFaq);
    on<UpdateFaqEvent>(_onUpdateFaq);
    on<DeleteFaqEvent>(_onDeleteFaq);
    on<ToggleFaqStatusEvent>(_onToggleFaqStatus);
    on<SearchFaqsEvent>(_onSearchFaqs);
  }

  Future<void> _onLoadAllFaqs(
    LoadAllFaqsEvent event,
    Emitter<AdminFaqState> emit,
  ) async {
    emit(AdminFaqsLoading());

    // ✅ Use getAllFaqs instead of getActiveFaqs
    final result = await getAllFaqs(const NoParams());

    result.fold((failure) => emit(AdminFaqError(failure.message)), (faqs) {
      final filteredFaqs =
          event.searchQuery != null && event.searchQuery!.isNotEmpty
          ? faqs.where((faq) {
              final query = event.searchQuery!.toLowerCase();
              return faq.question.toLowerCase().contains(query) ||
                  faq.answer.toLowerCase().contains(query) ||
                  (faq.category?.toLowerCase().contains(query) ?? false);
            }).toList()
          : faqs;

      emit(
        AdminFaqsLoaded(
          faqs: faqs,
          filteredFaqs: filteredFaqs,
          searchQuery: event.searchQuery,
        ),
      );
    });
  }

  Future<void> _onCreateFaq(
    CreateFaqEvent event,
    Emitter<AdminFaqState> emit,
  ) async {
    emit(AdminFaqOperationLoading());
    final result = await createFaq(CreateFaqParams(faqData: event.faqData));
    result.fold((failure) => emit(AdminFaqError(failure.message)), (faq) {
      emit(const AdminFaqOperationSuccess('FAQ created successfully'));
      add(const LoadAllFaqsEvent());
    });
  }

  Future<void> _onUpdateFaq(
    UpdateFaqEvent event,
    Emitter<AdminFaqState> emit,
  ) async {
    emit(AdminFaqOperationLoading());
    final result = await updateFaq(
      UpdateFaqParams(id: event.id, faqData: event.faqData),
    );
    result.fold((failure) => emit(AdminFaqError(failure.message)), (faq) {
      emit(const AdminFaqOperationSuccess('FAQ updated successfully'));
      add(const LoadAllFaqsEvent());
    });
  }

  Future<void> _onDeleteFaq(
    DeleteFaqEvent event,
    Emitter<AdminFaqState> emit,
  ) async {
    emit(AdminFaqOperationLoading());
    final result = await deleteFaq(DeleteFaqParams(id: event.id));
    result.fold((failure) => emit(AdminFaqError(failure.message)), (_) {
      emit(const AdminFaqOperationSuccess('FAQ deleted successfully'));
      add(const LoadAllFaqsEvent());
    });
  }

  Future<void> _onToggleFaqStatus(
    ToggleFaqStatusEvent event,
    Emitter<AdminFaqState> emit,
  ) async {
    emit(AdminFaqOperationLoading()); // ✅ Added loading state

    final result = await toggleFaqStatus(ToggleFaqStatusParams(id: event.id));

    result.fold(
      (failure) {
        emit(AdminFaqError(failure.message));
      },
      (faq) {
        emit(
          AdminFaqOperationSuccess(
            'FAQ ${faq.isActive ? 'activated' : 'deactivated'} successfully',
          ),
        );
        // ✅ Reload all FAQs to update the list
        add(const LoadAllFaqsEvent());
      },
    );
  }

  Future<void> _onSearchFaqs(
    SearchFaqsEvent event,
    Emitter<AdminFaqState> emit,
  ) async {
    if (state is AdminFaqsLoaded) {
      final currentState = state as AdminFaqsLoaded;
      final filteredFaqs = event.query.isEmpty
          ? currentState.faqs
          : currentState.faqs.where((faq) {
              final query = event.query.toLowerCase();
              return faq.question.toLowerCase().contains(query) ||
                  faq.answer.toLowerCase().contains(query) ||
                  (faq.category?.toLowerCase().contains(query) ?? false);
            }).toList();

      emit(
        currentState.copyWith(
          filteredFaqs: filteredFaqs,
          searchQuery: event.query,
        ),
      );
    }
  }
}

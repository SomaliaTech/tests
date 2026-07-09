import 'package:equatable/equatable.dart';
import 'package:mobile/features/support/domain/entities/faq.dart';

abstract class AdminFaqState extends Equatable {
  const AdminFaqState();

  @override
  List<Object?> get props => [];
}

class AdminFaqInitial extends AdminFaqState {}

class AdminFaqsLoading extends AdminFaqState {}

class AdminFaqsLoaded extends AdminFaqState {
  final List<Faq> faqs;
  final List<Faq> filteredFaqs;
  final String? searchQuery;

  const AdminFaqsLoaded({
    required this.faqs,
    required this.filteredFaqs,
    this.searchQuery,
  });

  AdminFaqsLoaded copyWith({
    List<Faq>? faqs,
    List<Faq>? filteredFaqs,
    String? searchQuery,
  }) {
    return AdminFaqsLoaded(
      faqs: faqs ?? this.faqs,
      filteredFaqs: filteredFaqs ?? this.filteredFaqs,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [faqs, filteredFaqs, searchQuery];
}

class AdminFaqOperationLoading extends AdminFaqState {}

class AdminFaqOperationSuccess extends AdminFaqState {
  final String message;
  const AdminFaqOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminFaqError extends AdminFaqState {
  final String message;
  const AdminFaqError(this.message);

  @override
  List<Object?> get props => [message];
}

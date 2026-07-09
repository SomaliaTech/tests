import 'package:equatable/equatable.dart';
import 'package:mobile/features/support/domain/entities/faq.dart';

abstract class FaqState extends Equatable {
  const FaqState();

  @override
  List<Object?> get props => [];
}

class FaqInitial extends FaqState {}

class FaqsLoading extends FaqState {}

class FaqsLoaded extends FaqState {
  final List<Faq> faqs;
  const FaqsLoaded(this.faqs);

  @override
  List<Object?> get props => [faqs];
}

class FaqOperationLoading extends FaqState {}

class FaqOperationSuccess extends FaqState {
  final String message;
  const FaqOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class FaqError extends FaqState {
  final String message;
  const FaqError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';

abstract class FaqEvent extends Equatable {
  const FaqEvent();

  @override
  List<Object?> get props => [];
}

class LoadActiveFaqsEvent extends FaqEvent {
  const LoadActiveFaqsEvent();
}

class LoadAllFaqsEvent extends FaqEvent {
  const LoadAllFaqsEvent();
}

class CreateFaqEvent extends FaqEvent {
  final Map<String, dynamic> faqData;
  const CreateFaqEvent({required this.faqData});

  @override
  List<Object?> get props => [faqData];
}

class UpdateFaqEvent extends FaqEvent {
  final String id;
  final Map<String, dynamic> faqData;
  const UpdateFaqEvent({required this.id, required this.faqData});

  @override
  List<Object?> get props => [id, faqData];
}

class DeleteFaqEvent extends FaqEvent {
  final String id;
  const DeleteFaqEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class ToggleFaqStatusEvent extends FaqEvent {
  final String id;
  const ToggleFaqStatusEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

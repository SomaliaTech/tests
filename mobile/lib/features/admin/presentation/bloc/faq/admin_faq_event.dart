import 'package:equatable/equatable.dart';

abstract class AdminFaqEvent extends Equatable {
  const AdminFaqEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllFaqsEvent extends AdminFaqEvent {
  final String? searchQuery; // ✅ Changed from 'search' to 'searchQuery'
  const LoadAllFaqsEvent({this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}

class CreateFaqEvent extends AdminFaqEvent {
  final Map<String, dynamic> faqData;
  const CreateFaqEvent({required this.faqData});

  @override
  List<Object?> get props => [faqData];
}

class UpdateFaqEvent extends AdminFaqEvent {
  final String id;
  final Map<String, dynamic> faqData;
  const UpdateFaqEvent({required this.id, required this.faqData});

  @override
  List<Object?> get props => [id, faqData];
}

class DeleteFaqEvent extends AdminFaqEvent {
  final String id;
  const DeleteFaqEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class ToggleFaqStatusEvent extends AdminFaqEvent {
  final String id;
  const ToggleFaqStatusEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class SearchFaqsEvent extends AdminFaqEvent {
  final String query;
  const SearchFaqsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

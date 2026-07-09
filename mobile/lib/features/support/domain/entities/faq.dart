import 'package:equatable/equatable.dart';

class Faq extends Equatable {
  final String id;
  final String question;
  final String answer;
  final String? category;
  final int order;
  final bool isActive; // ✅ Must exist

  const Faq({
    required this.id,
    required this.question,
    required this.answer,
    this.category,
    required this.order,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, question, answer, category, order, isActive];
}

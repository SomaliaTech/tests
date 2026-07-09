import 'package:mobile/features/support/domain/entities/faq.dart';

class FaqModel extends Faq {
  const FaqModel({
    required super.id,
    required super.question,
    required super.answer,
    super.category,
    required super.order,
    super.isActive,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String?,
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true, // ✅ Added
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'order': order,
      'isActive': isActive, // ✅ Added
    };
  }

  Faq toEntity() {
    return Faq(
      id: id,
      question: question,
      answer: answer,
      category: category,
      order: order,
      isActive: isActive, // ✅ Added
    );
  }
}

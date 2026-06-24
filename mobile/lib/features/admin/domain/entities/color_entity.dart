import 'package:equatable/equatable.dart';

class ColorEntity extends Equatable {
  final String id;
  final String name;
  final String code;

  const ColorEntity({required this.id, required this.name, required this.code});

  @override
  List<Object?> get props => [id, name, code];
}

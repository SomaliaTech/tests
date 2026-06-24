import 'package:equatable/equatable.dart';

class SizeEntity extends Equatable {
  final String id;
  final String name;
  final String value;

  const SizeEntity({required this.id, required this.name, required this.value});

  @override
  List<Object?> get props => [id, name, value];
}

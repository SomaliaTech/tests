import 'package:equatable/equatable.dart';

class ChartDataEntity extends Equatable {
  final String date;
  final double value;
  final int count;

  const ChartDataEntity({
    required this.date,
    required this.value,
    required this.count,
  });

  @override
  List<Object?> get props => [date, value, count];
}

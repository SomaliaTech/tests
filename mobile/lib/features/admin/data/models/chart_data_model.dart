import 'package:mobile/features/admin/domain/entities/chart_data_entity.dart';

class ChartDataModel {
  final String date;
  final double value;
  final int count;

  ChartDataModel({
    required this.date,
    required this.value,
    required this.count,
  });

  factory ChartDataModel.fromJson(Map<String, dynamic> json) {
    return ChartDataModel(
      date: json['date'] ?? '',
      value: (json['value'] ?? json['revenue'] ?? json['users'] ?? 0)
          .toDouble(),
      count: json['count'] ?? json['orders'] ?? json['users'] ?? 0,
    );
  }

  ChartDataEntity toEntity() {
    return ChartDataEntity(date: date, value: value, count: count);
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'value': value, 'count': count};
  }
}

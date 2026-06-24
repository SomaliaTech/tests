import 'package:equatable/equatable.dart';

enum Market { mogadishu, hargeisa, jowhar }

extension MarketExtension on Market {
  String get displayName {
    switch (this) {
      case Market.mogadishu:
        return 'Mogadishu';
      case Market.hargeisa:
        return 'Hargeisa';
      case Market.jowhar:
        return 'Jowhar';
    }
  }
}

class ProfileData extends Equatable {
  final String name;
  final String phone;
  final Market? market;
  final String? profileImage;
  final int points;

  const ProfileData({
    required this.name,
    required this.phone,
    this.market,
    this.profileImage,
    this.points = 0,
  });

  ProfileData copyWith({
    String? name,
    String? phone,
    Market? market,
    String? profileImage,
    int? points,
  }) {
    return ProfileData(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      market: market ?? this.market,
      profileImage: profileImage ?? this.profileImage,
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [name, phone, market, profileImage, points];
}

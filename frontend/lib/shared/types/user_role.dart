import '../../core/constants/brand_assets.dart';

enum UserRole { buyer, producer }

extension UserRoleText on UserRole {
  String get companyName => switch (this) {
    UserRole.buyer => 'Alıcı',
    UserRole.producer => 'Üretici',
  };

  String get panelName => switch (this) {
    UserRole.buyer => 'Alıcı Paneli',
    UserRole.producer => 'Üretici Paneli',
  };

  String get logoAsset => switch (this) {
    UserRole.buyer => BrandAssets.buyerLogo,
    UserRole.producer => BrandAssets.producerLogo,
  };

  String get logoFallbackLabel => switch (this) {
    UserRole.buyer => 'Alıcı',
    UserRole.producer => 'Üretici',
  };
}

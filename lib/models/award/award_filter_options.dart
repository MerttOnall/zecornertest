/// Web `zeonline/rewards` filtre tanımları (Next.js bundle ile birebir).
class AwardFilterConfig {
  final String label;
  final String groupBy;
  final String? listingType;
  final List<int>? contactTypes;

  const AwardFilterConfig({
    required this.label,
    required this.groupBy,
    this.listingType,
    this.contactTypes,
  });
}

class AwardFilterOptions {
  AwardFilterOptions._();

  static const String defaultTitle = 'Konut + Ticari - Tüm Ofisler';

  static const List<AwardFilterConfig> configs = [
    AwardFilterConfig(
      label: defaultTitle,
      groupBy: 'office',
    ),
    AwardFilterConfig(
      label: 'Konut + Ticari - Saha Direktörleri, Brokerlar, Danışmanlar',
      groupBy: 'contact',
      contactTypes: [10, 11, 19],
    ),
    AwardFilterConfig(
      label: 'Konut + Ticari - Sadece Danışmanlar',
      groupBy: 'contact',
      contactTypes: [11],
    ),
    AwardFilterConfig(
      label: 'Konut - Tüm Ofisler',
      groupBy: 'office',
      listingType: 'konut',
    ),
    AwardFilterConfig(
      label: 'Konut - Saha Direktörleri, Brokerlar, Danışmanlar',
      groupBy: 'contact',
      listingType: 'konut',
      contactTypes: [10, 11, 19],
    ),
    AwardFilterConfig(
      label: 'Konut - Sadece Danışmanlar',
      groupBy: 'contact',
      listingType: 'konut',
      contactTypes: [11],
    ),
    AwardFilterConfig(
      label: 'Ticari - Tüm Ofisler',
      groupBy: 'office',
      listingType: 'is-yeri',
    ),
    AwardFilterConfig(
      label: 'Ticari - Saha Direktörleri, Brokerlar, Danışmanlar',
      groupBy: 'contact',
      listingType: 'is-yeri',
      contactTypes: [10, 11, 19],
    ),
    AwardFilterConfig(
      label: 'Ticari - Sadece Danışmanlar',
      groupBy: 'contact',
      listingType: 'is-yeri',
      contactTypes: [11],
    ),
  ];

  static List<String> get titles =>
      configs.map((config) => config.label).toList(growable: false);

  static AwardFilterConfig resolve(String? selectedTitle) {
    final title = selectedTitle ?? defaultTitle;
    for (final config in configs) {
      if (config.label == title) return config;
    }
    return configs.first;
  }
}

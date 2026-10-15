class CategoryListingType {
  final String id;
  final String refCategory;
  final String listingType;
  final String label;

  CategoryListingType({
    required this.id,
    required this.refCategory,
    required this.listingType,
    required this.label,
  });

  factory CategoryListingType.fromJson(Map<String, dynamic> json) {
    return CategoryListingType(
      id: json['id'] ?? '',
      refCategory: json['ref_category'] ?? '',
      listingType: json['listing_type'] ?? '',
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ref_category': refCategory,
      'listing_type': listingType,
      'label': label,
    };
  }
}

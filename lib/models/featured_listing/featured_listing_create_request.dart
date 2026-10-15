class FeaturedListingCreateRequest {
  final String listingId;
  final String startDate;
  final String endDate;
  final int position;

  FeaturedListingCreateRequest({
    required this.listingId,
    required this.startDate,
    required this.endDate,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      'listing_id': listingId,
      'start_date': startDate,
      'end_date': endDate,
      'position': position,
    };
  }
}


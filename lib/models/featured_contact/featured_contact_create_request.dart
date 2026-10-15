class FeaturedContactCreateRequest {
  final int contactNo;
  final String startDate; // Format: "2025-03-31T21:00:00.000Z"
  final String endDate;   // Format: "2025-04-30T21:00:00.000Z"
  final int position;

  FeaturedContactCreateRequest({
    required this.contactNo,
    required this.startDate,
    required this.endDate,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      'contact_no': contactNo,
      'start_date': startDate,
      'end_date': endDate,
      'position': position,
    };
  }

  /// Helper to create from DateTime objects
  factory FeaturedContactCreateRequest.fromDateTimes({
    required int contactNo,
    required DateTime startDate,
    required DateTime endDate,
    required int position,
  }) {
    return FeaturedContactCreateRequest(
      contactNo: contactNo,
      startDate: startDate.toUtc().toIso8601String(),
      endDate: endDate.toUtc().toIso8601String(),
      position: position,
    );
  }
}


import 'listing_model.dart';

class ListingsResponseModel {
  final List<ListingModel> listings;
  final int totalCount;
  final int totalPages;
  final int page;
  /// Aynı endpoint bazen team_members da döner (get-office-listings)
  final List<Map<String, dynamic>> teamMembers;

  ListingsResponseModel({
    required this.listings,
    required this.totalCount,
    required this.totalPages,
    required this.page,
    this.teamMembers = const [],
  });

  factory ListingsResponseModel.fromJson(Map<String, dynamic> json) {
    print('🔍 ListingsResponseModel.fromJson çağrıldı');
    print('📋 JSON keys: ${json.keys.toList()}');
    
    List<ListingModel> listingsList = [];
    
    if (json['listings'] != null) {
      print('📝 Listings field bulundu, parse ediliyor...');
      try {
        final listingsData = json['listings'] as List;
        print('📊 Listings count: ${listingsData.length}');
        
        listingsList = listingsData
            .map((item) => ListingModel.fromJson(item as Map<String, dynamic>))
            .toList();
        print('✅ ${listingsList.length} ilan başarıyla parse edildi');
      } catch (e) {
        print('❌ Listings parse hatası: $e');
      }
    } else {
      print('⚠️ Listings field null');
    }

    List<Map<String, dynamic>> teamMembersList = [];
    if (json['team_members'] != null && json['team_members'] is List) {
      teamMembersList = (json['team_members'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }

    final result = ListingsResponseModel(
      listings: listingsList,
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 1,
      teamMembers: teamMembersList,
    );
    
    print('🎉 ListingsResponseModel oluşturuldu: ${result.listings.length} ilan, ${result.teamMembers.length} ekip');
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'listings': listings.map((listing) => listing.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }

  List<Object?> get props => [listings, totalCount, totalPages, page, teamMembers];
}

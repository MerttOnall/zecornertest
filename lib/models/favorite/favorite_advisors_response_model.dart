import 'favorite_advisor_model.dart';

class FavoriteAdvisorsResponseModel {
  final List<FavoriteAdvisorModel> advisors;
  final int totalCount;
  final int totalPages;
  final int page;

  FavoriteAdvisorsResponseModel({
    required this.advisors,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory FavoriteAdvisorsResponseModel.fromJson(Map<String, dynamic> json) {
    List<FavoriteAdvisorModel> list = [];
    if (json['advisors'] != null && json['advisors'] is List) {
      list = (json['advisors'] as List)
          .map((e) => FavoriteAdvisorModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    String safeStr(dynamic v) => v?.toString() ?? '';
    int safeInt(dynamic v) =>
        v is int ? v : (int.tryParse(v?.toString() ?? '0') ?? 0);
    return FavoriteAdvisorsResponseModel(
      advisors: list,
      totalCount: safeInt(json['totalCount']),
      totalPages: safeInt(json['totalPages']),
      page: safeInt(json['page']),
    );
  }
}

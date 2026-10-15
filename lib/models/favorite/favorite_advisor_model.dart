/// Favori danışman (GET /favorite/advisors) tek bir advisor objesi.
class FavoriteAdvisorModel {
  final int contactNo;
  final String title;
  final String name;
  final String surname;
  final int type;
  final String? typeDescription;
  final String? eMail;
  final String? tel;
  final String? picture;
  final String? slug;
  final int? connectedContact;
  final String? connectedContactTitle;
  final String? professionDescription;
  final String? provinceName;
  final String? districtName;
  final String? quarterName;

  FavoriteAdvisorModel({
    required this.contactNo,
    required this.title,
    required this.name,
    required this.surname,
    required this.type,
    this.typeDescription,
    this.eMail,
    this.tel,
    this.picture,
    this.slug,
    this.connectedContact,
    this.connectedContactTitle,
    this.professionDescription,
    this.provinceName,
    this.districtName,
    this.quarterName,
  });

  String get displayName => title.isNotEmpty ? title : '$name $surname'.trim();
  bool get isZecornerCadde =>
      connectedContactTitle != null && connectedContactTitle!.isNotEmpty;

  factory FavoriteAdvisorModel.fromJson(Map<String, dynamic> json) {
    String safeStr(dynamic v) => v?.toString() ?? '';
    int safeInt(dynamic v) =>
        v is int ? v : (int.tryParse(v?.toString() ?? '0') ?? 0);

    return FavoriteAdvisorModel(
      contactNo: safeInt(json['contact_no']),
      title: safeStr(json['title']),
      name: safeStr(json['name']),
      surname: safeStr(json['surname']),
      type: safeInt(json['type']),
      typeDescription: json['type_description']?.toString(),
      eMail: json['e_mail']?.toString(),
      tel: json['tel']?.toString(),
      picture: json['picture']?.toString(),
      slug: json['slug']?.toString(),
      connectedContact: json['connected_contact'] != null
          ? safeInt(json['connected_contact'])
          : null,
      connectedContactTitle: json['connected_contact_title']?.toString(),
      professionDescription: json['profession_description']?.toString(),
      provinceName: json['province_name']?.toString(),
      districtName: json['district_name']?.toString(),
      quarterName: json['quarter_name']?.toString(),
    );
  }
}

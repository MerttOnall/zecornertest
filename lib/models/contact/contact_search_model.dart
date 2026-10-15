class ContactSearchModel {
  final int contactNo;
  final String title;
  final String? picture;
  final String typeDescription;
  final String email;

  ContactSearchModel({
    required this.contactNo,
    required this.title,
    this.picture,
    required this.typeDescription,
    required this.email,
  });

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  static String _asString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  factory ContactSearchModel.fromJson(Map<String, dynamic> json) {
    // assignables / contact-info: contact_no | no | id | contact
    final contactNo = _asInt(
      json['contact_no'] ??
          json['no'] ??
          json['id'] ??
          json['contact'] ??
          json['related_contact'] ??
          json['related_contact_no'],
    );

    final nameParts = [
      json['name'],
      json['surname'],
      json['related_contact_name'],
      json['related_contact_surname'],
    ]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString().trim())
        .toList();

    final title = _asString(json['title']).isNotEmpty
        ? _asString(json['title'])
        : (nameParts.isNotEmpty ? nameParts.join(' ') : 'Kişi #$contactNo');

    final pictureRaw = _asString(json['picture']).isNotEmpty
        ? _asString(json['picture'])
        : _asString(json['related_contact_picture']);

    return ContactSearchModel(
      contactNo: contactNo,
      title: title,
      picture: pictureRaw.isEmpty ? null : pictureRaw,
      typeDescription: _asString(
        json['type_description'] ??
            json['related_contact_type_description'] ??
            json['role'] ??
            json['title_role'],
      ),
      email: _asString(
        json['e_mail'] ??
            json['email'] ??
            json['related_contact_e_mail'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_no': contactNo,
      'title': title,
      'picture': picture,
      'type_description': typeDescription,
      'e_mail': email,
    };
  }

  @override
  String toString() {
    return 'ContactSearchModel(contactNo: $contactNo, title: $title, typeDescription: $typeDescription, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactSearchModel && other.contactNo == contactNo;
  }

  @override
  int get hashCode => contactNo.hashCode;
}

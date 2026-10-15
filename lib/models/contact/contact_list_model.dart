class ContactListModel {
  final int contactNo;
  final String title;
  final String? picture;
  final String typeDescription;
  final String eMail;

  ContactListModel({
    required this.contactNo,
    required this.title,
    this.picture,
    required this.typeDescription,
    required this.eMail,
  });

  factory ContactListModel.fromJson(Map<String, dynamic> json) {
    return ContactListModel(
      contactNo: json['contact_no'] ?? 0,
      title: json['title'] ?? '',
      picture: json['picture'],
      typeDescription: json['type_description'] ?? '',
      eMail: json['e_mail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_no': contactNo,
      'title': title,
      'picture': picture,
      'type_description': typeDescription,
      'e_mail': eMail,
    };
  }
}


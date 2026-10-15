class FeaturedContactModel {
  final int id;
  final String startDate;
  final String endDate;
  final int position;
  final int status;
  final int contactNo;
  final String title;
  final int type;
  final String typeDescription;
  final String eMail;
  final String tel;
  final String? picutre; // Typo in API
  final SocialMedia? socialMedia;
  final int? connectedContact;
  final String? connectedContactTitle;
  final int? sectoralExperience;
  final int? rating;
  final String? portfolioCount;

  FeaturedContactModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.position,
    required this.status,
    required this.contactNo,
    required this.title,
    required this.type,
    required this.typeDescription,
    required this.eMail,
    required this.tel,
    this.picutre,
    this.socialMedia,
    this.connectedContact,
    this.connectedContactTitle,
    this.sectoralExperience,
    this.rating,
    this.portfolioCount,
  });

  factory FeaturedContactModel.fromJson(Map<String, dynamic> json) {
    return FeaturedContactModel(
      id: json['id'] ?? 0,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      position: json['position'] ?? 0,
      status: json['status'] ?? 0,
      contactNo: json['contact_no'] ?? 0,
      title: json['title'] ?? '',
      type: json['type'] ?? 0,
      typeDescription: json['type_description'] ?? '',
      eMail: json['e_mail'] ?? '',
      tel: json['tel'] ?? '',
      picutre: json['picutre'],
      socialMedia: json['social_media'] != null
          ? SocialMedia.fromJson(json['social_media'])
          : null,
      connectedContact: json['connected_contact'],
      connectedContactTitle: json['connected_contact_title'],
      sectoralExperience: json['sectoral_experience'],
      rating: json['rating'],
      portfolioCount: json['portfolio_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_date': startDate,
      'end_date': endDate,
      'position': position,
      'status': status,
      'contact_no': contactNo,
      'title': title,
      'type': type,
      'type_description': typeDescription,
      'e_mail': eMail,
      'tel': tel,
      'picutre': picutre,
      'social_media': socialMedia?.toJson(),
      'connected_contact': connectedContact,
      'connected_contact_title': connectedContactTitle,
      'sectoral_experience': sectoralExperience,
      'rating': rating,
      'portfolio_count': portfolioCount,
    };
  }
}

class SocialMedia {
  final String? linkedin;
  final String? x;
  final String? instagram;
  final String? facebook;

  SocialMedia({
    this.linkedin,
    this.x,
    this.instagram,
    this.facebook,
  });

  factory SocialMedia.fromJson(Map<String, dynamic> json) {
    return SocialMedia(
      linkedin: json['linkedin'],
      x: json['x'],
      instagram: json['instagram'],
      facebook: json['facebook'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'linkedin': linkedin,
      'x': x,
      'instagram': instagram,
      'facebook': facebook,
    };
  }
}

class FeaturedContactResponse {
  final List<FeaturedContactModel> featuredContacts;
  final int totalCount;
  final int totalPages;
  final int page;

  FeaturedContactResponse({
    required this.featuredContacts,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory FeaturedContactResponse.fromJson(Map<String, dynamic> json) {
    final contacts = (json['featured_contacts'] as List)
        .map((e) => FeaturedContactModel.fromJson(e))
        .toList();
    return FeaturedContactResponse(
      featuredContacts: contacts,
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 0,
    );
  }
}


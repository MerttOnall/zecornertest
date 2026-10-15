class ContactCreateModel {
  final String name;
  final String surname;
  final String phone;
  final String email;
  final String? tcId;
  final String? birthDate;
  final String? gender;
  final String? personType;
  final String? profession;
  final String? education;
  final String? experience;
  final String? city;
  final String? district;
  final String? neighborhood;
  final String? address;
  final String? instagram;
  final String? facebook;
  final String? twitter;
  final String? linkedin;
  final String? whereYouHeardUs;
  final String? coverLetter;
  final String? references;
  final String? picture;
  final List<Map<String, dynamic>>? attachments;

  ContactCreateModel({
    required this.name,
    required this.surname,
    required this.phone,
    required this.email,
    this.tcId,
    this.birthDate,
    this.gender,
    this.personType,
    this.profession,
    this.education,
    this.experience,
    this.city,
    this.district,
    this.neighborhood,
    this.address,
    this.instagram,
    this.facebook,
    this.twitter,
    this.linkedin,
    this.whereYouHeardUs,
    this.coverLetter,
    this.references,
    this.picture,
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surname': surname,
      'phone': phone,
      'email': email,
      'tcId': tcId,
      'birthDate': birthDate,
      'gender': gender,
      'personType': personType,
      'profession': profession,
      'education': education,
      'experience': experience,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'address': address,
      'instagram': instagram,
      'facebook': facebook,
      'twitter': twitter,
      'linkedin': linkedin,
      'whereYouHeardUs': whereYouHeardUs,
      'coverLetter': coverLetter,
      'references': references,
      'picture': picture,
      'attachments': attachments,
    };
  }

  factory ContactCreateModel.fromJson(Map<String, dynamic> json) {
    return ContactCreateModel(
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      tcId: json['tcId'],
      birthDate: json['birthDate'],
      gender: json['gender'],
      personType: json['personType'],
      profession: json['profession'],
      education: json['education'],
      experience: json['experience'],
      city: json['city'],
      district: json['district'],
      neighborhood: json['neighborhood'],
      address: json['address'],
      instagram: json['instagram'],
      facebook: json['facebook'],
      twitter: json['twitter'],
      linkedin: json['linkedin'],
      whereYouHeardUs: json['whereYouHeardUs'],
      coverLetter: json['coverLetter'],
      references: json['references'],
      picture: json['picture'],
      attachments: json['attachments'] != null 
          ? List<Map<String, dynamic>>.from(json['attachments'])
          : null,
    );
  }
}

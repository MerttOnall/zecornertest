import 'package:zecorner/core/interfaces/form_model_interface.dart';
import 'package:zecorner/core/value_objects/string_field.dart';

class PersonEditFormModel implements IFormModel {
  final StringField firstName;
  final StringField lastName;
  final StringField email;
  final StringField phone;
  final StringField tcNumber;
  final StringField birthDate;
  final StringField address;
  final StringField experience;
  final StringField instagram;
  final StringField facebook;
  final StringField twitter;
  final StringField linkedin;
  final StringField connectedPerson;
  final StringField pastExperience;
  final StringField coverLetter;
  final StringField references;
  final StringField companyInfo;
  final String? selectedPersonType;
  final String? selectedConsultantLevel;
  final String? selectedProfession;
  final String? selectedEducation;
  final String? selectedCity;
  final String? selectedDistrict;
  final String? selectedNeighborhood;
  final bool isActive;
  final bool campaignConsent;
  final bool isCustomConsultant;

  PersonEditFormModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.tcNumber,
    required this.birthDate,
    required this.address,
    required this.experience,
    required this.instagram,
    required this.facebook,
    required this.twitter,
    required this.linkedin,
    required this.connectedPerson,
    required this.pastExperience,
    required this.coverLetter,
    required this.references,
    required this.companyInfo,
    required this.selectedPersonType,
    required this.selectedConsultantLevel,
    required this.selectedProfession,
    required this.selectedEducation,
    required this.selectedCity,
    required this.selectedDistrict,
    required this.selectedNeighborhood,
    required this.isActive,
    required this.campaignConsent,
    required this.isCustomConsultant,
  });

  factory PersonEditFormModel.empty() => PersonEditFormModel(
        firstName: StringField(''),
        lastName: StringField(''),
        email: StringField(''),
        phone: StringField(''),
        tcNumber: StringField(''),
        birthDate: StringField(''),
        address: StringField(''),
        experience: StringField(''),
        instagram: StringField(''),
        facebook: StringField(''),
        twitter: StringField(''),
        linkedin: StringField(''),
        connectedPerson: StringField(''),
        pastExperience: StringField(''),
        coverLetter: StringField(''),
        references: StringField(''),
        companyInfo: StringField(''),
        selectedPersonType: 'Müşteri',
        selectedConsultantLevel: null,
        selectedProfession: 'Diğer',
        selectedEducation: 'Üniversite',
        selectedCity: 'İstanbul',
        selectedDistrict: 'Beşiktaş',
        selectedNeighborhood: 'Mahalle Adı',
        isActive: true,
        campaignConsent: true,
        isCustomConsultant: false,
      );

  PersonEditFormModel copyWith({
    StringField? firstName,
    StringField? lastName,
    StringField? email,
    StringField? phone,
    StringField? tcNumber,
    StringField? birthDate,
    StringField? address,
    StringField? experience,
    StringField? instagram,
    StringField? facebook,
    StringField? twitter,
    StringField? linkedin,
    StringField? connectedPerson,
    StringField? pastExperience,
    StringField? coverLetter,
    StringField? references,
    StringField? companyInfo,
    String? selectedPersonType,
    String? selectedConsultantLevel,
    String? selectedProfession,
    String? selectedEducation,
    String? selectedCity,
    String? selectedDistrict,
    String? selectedNeighborhood,
    bool? isActive,
    bool? campaignConsent,
    bool? isCustomConsultant,
  }) {
    return PersonEditFormModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      tcNumber: tcNumber ?? this.tcNumber,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      experience: experience ?? this.experience,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
      connectedPerson: connectedPerson ?? this.connectedPerson,
      pastExperience: pastExperience ?? this.pastExperience,
      coverLetter: coverLetter ?? this.coverLetter,
      references: references ?? this.references,
      companyInfo: companyInfo ?? this.companyInfo,
      selectedPersonType: selectedPersonType ?? this.selectedPersonType,
      selectedConsultantLevel: selectedConsultantLevel ?? this.selectedConsultantLevel,
      selectedProfession: selectedProfession ?? this.selectedProfession,
      selectedEducation: selectedEducation ?? this.selectedEducation,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedNeighborhood: selectedNeighborhood ?? this.selectedNeighborhood,
      isActive: isActive ?? this.isActive,
      campaignConsent: campaignConsent ?? this.campaignConsent,
      isCustomConsultant: isCustomConsultant ?? this.isCustomConsultant,
    );
  }

  @override
  bool isValid() {
    return firstName.value.isNotEmpty && 
           lastName.value.isNotEmpty && 
           email.value.isNotEmpty && 
           phone.value.isNotEmpty;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName.value,
      'lastName': lastName.value,
      'email': email.value,
      'phone': phone.value,
      'tcNumber': tcNumber.value,
      'birthDate': birthDate.value,
      'address': address.value,
      'experience': experience.value,
      'instagram': instagram.value,
      'facebook': facebook.value,
      'twitter': twitter.value,
      'linkedin': linkedin.value,
      'connectedPerson': connectedPerson.value,
      'pastExperience': pastExperience.value,
      'coverLetter': coverLetter.value,
      'references': references.value,
      'companyInfo': companyInfo.value,
      'selectedPersonType': selectedPersonType,
      'selectedConsultantLevel': selectedConsultantLevel,
      'selectedProfession': selectedProfession,
      'selectedEducation': selectedEducation,
      'selectedCity': selectedCity,
      'selectedDistrict': selectedDistrict,
      'selectedNeighborhood': selectedNeighborhood,
      'isActive': isActive,
      'campaignConsent': campaignConsent,
      'isCustomConsultant': isCustomConsultant,
    };
  }

  @override
  String getErrorMessage() {
    if (firstName.value.isEmpty) {
      return 'Ad alanı zorunludur.';
    }
    if (lastName.value.isEmpty) {
      return 'Soyad alanı zorunludur.';
    }
    if (email.value.isEmpty) {
      return 'E-posta alanı zorunludur.';
    }
    if (phone.value.isEmpty) {
      return 'Telefon alanı zorunludur.';
    }
    return 'Formda eksik veya hatalı alanlar var.';
  }
}

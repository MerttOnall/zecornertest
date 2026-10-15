import 'package:zecorner/core/interfaces/form_model_interface.dart';
import 'package:zecorner/core/value_objects/string_field.dart';

class UserEditFormModel implements IFormModel {
  final StringField firstName;
  final StringField lastName;
  final StringField email;
  final StringField phone;
  final List<String> selectedRoles;
  final bool isActive;

  UserEditFormModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.selectedRoles,
    required this.isActive,
  });

  factory UserEditFormModel.empty() {
    return UserEditFormModel(
      firstName: StringField(''),
      lastName: StringField(''),
      email: StringField(''),
      phone: StringField(''),
      selectedRoles: [],
      isActive: true,
    );
  }

  factory UserEditFormModel.fromUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required List<String> roles,
    required bool isActive,
  }) {
    return UserEditFormModel(
      firstName: StringField(firstName),
      lastName: StringField(lastName),
      email: StringField(email),
      phone: StringField(phone),
      selectedRoles: roles,
      isActive: isActive,
    );
  }

  @override
  bool isValid() {
    // Kişisel bilgiler ve iletişim bilgileri sadece okunabilir olduğu için
    // sadece roller kontrol ediliyor
    return selectedRoles.isNotEmpty;
  }

  @override
  String? getErrorMessage() {
    if (selectedRoles.isEmpty) {
      return 'Lütfen en az bir rol seçin';
    }
    return null;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'roles': selectedRoles,
    };
  }

  UserEditFormModel copyWith({
    StringField? firstName,
    StringField? lastName,
    StringField? email,
    StringField? phone,
    List<String>? selectedRoles,
    bool? isActive,
  }) {
    return UserEditFormModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      selectedRoles: selectedRoles ?? this.selectedRoles,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// [EditUserScreen] için route argümanları.
class EditUserArgs {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String userNumber;
  final String role;
  final bool isActive;

  const EditUserArgs({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.userNumber,
    required this.role,
    required this.isActive,
  });

  String get fullName => '$firstName $lastName';
}

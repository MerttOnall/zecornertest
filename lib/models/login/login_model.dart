import 'package:dartz/dartz.dart';

class LoginAuthentication {
  final ValueNotNull<String> email;
  final ValueNotNull<String> password;

  LoginAuthentication({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email.getOrCrash(),
      'password': password.getOrCrash(),
    };
  }
}

class ValueNotNull<T> {
  final T _value;

  ValueNotNull(this._value);

  T getOrCrash() => _value;

  @override
  String toString() => _value.toString();
} 
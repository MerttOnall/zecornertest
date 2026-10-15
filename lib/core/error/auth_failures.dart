import '../error/failures.dart';

abstract class IAuthFailure extends Failure {
  const IAuthFailure({required String message, int? statusCode}) 
      : super(message: message, statusCode: statusCode);
}

class LoginAuthFailure extends IAuthFailure {
  const LoginAuthFailure({required String errorMessage}) 
      : super(message: errorMessage);
} 
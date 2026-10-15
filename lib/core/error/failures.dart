import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
  }) : super(message: message);
}

class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
  }) : super(message: message);
}

class ParseFailure extends Failure {
  const ParseFailure({
    required String message,
  }) : super(message: message);
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    required String message,
  }) : super(message: message);
} 
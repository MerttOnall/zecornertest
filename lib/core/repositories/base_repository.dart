import '../network/dio_client.dart';
import '../error/failures.dart';
import '../utils/either.dart';

mixin BaseRepository {
  DioClient get dioClient => DioClient();

  // Helper method for handling common API operations
  Future<Either<Failure, T>> handleApiCall<T>(
    Future<Either<Failure, T>> Function() apiCall,
  ) async {
    try {
      return await apiCall();
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // Helper method for transforming data
  Either<Failure, List<T>> transformList<T>(
    Either<Failure, dynamic> result,
    T Function(dynamic) fromJson,
  ) {
    return result.fold(
      (failure) => Left(failure),
      (data) {
        try {
          if (data is List) {
            final items = data.map((item) => fromJson(item)).toList();
            return Right(items);
          }
          return Left(ValidationFailure(message: 'Expected list but got ${data.runtimeType}'));
        } catch (e) {
          return Left(ValidationFailure(message: 'Failed to parse list: $e'));
        }
      },
    );
  }

  // Helper method for transforming single item
  Either<Failure, T> transformItem<T>(
    Either<Failure, dynamic> result,
    T Function(dynamic) fromJson,
  ) {
    return result.fold(
      (failure) => Left(failure),
      (data) {
        try {
          return Right(fromJson(data));
        } catch (e) {
          return Left(ValidationFailure(message: 'Failed to parse item: $e'));
        }
      },
    );
  }
} 
abstract class Either<L, R> {
  const Either();

  bool get isLeft;
  bool get isRight;

  L get left;
  R get right;

  T fold<T>(T Function(L left) fnL, T Function(R right) fnR);

  Either<L, T> map<T>(T Function(R right) f) {
    return fold((l) => Left(l), (r) => Right(f(r)));
  }

  Either<T, R> mapLeft<T>(T Function(L left) f) {
    return fold((l) => Left(f(l)), (r) => Right(r));
  }
}

class Left<L, R> extends Either<L, R> {
  final L _value;

  const Left(this._value);

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  L get left => _value;

  @override
  R get right => throw Exception('Called right on Left');

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) {
    return fnL(_value);
  }

  @override
  bool operator ==(Object other) {
    return other is Left && other._value == _value;
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'Left($_value)';
}

class Right<L, R> extends Either<L, R> {
  final R _value;

  const Right(this._value);

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  L get left => throw Exception('Called left on Right');

  @override
  R get right => _value;

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) {
    return fnR(_value);
  }

  @override
  bool operator ==(Object other) {
    return other is Right && other._value == _value;
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'Right($_value)';
} 
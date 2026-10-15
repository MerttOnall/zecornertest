class StringField {
  final String _value;
  final String? _errorMessage;

  StringField(this._value, {String? errorMessage}) : _errorMessage = errorMessage;

  String get value => _value;
  String? get errorMessage => _errorMessage;
  bool get isValid => _errorMessage == null && _value.isNotEmpty;
  bool get isEmpty => _value.isEmpty;

  @override
  String toString() => _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringField && runtimeType == other.runtimeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}

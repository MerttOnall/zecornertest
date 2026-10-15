class UnfavoriteModel {
  final String code;
  final String message;
  final String pk;

  UnfavoriteModel({
    required this.code,
    required this.message,
    required this.pk,
  });

  factory UnfavoriteModel.fromJson(Map<String, dynamic> json) {
    return UnfavoriteModel(
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      pk: json['pk'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'pk': pk,
    };
  }

  @override
  String toString() {
    return 'UnfavoriteModel(code: $code, message: $message, pk: $pk)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnfavoriteModel &&
        other.code == code &&
        other.message == message &&
        other.pk == pk;
  }

  @override
  int get hashCode {
    return code.hashCode ^ message.hashCode ^ pk.hashCode;
  }
}

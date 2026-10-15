abstract class IFormModel {
  bool isValid();
  Map<String, dynamic> toMap();
  String? getErrorMessage();
}

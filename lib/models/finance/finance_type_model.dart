class FinanceType {
  final String code;
  final String description;
  final bool isExpense;

  FinanceType({
    required this.code,
    required this.description,
    required this.isExpense,
  });

  factory FinanceType.fromJson(Map<String, dynamic> json) {
    return FinanceType(
      code: json['code'] as String,
      description: json['description'] as String,
      isExpense: json['is_expense'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'is_expense': isExpense,
    };
  }

  // Gelir mi gider mi kontrolü
  bool get isIncome => !isExpense;
}


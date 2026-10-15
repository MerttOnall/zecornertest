class PotentialIncomeModel {
  final String potentialIncome;
  final int office;

  PotentialIncomeModel({
    required this.potentialIncome,
    required this.office,
  });

  factory PotentialIncomeModel.fromJson(Map<String, dynamic> json) {
    return PotentialIncomeModel(
      potentialIncome: json['potential_income']?.toString() ?? '0',
      office: json['office'] is int
          ? json['office'] as int
          : int.tryParse('${json['office'] ?? 0}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'potential_income': potentialIncome,
      'office': office,
    };
  }

  @override
  String toString() {
    return 'PotentialIncomeModel(potentialIncome: $potentialIncome, office: $office)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PotentialIncomeModel &&
        other.potentialIncome == potentialIncome &&
        other.office == office;
  }

  @override
  int get hashCode {
    return potentialIncome.hashCode ^ office.hashCode;
  }
}

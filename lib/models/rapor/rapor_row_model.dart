/// Rapor satırı modeli. API'den gelecek veri yapısına uyumlu.
class RaporRowModel {
  final String officeOrConsultant;
  final String consultant;
  final int count;

  const RaporRowModel({
    required this.officeOrConsultant,
    required this.consultant,
    required this.count,
  });

  factory RaporRowModel.fromJson(Map<String, dynamic> json) {
    final office = json['connected_contact_title'] as String? ??
        json['officeName'] as String? ??
        json['officeOrConsultant'] as String? ??
        '';
    final consultant = json['contact_title'] as String? ??
        json['consultantName'] as String? ??
        json['consultant'] as String? ??
        '';
    final c = json['count'];
    final count = c is int ? c : (int.tryParse('$c') ?? 0);
    return RaporRowModel(
      officeOrConsultant: office,
      consultant: consultant,
      count: count,
    );
  }

  Map<String, dynamic> toJson() => {
        'officeOrConsultant': officeOrConsultant,
        'consultant': consultant,
        'count': count,
      };
}

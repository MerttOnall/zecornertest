/// "Tüm brokerlar" listesi için satır modeli (get-contacts API cevabı).
/// Sütunlar: No, Kişi / T.C & Vergi No, İletişim Bilgileri, Bağlı Ofis/Broker.
class BrokerRowModel {
  final int contactNo;
  final String name;
  final String surname;
  final String title;
  final String? tcIdNumber;
  final String? taxNo;
  final String email;
  final String tel;
  final String? connectedContactTitle;
  final String? pictureUrl;

  const BrokerRowModel({
    required this.contactNo,
    required this.name,
    required this.surname,
    required this.title,
    this.tcIdNumber,
    this.taxNo,
    required this.email,
    required this.tel,
    this.connectedContactTitle,
    this.pictureUrl,
  });

  String get displayName {
    final n = '$name $surname'.trim();
    return n.isNotEmpty ? n : (title.isNotEmpty ? title : '—');
  }

  String get tcVergiDisplay {
    if (tcIdNumber != null && tcIdNumber!.isNotEmpty) return 'T.C. No: $tcIdNumber';
    if (taxNo != null && taxNo!.isNotEmpty) return 'Vergi No: $taxNo';
    return 'T.C. No: -';
  }

  factory BrokerRowModel.fromJson(Map<String, dynamic> json) {
    final contactNo = json['contact_no'] ?? json['contactNo'] ?? 0;
    final name = (json['name'] ?? '').toString().trim();
    final surname = (json['surname'] ?? '').toString().trim();
    final title = (json['title'] ?? '').toString().trim();
    final tc = json['tc_id_number'] ?? json['tcIdNumber'];
    final tax = json['tax_no'] ?? json['taxNo'];
    final email = (json['e_mail'] ?? json['email'] ?? '').toString();
    final tel = (json['tel'] ?? '').toString();
    final connected = json['connected_contact_title'] ?? json['connectedContactTitle'];
    final picture = json['picture'] ?? json['pictureUrl'];
    return BrokerRowModel(
      contactNo: contactNo is int ? contactNo : int.tryParse('$contactNo') ?? 0,
      name: name,
      surname: surname,
      title: title,
      tcIdNumber: tc?.toString(),
      taxNo: tax?.toString(),
      email: email,
      tel: tel,
      connectedContactTitle: connected?.toString(),
      pictureUrl: picture?.toString(),
    );
  }
}

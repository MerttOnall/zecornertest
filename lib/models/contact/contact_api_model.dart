import 'dart:convert';

class ContactApiModel {
  final int contactNo;
  final String title;
  final String name;
  final String surname;
  final String type;
  final String? tcIdNumber;
  final String? taxNo;
  final String? taxOffice;
  final String nationality;
  final int? sex;
  final String eMail;
  final String tel;
  final int status;
  final String? updatedAt;
  final String createdAt;
  final String? source;
  final String typeDescription;
  final bool isCompany;
  final bool isEmployee;
  final bool isAgency;
  final String? birthday;
  final String? professionCode;
  final String? professionDescription;
  final String? educationCode;
  final String? educationDescription;
  final String? whereYouHeardUs;
  final int? sectoralExperience;
  final String? picture;
  final bool marketingCommunicationPermission;
  final String? address;
  final String? district;
  final String? postCode;
  final String? city;
  final String? country;
  final String? addressSource;
  final String? provinceCode;
  final String? provinceName;
  final String? districtCode;
  final String? districtName;
  final String? quarterCode;
  final String? quarterName;
  final int? connectedContact;
  final String? connectedContactTitle;
  final int? connectedContactType;
  final String? connectedContactDescription;
  final bool isCustomer;
  final String slug;
  final String? instagram;
  final String? facebook;
  final String? twitter;
  final String? linkedin;
  final String? pastExperience;
  final String? coverLetter;
  final String? references;
  final String? aboutMe; // Hakkımda 
  final int? birthPlaceCode; // Doğum Yeri Kodu
  final String? birthPlaceName; // Doğum Yeri Adı
  final String? maritalStatus; // Medeni Durum
  final String? size; // Beden
  final bool? isForeignNationality; // Yabancı Uyruk
  final List<Map<String, dynamic>>? detailAttachments; // Mevcut belgeler (güncellemede korunacak)
  final Map<String, dynamic>? preservedNestedDetail;

  ContactApiModel({
    required this.contactNo,
    required this.title,
    required this.name,
    required this.surname,
    required this.type,
    this.tcIdNumber,
    this.taxNo,
    this.taxOffice,
    required this.nationality,
    this.sex,
    required this.eMail,
    required this.tel,
    required this.status,
    this.updatedAt,
    required this.createdAt,
    this.source,
    required this.typeDescription,
    required this.isCompany,
    required this.isEmployee,
    required this.isAgency,
    this.birthday,
    this.professionCode,
    this.professionDescription,
    this.educationCode,
    this.educationDescription,
    this.whereYouHeardUs,
    this.sectoralExperience,
    this.picture,
    required this.marketingCommunicationPermission,
    this.address,
    this.district,
    this.postCode,
    this.city,
    this.country,
    this.addressSource,
    this.provinceCode,
    this.provinceName,
    this.districtCode,
    this.districtName,
    this.quarterCode,
    this.quarterName,
    this.connectedContact,
    this.connectedContactTitle,
    this.connectedContactType,
    this.connectedContactDescription,
    required this.isCustomer,
    required this.slug,
    this.instagram,
    this.facebook,
    this.twitter,
    this.linkedin,
    this.pastExperience,
    this.coverLetter,
    this.references,
    this.aboutMe,
    this.birthPlaceCode,
    this.birthPlaceName,
    this.maritalStatus,
    this.size,
    this.isForeignNationality,
    this.detailAttachments,
    this.preservedNestedDetail,
  });

  factory ContactApiModel.fromJson(Map<String, dynamic> json) {
    final detail = _asMap(json['detail']);
    final nested = _asMap(detail['detail']);
    final social = _asMap(detail['socialMedia'] ?? detail['social_media']);
    final address = json['address'] is Map
        ? Map<String, dynamic>.from(json['address'] as Map)
        : <String, dynamic>{};
    final uavtRaw = address['uavt_address'];
    final uavt = uavtRaw is Map
        ? Map<String, dynamic>.from(uavtRaw)
        : <String, dynamic>{};

    String? str(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    int? asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim());
      return null;
    }

    bool asBool(dynamic value, [bool fallback = false]) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = value?.toString().trim().toLowerCase();
      if (text == 'true' || text == '1' || text == 'yes' || text == 'evet') {
        return true;
      }
      if (text == 'false' || text == '0' || text == 'no' || text == 'hayir') {
        return false;
      }
      return fallback;
    }

    int? parseSex(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      final text = value?.toString().trim().toLowerCase();
      if (text == null || text.isEmpty) return null;
      if (text == '1' || text == 'm' || text == 'male' || text == 'erkek') {
        return 1;
      }
      if (text == '2' ||
          text == 'f' ||
          text == 'female' ||
          text == 'kadın' ||
          text == 'kadin') {
        return 2;
      }
      return int.tryParse(text);
    }

    final birthRaw = str(nested['birth_place']) ??
        str(detail['birthPlaceName']) ??
        str(detail['birth_place_name']);
    final birthIsCode = birthRaw != null && int.tryParse(birthRaw) != null;
    final provinceCode = str(uavt['province_code']) ??
        str(address['province_code']) ??
        str(address['city']);
    final provinceName =
        str(uavt['province_name']) ?? str(address['province_name']);
    final districtCode =
        str(uavt['district_code']) ?? str(address['district_code']);
    final districtName =
        str(uavt['district_name']) ?? str(address['district_name']);
    final quarterCode = str(uavt['village_code']) ??
        str(uavt['quarter_code']) ??
        str(address['quarter_code']);
    final quarterName = str(uavt['quarter_name']) ??
        str(uavt['village_name']) ??
        str(address['quarter_name']);
    final profession = detail['profession'] is Map
        ? Map<String, dynamic>.from(detail['profession'] as Map)
        : <String, dynamic>{};
    final education = detail['education'] is Map
        ? Map<String, dynamic>.from(detail['education'] as Map)
        : <String, dynamic>{};

    return ContactApiModel(
      contactNo: asInt(json['contact_no']) ?? asInt(json['no']) ?? 0,
      title: str(json['title']) ?? '',
      name: str(json['name']) ?? '',
      surname: str(json['surname']) ?? '',
      type: _readTypeCode(json['type']) ?? '1',
      tcIdNumber: str(json['tc_id_number']),
      taxNo: str(json['tax_no']),
      taxOffice: str(json['tax_office']),
      nationality: str(json['nationality']) ?? 'TR',
      sex: parseSex(json['sex']) ?? parseSex(nested['sex']) ?? parseSex(detail['sex']),
      eMail: str(json['e_mail']) ?? str(json['email']) ?? '',
      tel: str(json['tel']) ?? str(json['phone']) ?? '0',
      status: asInt(json['status']) ?? asInt(detail['status']) ?? 0,
      updatedAt: str(json['updated_at']),
      createdAt: str(json['created_at']) ?? DateTime.now().toIso8601String(),
      source: str(json['source']),
      typeDescription: str(json['type_description']) ?? '',
      isCompany: asBool(json['is_company']),
      isEmployee: asBool(json['is_employee']),
      isAgency: asBool(json['is_agency']),
      birthday: birthdayFrom(json),
      professionCode: str(profession['code']) ??
          str(profession['id']) ??
          str(json['profession_code']),
      professionDescription: str(profession['description']) ??
          str(json['profession_description']),
      educationCode: str(education['code']) ??
          str(education['id']) ??
          str(json['education_code']),
      educationDescription:
          str(education['description']) ?? str(json['education_description']),
      whereYouHeardUs: _plainRichText(nested['whereYouHeardUs']) ??
          _plainRichText(nested['where_you_heard_us']) ??
          _plainRichText(detail['whereYouHeardUs']) ??
          _plainRichText(detail['where_you_heard_us']) ??
          _plainRichText(json['where_you_heard_us']),
      sectoralExperience: asInt(detail['sectoralExperience']) ??
          asInt(detail['sectoral_experience']) ??
          asInt(json['sectoral_experience']),
      picture: str(detail['picture']) ?? str(json['picture']),
      marketingCommunicationPermission: asBool(
        detail['marketingCommunicationPermission'] ??
            detail['marketing_communication_permission'],
      ),
      address: str(address['address']),
      district: districtName ?? districtCode ?? str(address['district']),
      postCode: str(address['post_code']) ?? str(address['postCode']),
      city: provinceName ?? provinceCode ?? str(address['city']),
      country: str(address['country_code']) ?? str(address['country']),
      addressSource: str(address['address_source']),
      provinceCode: provinceCode,
      provinceName: provinceName,
      districtCode: districtCode,
      districtName: districtName,
      quarterCode: quarterCode,
      quarterName: quarterName,
      connectedContact: asInt(json['connected_contact']),
      connectedContactTitle: str(json['connected_contact_title']),
      connectedContactType: asInt(json['connected_contact_type']),
      connectedContactDescription: str(json['connected_contact_description']),
      isCustomer: asBool(json['is_customer']),
      slug: str(json['slug']) ?? '',
      instagram: str(social['instagram']) ?? str(detail['instagram']),
      facebook: str(social['facebook']) ?? str(detail['facebook']),
      twitter: str(social['x']) ?? str(social['twitter']) ?? str(detail['twitter']),
      linkedin: str(social['linkedin']) ?? str(detail['linkedin']),
      pastExperience: _plainRichText(detail['areasOfExpertise']) ??
          _plainRichText(detail['areas_of_expertise']) ??
          _plainRichText(detail['pastExperience']) ??
          _plainRichText(detail['past_experience']),
      coverLetter: _plainRichText(detail['writing']) ??
          _plainRichText(detail['coverLetter']) ??
          _plainRichText(detail['cover_letter']) ??
          _plainRichText(detail['aboutMe']) ??
          _plainRichText(detail['about_me']),
      references: _plainRichText(detail['reference']) ??
          _plainRichText(detail['references']),
      aboutMe: _plainRichText(detail['aboutMe']) ??
          _plainRichText(detail['about_me']),
      birthPlaceCode: birthIsCode
          ? int.tryParse(birthRaw)
          : (asInt(detail['birthPlaceCode']) ?? asInt(detail['birth_place_code'])),
      birthPlaceName: birthIsCode
          ? (str(detail['birthPlaceName']) ?? str(detail['birth_place_name']))
          : birthRaw,
      maritalStatus: str(nested['marital_status']) ??
          str(nested['maritalStatus']) ??
          str(detail['maritalStatus']) ??
          str(detail['marital_status']),
      size: str(nested['clothing_size']) ??
          str(nested['clothingSize']) ??
          str(detail['clothing_size']) ??
          str(detail['size']),
      isForeignNationality: detail['isForeignNationality'] is bool
          ? detail['isForeignNationality'] as bool
          : detail['is_foreign_nationality'] is bool
              ? detail['is_foreign_nationality'] as bool
              : ((str(json['nationality']) ?? 'TR') != 'TR'),
      detailAttachments: attachmentsFrom(json),
      preservedNestedDetail: nested.isEmpty ? null : nested,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  /// Quill HTML (`<p class="ql-align-justify">…</p>`) düz metne iner.
  static String? _plainRichText(dynamic value) {
    final raw = _textValue(value);
    if (raw == null) return null;
    if (!raw.contains('<') && !raw.contains('&')) return raw;
    var text = raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]+>'), '');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return text.isEmpty ? null : text;
  }

  static String? _textValue(dynamic value) {
    if (value is List) {
      final parts = value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join('\n');
    }
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? birthdayFrom(Map<String, dynamic> json) {
    final detail = _asMap(json['detail']);
    final nested = _asMap(detail['detail']);
    const keys = [
      'birthday',
      'birthDay',
      'birth_date',
      'birthDate',
      'date_of_birth',
      'dogum_tarihi',
    ];
    for (final source in [detail, nested, json]) {
      for (final key in keys) {
        final text = _dateText(source[key]);
        if (text != null) return text;
      }
    }
    return null;
  }

  static String? _dateText(dynamic value) {
    if (value is Map) {
      final year = value['year'] ?? value['y'];
      final month = value['month'] ?? value['m'];
      final day = value['day'] ?? value['d'];
      if (year != null && month != null && day != null) {
        final d = day.toString().padLeft(2, '0');
        final m = month.toString().padLeft(2, '0');
        return '$d/$m/$year';
      }
      final inner = value['date'] ?? value['birthday'] ?? value['value'];
      if (inner != null && inner is! Map) return _dateText(inner);
      return null;
    }
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;
    return text;
  }

  /// Kayıttaki bütün ağacı tarar. Belge `attachments` dışında bir yerde duruyorsa da bulunur.
  static List<Map<String, dynamic>> collectAttachmentMaps(dynamic node) {
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    void walk(dynamic current, int depth) {
      if (current == null || depth > 6) return;
      if (current is String) {
        final text = current.trim();
        if ((text.startsWith('[') || text.startsWith('{')) && text.length > 2) {
          try {
            walk(jsonDecode(text), depth + 1);
          } catch (_) {}
        }
        return;
      }
      if (current is List) {
        for (final item in current) {
          walk(item, depth + 1);
        }
        return;
      }
      if (current is! Map) return;

      final type = _attachmentType(current['type']);
      final described = _attachmentType(
        current['type_description'] ?? current['description'],
      );
      final file = _attachmentFile(
        current['attachment'] ??
            current['s3Id'] ??
            current['s3id'] ??
            current['s3_id'] ??
            current['fileId'] ??
            current['file_id'] ??
            current['url'] ??
            current['file_url'] ??
            current['path'],
      );
      final label = '$type $described'.trim();
      final known = _specificDocumentType(label) != null ||
          _looksLikeAttachmentType(type) ||
          _looksLikeAttachmentType(described);
      if (file.isNotEmpty &&
          file != 'null' &&
          known &&
          seen.add('${label.toUpperCase()}|$file')) {
        out.add({
          'type': type.isNotEmpty ? type : described,
          'attachment': file,
          'type_description': described,
          'id': current['id'],
        });
      }

      for (final value in current.values) {
        if (value is Map || value is List) {
          walk(value, depth + 1);
        } else if (value is String) {
          final text = value.trim();
          if ((text.startsWith('[') || text.startsWith('{')) && text.length > 2) {
            walk(value, depth + 1);
          }
        }
      }
    }

    walk(node, 0);
    return out;
  }

  static List<Map<String, dynamic>>? attachmentsFrom(Map<String, dynamic> json) {
    final collected = collectAttachmentMaps(json);
    if (collected.isNotEmpty) return collected;
    final detail = _asMap(json['detail']);
    final nested = _asMap(detail['detail']);
    final direct = <Map<String, dynamic>>[];
    void takeDirect(dynamic source) {
      if (source is! List) return;
      for (final item in source) {
        if (item is! Map) continue;
        final type = (item['type'] ?? '').toString().trim();
        final file = (item['attachment'] ??
                item['s3Id'] ??
                item['s3_id'] ??
                item['fileId'] ??
                item['file_id'] ??
                '')
            .toString()
            .trim();
        if (type.isEmpty || file.isEmpty || file == 'null') continue;
        direct.add({'type': type, 'attachment': file});
      }
    }

    takeDirect(json['attachments']);
    takeDirect(detail['attachments']);
    takeDirect(nested['attachments']);
    if (direct.isNotEmpty) return direct;
    return _readAttachments([
      json['attachments'],
      json['files'],
      json['documents'],
      detail['attachments'],
      detail['files'],
      detail['documents'],
      nested['attachments'],
      nested['files'],
      nested['documents'],
      _namedDocumentEntries(json),
      _namedDocumentEntries(detail),
      _namedDocumentEntries(nested),
    ]);
  }

  static List<Map<String, dynamic>>? _readAttachments(List<dynamic> sources) {
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    void add(String type, String file) {
      final kind = type.trim();
      final id = file.trim();
      if (kind.isEmpty || id.isEmpty) return;
      final key = '${kind.toUpperCase()}|$id';
      if (!seen.add(key)) return;
      out.add({'type': kind, 'attachment': id});
    }

    void consume(dynamic source) {
      if (source == null) return;
      if (source is String) {
        final text = source.trim();
        if (text.startsWith('[') || text.startsWith('{')) {
          try {
            consume(jsonDecode(text));
          } catch (_) {}
        }
        return;
      }
      if (source is List) {
        for (final item in source) {
          consume(item);
        }
        return;
      }
      if (source is! Map) return;

      final map = <String, dynamic>{};
      source.forEach((key, value) {
        map[key.toString().toLowerCase()] = value;
      });

      var type = _attachmentType(map['type']);
      final described = (map['type_description'] ?? map['description'] ?? '')
          .toString()
          .trim();
      var file = _attachmentFile(
        map['attachment'] ??
            map['s3id'] ??
            map['fileid'] ??
            map['file_id'] ??
            map['file'] ??
            map['key'] ??
            map['url'] ??
            map['file_url'] ??
            map['fileurl'] ??
            map['path'] ??
            map['link'],
      );
      final rowId = _attachmentFile(map['id']);
      final specific = _specificDocumentType(described) ??
          _specificDocumentType(type) ??
          _specificDocumentType(rowId);
      if (specific != null) {
        type = specific;
      } else if (type.isEmpty && _looksLikeAttachmentType(rowId)) {
        type = rowId;
      } else if (type.isEmpty) {
        type = described;
      }
      if (file.isEmpty &&
          rowId.isNotEmpty &&
          _specificDocumentType(rowId) == null &&
          !_looksLikeAttachmentType(rowId)) {
        file = rowId;
      }
      if (type.isNotEmpty && file.isNotEmpty && _looksLikeFileId(file)) {
        add(type, file);
      }

      map.forEach((key, value) {
        if (key == 'type' ||
            key == 'id' ||
            key == 'attachment' ||
            key == 's3id' ||
            key == 'type_description' ||
            key == 'description') {
          return;
        }
        if (value is Map || value is List) {
          final named = _specificDocumentType(key);
          if (named != null && value is Map) {
            final nestedId = _attachmentFile(value);
            if (_looksLikeFileId(nestedId)) add(named, nestedId);
          }
          consume(value);
          return;
        }
        final nestedFile = _attachmentFile(value);
        if (!_looksLikeFileId(nestedFile)) return;
        final named = _specificDocumentType(key);
        if (named != null) {
          add(named, nestedFile);
        } else if (_looksLikeAttachmentType(key)) {
          add(key, nestedFile);
        }
      });
    }

    for (final source in sources) {
      consume(source);
    }
    return out.isEmpty ? null : out;
  }

  static String _attachmentType(dynamic value) {
    if (value is Map) {
      return (value['code'] ?? value['id'] ?? value['description'] ?? '')
          .toString()
          .trim();
    }
    return value?.toString().trim() ?? '';
  }

  static String _attachmentFile(dynamic value) {
    if (value is Map) {
      final id = (value['id'] ?? '').toString().trim();
      final rest = (value['s3Id'] ??
              value['s3id'] ??
              value['attachment'] ??
              value['key'] ??
              value['url'] ??
              value['file_url'] ??
              value['fileUrl'] ??
              value['path'] ??
              value['link'] ??
              '')
          .toString()
          .trim();
      if (id.isNotEmpty &&
          rest.isNotEmpty &&
          (_specificDocumentType(id) != null || _looksLikeAttachmentType(id))) {
        return rest == 'null' ? '' : rest;
      }
      if (id.isNotEmpty &&
          id != 'null' &&
          _specificDocumentType(id) == null &&
          !_looksLikeAttachmentType(id)) {
        return id;
      }
      return rest == 'null' ? '' : rest;
    }
    final text = value?.toString().trim() ?? '';
    return text == 'null' ? '' : text;
  }

  static bool _looksLikeFileId(String value) {
    final text = value.trim();
    if (text.isEmpty || text == 'null') return false;
    if (text.contains(' ') || text.contains('\n')) return false;
    return text.length >= 4;
  }

  /// Web enum’u ya da Türkçe açıklamayı düzenle ekranının yuvasına çevirir.
  static String? _specificDocumentType(String raw) {
    final type = raw
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
    if (type.isEmpty) return null;
    if (type.contains('CRIMINAL') ||
        type.contains('ADLI SICIL') ||
        type.contains('SABIKA')) {
      return 'CRIMINAL_RECORD';
    }
    if (type.contains('GRADUATION') ||
        type.contains('DIPLOMA') ||
        type.contains('MEZUNIYET')) {
      return 'GRADUATION_DOCUMENT';
    }
    if (type.contains('PROFESSIONAL') ||
        type.contains('COMPOTENCE') ||
        type.contains('COMPETENCE') ||
        type.contains('YETERLILIK') ||
        type.contains('MESLEKI')) {
      return 'PROFESSIONAL_COMPOTENCE_CERTIFICATE';
    }
    if (type.contains('REAL_ESTATE') ||
        type.contains('TASINMAZ') ||
        type.contains('TICARI YETKI')) {
      return 'REAL_ESTATE_TRADE_AUTHORIZATION_CERTIFICATE';
    }
    if (type.contains('TAX_PLATE') || type.contains('VERGI LEVHA')) {
      return 'TAX_PLATE';
    }
    if (type.contains('IDENTITY_DOCUMENT_BACK') ||
        type.contains('IDENTITY_BACK') ||
        ((type.contains('NUFUS') || type.contains('KIMLIK')) &&
            type.contains('ARKA'))) {
      return 'IDENTITY_DOCUMENT_BACK';
    }
    if (type.contains('IDENTITY_DOCUMENT_FRONT') ||
        type.contains('IDENTITY_FRONT') ||
        ((type.contains('NUFUS') || type.contains('KIMLIK')) &&
            (type.contains('ON') || type.contains('FRONT')))) {
      return 'IDENTITY_DOCUMENT_FRONT';
    }
    if (type == 'IDENTITY_DOCUMENT') return 'IDENTITY_DOCUMENT';
    if (type.contains('CONTRACT') || type.contains('SOZLESME')) {
      return 'CONTRACT_DOCUMENT';
    }
    return null;
  }

  static List<Map<String, dynamic>> _namedDocumentEntries(
    Map<String, dynamic> map,
  ) {
    const keys = <String, String>{
      'criminalRecord': 'CRIMINAL_RECORD',
      'criminal_record': 'CRIMINAL_RECORD',
      'graduationDocument': 'GRADUATION_DOCUMENT',
      'graduation_document': 'GRADUATION_DOCUMENT',
      'diploma': 'GRADUATION_DOCUMENT',
      'professionalCompotenceCertificate':
          'PROFESSIONAL_COMPOTENCE_CERTIFICATE',
      'professional_compotence_certificate':
          'PROFESSIONAL_COMPOTENCE_CERTIFICATE',
      'professionalCertificate': 'PROFESSIONAL_COMPOTENCE_CERTIFICATE',
      'professional_certificate': 'PROFESSIONAL_COMPOTENCE_CERTIFICATE',
      'realEstateTradeAuthorizationCertificate':
          'REAL_ESTATE_TRADE_AUTHORIZATION_CERTIFICATE',
      'real_estate_trade_authorization_certificate':
          'REAL_ESTATE_TRADE_AUTHORIZATION_CERTIFICATE',
      'realEstatePermit': 'REAL_ESTATE_TRADE_AUTHORIZATION_CERTIFICATE',
      'real_estate_permit': 'REAL_ESTATE_TRADE_AUTHORIZATION_CERTIFICATE',
      'taxPlate': 'TAX_PLATE',
      'tax_plate': 'TAX_PLATE',
      'taxPlateDocument': 'TAX_PLATE',
      'identityDocumentFront': 'IDENTITY_DOCUMENT_FRONT',
      'identity_document_front': 'IDENTITY_DOCUMENT_FRONT',
      'identityDocumentBack': 'IDENTITY_DOCUMENT_BACK',
      'identity_document_back': 'IDENTITY_DOCUMENT_BACK',
      'identityDocument': 'IDENTITY_DOCUMENT',
      'contractDocument': 'CONTRACT_DOCUMENT',
    };
    final out = <Map<String, dynamic>>[];
    map.forEach((key, value) {
      final type = keys[key];
      if (type == null) return;
      final file = _attachmentFile(value);
      if (!_looksLikeFileId(file)) return;
      out.add({'type': type, 'attachment': file});
    });
    return out;
  }

  static bool _looksLikeAttachmentType(String value) {
    final type = value
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('İ', 'I');
    if (type.isEmpty) return false;
    const marks = [
      'DOCUMENT',
      'CRIMINAL',
      'DIPLOMA',
      'GRADUATION',
      'PROFESSIONAL',
      'REAL_ESTATE',
      'IDENTITY',
      'TAX_PLATE',
      'PICTURE',
      'PERMIT',
      'CERTIFICATE',
      'CONTRACT',
      'COMPOTENCE',
      'COMPETENCE',
      'YETERLILIK',
      'MESLEKI',
    ];
    for (final mark in marks) {
      if (type.contains(mark)) return true;
    }
    return false;
  }

  /// Adres: DB/API il ve ilçe için **kod (int)** bekliyor; isimleri `*_name` alanlarında gönder.
  Map<String, dynamic> _buildAddressPayload() {
    final out = <String, dynamic>{};

    int? pCode = int.tryParse(provinceCode ?? '');
    if (pCode == null && city != null && city!.isNotEmpty) {
      pCode = int.tryParse(city!);
    }
    int? dCode = int.tryParse(districtCode ?? '');
    if (dCode == null && district != null && district!.isNotEmpty) {
      dCode = int.tryParse(district!);
    }
    final qCode = int.tryParse(quarterCode ?? '');

    if (pCode != null) {
      out['city'] = pCode;
      out['province_code'] = pCode;
    }
    if (provinceName != null && provinceName!.isNotEmpty) {
      out['province_name'] = provinceName;
    }
    if (dCode != null) {
      out['district'] = dCode;
      out['district_code'] = dCode;
    }
    if (districtName != null && districtName!.isNotEmpty) {
      out['district_name'] = districtName;
    }
    if (qCode != null) {
      out['quarter_code'] = qCode;
    }
    if (quarterName != null && quarterName!.isNotEmpty) {
      out['quarter_name'] = quarterName;
    }
    if (country != null && country!.isNotEmpty) {
      out['country'] = country;
    }
    if (address != null && address!.isNotEmpty) {
      out['address'] = address;
    }
    if (postCode != null && postCode!.isNotEmpty) {
      out['postCode'] = postCode;
      out['post_code'] = postCode;
    }
    return out;
  }

  Map<String, dynamic> toJson() {
    // Ana request objesi (camelCase formatı - Add sayfası ile aynı)
    final requestData = <String, dynamic>{
      'name': name,
      'surname': surname,
      'tel': tel,
      'eMail': eMail, // camelCase
      'nationality': nationality,
      'sex': sex ?? 1, // Default: Erkek
      'type': {
        'code': type, // String olarak obje içinde
      },
      'status': status,
    };
    
    // TC Kimlik (opsiyonel)
    if (tcIdNumber != null && tcIdNumber!.isNotEmpty) {
      requestData['tcIdNumber'] = tcIdNumber; // camelCase
    }
    
    // Detail objesi (opsiyonel)
    final detailObj = <String, dynamic>{};
    
    if (birthday != null && birthday!.isNotEmpty) {
      detailObj['birthday'] = birthday;
    }
    
    if (professionCode != null && professionCode!.isNotEmpty) {
      detailObj['profession'] = {
        'code': professionCode,
        'description': professionDescription ?? '',
      };
    }
    
    if (educationCode != null && educationCode!.isNotEmpty) {
      detailObj['education'] = {
        'code': educationCode,
        'description': educationDescription ?? '',
      };
    }
    
    // Social Media
    final socialMediaObj = <String, dynamic>{};
    if (instagram != null && instagram!.isNotEmpty) {
      socialMediaObj['instagram'] = instagram!;
    }
    if (twitter != null && twitter!.isNotEmpty) {
      socialMediaObj['x'] = twitter!;
    }
    if (linkedin != null && linkedin!.isNotEmpty) {
      socialMediaObj['linkedin'] = linkedin!;
    }
    if (facebook != null && facebook!.isNotEmpty) {
      socialMediaObj['facebook'] = facebook!;
    }
    if (socialMediaObj.isNotEmpty) {
      detailObj['socialMedia'] = socialMediaObj; // camelCase
    }
    
    if (whereYouHeardUs != null && whereYouHeardUs!.isNotEmpty) {
      detailObj['whereYouHeardUs'] = whereYouHeardUs!; // camelCase
    }
    if (coverLetter != null && coverLetter!.isNotEmpty) {
      detailObj['coverLetter'] = coverLetter!; // camelCase
    }
    if (sectoralExperience != null) {
      detailObj['sectoralExperience'] = sectoralExperience!; // camelCase
    }
    if (references != null && references!.isNotEmpty) {
      detailObj['references'] = references!; // references (not reference)
    }
    if (pastExperience != null && pastExperience!.isNotEmpty) {
      detailObj['pastExperience'] = pastExperience!;
    }
    if (picture != null && picture!.isNotEmpty) {
      detailObj['picture'] = picture!;
    }
    if (aboutMe != null && aboutMe!.isNotEmpty) {
      detailObj['aboutMe'] = aboutMe!;
    }
    if (birthPlaceCode != null) {
      detailObj['birthPlaceCode'] = birthPlaceCode!;
    }
    if (birthPlaceName != null && birthPlaceName!.isNotEmpty) {
      detailObj['birthPlaceName'] = birthPlaceName!;
    }
    if (maritalStatus != null && maritalStatus!.isNotEmpty) {
      detailObj['maritalStatus'] = maritalStatus!;
    }
    if (size != null && size!.isNotEmpty) {
      detailObj['size'] = size!;
    }
    if (isForeignNationality != null) {
      detailObj['isForeignNationality'] = isForeignNationality!;
    }
    
    // Attachments (boş array bile olabilir - opsiyonel)
    // detailObj['attachments'] = []; // SADECE gerekliyse ekle
    
    // Detail objesini ekle (sadece boş değilse)
    if (detailObj.isNotEmpty) {
      requestData['detail'] = detailObj;
    }
    
    final addressObj = _buildAddressPayload();
    if (addressObj.isNotEmpty) {
      requestData['address'] = addressObj;
    }
    
    // Connected contact (opsiyonel)
    if (connectedContact != null) {
      requestData['connectedContact'] = connectedContact;
    }
    
    // Marketing permission
    requestData['marketingCommunicationPermission'] = marketingCommunicationPermission;
    
    return requestData;
  }

  // Update için özel JSON metodu (Add sayfasını bozmamak için ayrı)
  Map<String, dynamic> toUpdateJson() {
    // Ana request objesi (camelCase formatı)
    final requestData = <String, dynamic>{
      'name': name,
      'surname': surname,
      'tel': tel,
      'eMail': eMail,
      'nationality': nationality,
      'sex': sex ?? 1,
      'type': {
        'code': type.toString(), // String olarak
      },
      'status': status,
    };

    // TC Kimlik (opsiyonel)
    if (tcIdNumber != null && tcIdNumber!.isNotEmpty) {
      requestData['tcIdNumber'] = tcIdNumber;
    }

    // Detail objesi (opsiyonel)
    final detailObj = <String, dynamic>{};

    if (birthday != null && birthday!.isNotEmpty) {
      detailObj['birthday'] = birthday;
    }

    if (professionCode != null && professionCode!.isNotEmpty) {
      detailObj['profession'] = {
        'code': professionCode,
        'description': professionDescription ?? '',
      };
    }

    if (educationCode != null && educationCode!.isNotEmpty) {
      detailObj['education'] = {
        'code': educationCode,
        'description': educationDescription ?? '',
      };
    }

    // Social Media
    final socialMediaObj = <String, dynamic>{};
    if (instagram != null && instagram!.isNotEmpty) {
      socialMediaObj['instagram'] = instagram!;
    }
    if (twitter != null && twitter!.isNotEmpty) {
      socialMediaObj['x'] = twitter!;
    }
    if (linkedin != null && linkedin!.isNotEmpty) {
      socialMediaObj['linkedin'] = linkedin!;
    }
    if (facebook != null && facebook!.isNotEmpty) {
      socialMediaObj['facebook'] = facebook!;
    }
    if (socialMediaObj.isNotEmpty) {
      detailObj['socialMedia'] = socialMediaObj;
    }

    if (whereYouHeardUs != null && whereYouHeardUs!.isNotEmpty) {
      detailObj['whereYouHeardUs'] = whereYouHeardUs!;
    }
    if (coverLetter != null && coverLetter!.isNotEmpty) {
      detailObj['coverLetter'] = coverLetter!;
    }
    if (sectoralExperience != null) {
      detailObj['sectoralExperience'] = sectoralExperience!;
    }
    if (references != null && references!.isNotEmpty) {
      detailObj['references'] = references!;
    }
    if (pastExperience != null && pastExperience!.isNotEmpty) {
      detailObj['pastExperience'] = pastExperience!;
      detailObj['areasOfExpertise'] = pastExperience!;
    }
    if (picture != null && picture!.isNotEmpty) {
      detailObj['picture'] = picture!;
    }
    if (aboutMe != null && aboutMe!.isNotEmpty) {
      detailObj['aboutMe'] = aboutMe!;
    }
    if (coverLetter != null && coverLetter!.isNotEmpty) {
      detailObj['writing'] = coverLetter!;
    }
    if (birthPlaceCode != null) {
      detailObj['birthPlaceCode'] = birthPlaceCode!;
    }
    if (birthPlaceName != null && birthPlaceName!.isNotEmpty) {
      detailObj['birthPlaceName'] = birthPlaceName!;
    }
    if (maritalStatus != null && maritalStatus!.isNotEmpty) {
      detailObj['maritalStatus'] = maritalStatus!;
    }
    if (size != null && size!.isNotEmpty) {
      detailObj['size'] = size!;
    }
    if (isForeignNationality != null) {
      detailObj['isForeignNationality'] = isForeignNationality!;
    }

    final nestedDetail = <String, dynamic>{
      if (preservedNestedDetail != null) ...preservedNestedDetail!,
    };
    if (birthPlaceCode != null) {
      nestedDetail['birth_place'] = birthPlaceCode.toString();
    } else if (birthPlaceName != null && birthPlaceName!.isNotEmpty) {
      nestedDetail['birth_place'] = birthPlaceName;
    }
    if (sex == 1) nestedDetail['sex'] = 'male';
    if (sex == 2) nestedDetail['sex'] = 'female';
    if (maritalStatus != null && maritalStatus!.isNotEmpty) {
      nestedDetail['marital_status'] = maritalStatus;
    }
    if (size != null && size!.isNotEmpty) {
      nestedDetail['clothing_size'] = size;
    }
    if (whereYouHeardUs != null && whereYouHeardUs!.isNotEmpty) {
      nestedDetail['whereYouHeardUs'] = whereYouHeardUs;
    }
    if (nestedDetail.isNotEmpty) {
      detailObj['detail'] = nestedDetail;
    }

    // Attachments (backend bunu mutlaka bekliyor - boş array bile olsa)
    detailObj['attachments'] = [];

    // Detail objesini ekle (sadece boş değilse)
    if (detailObj.isNotEmpty) {
      requestData['detail'] = detailObj;
    }

    requestData['address'] = _buildAddressPayload();

    // Connected contact (opsiyonel)
    if (connectedContact != null) {
      requestData['connectedContact'] = connectedContact;
    }

    // Marketing permission
    requestData['marketingCommunicationPermission'] = marketingCommunicationPermission;

    return requestData;
  }

  // Tam adı döndüren yardımcı method
  String get fullName {
    if (name.isNotEmpty && surname.isNotEmpty) {
      return '$name $surname';
    } else if (name.isNotEmpty) {
      return name;
    } else if (surname.isNotEmpty) {
      return surname;
    }
    return title;
  }

  // Aktif durumu kontrol eden method
  bool get isActive => status == 1;

  // Telefon numarası kontrol eden method
  String get displayPhone => tel == "0" ? "Belirtilmemiş" : tel;

  // E-posta kısaltma methodu
  String get displayEmail {
    if (eMail.length > 20) {
      return '${eMail.substring(0, 17)}...';
    }
    return eMail;
  }
}

class ContactApiResponse {
  final List<ContactApiModel> contacts;
  final int totalCount;
  final int totalPages;
  final int page;

  ContactApiResponse({
    required this.contacts,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory ContactApiResponse.fromJson(Map<String, dynamic> json) {
    return ContactApiResponse(
      contacts: (json['contacts'] as List<dynamic>)
          .map((contactJson) => ContactApiModel.fromJson(contactJson))
          .toList(),
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 1,
    );
  }
}

String? _readTypeCode(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    return _readTypeCode(value['code'] ?? value['id']);
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

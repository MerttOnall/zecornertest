import 'package:shared_preferences/shared_preferences.dart';

/// Danışman oturumunda listeler yalnızca bağlı olunan ofise iner.
/// Admin ve ofis asistanı bu kısıtı almaz.
/// Broker (`role_office_broker`) başka ofise ait olduğu belli olan kaydı görmez;
/// ofis alanı boşsa kayıt kalır, çalışan liste boşalmaz.
class AdvisorOfficeScope {
  final bool restricted;

  /// Yalnız ofis broker. Asistan ve admin bu bayrağı almaz.
  final bool officeTeam;
  final int officeId;
  final int userContactNo;
  final String officeTitle;

  const AdvisorOfficeScope({
    required this.restricted,
    this.officeTeam = false,
    required this.officeId,
    required this.userContactNo,
    required this.officeTitle,
  });

  static const unrestricted = AdvisorOfficeScope(
    restricted: false,
    officeTeam: false,
    officeId: 0,
    userContactNo: 0,
    officeTitle: '',
  );

  static Future<AdvisorOfficeScope> load() async {
    final prefs = await SharedPreferences.getInstance();
    final roles = prefs.getStringList('userRoleCodes') ?? const <String>[];
    final isAdmin =
        prefs.getBool('userIsAdmin') == true || roles.contains('role_admin');
    final isBroker = roles.contains('role_office_broker') ||
        roles.contains('role_office_assistant');
    final officeTeam = roles.contains('role_office_broker') && !isAdmin;
    final restricted = roles.contains('role_advisor') && !isAdmin && !isBroker;

    final officeFromInt = prefs.getInt('officeId');
    final officeId = (officeFromInt != null && officeFromInt > 0)
        ? officeFromInt
        : int.tryParse(prefs.getString('officeId')?.trim() ?? '') ?? 0;

    return AdvisorOfficeScope(
      restricted: restricted,
      officeTeam: officeTeam,
      officeId: officeId,
      userContactNo:
          int.tryParse(prefs.getString('userID')?.trim() ?? '') ?? 0,
      officeTitle: prefs.getString('officeTitle')?.trim() ?? '',
    );
  }

  bool matchesId(int? id) {
    if (id == null || id <= 0) return false;
    if (officeId > 0 && id == officeId) return true;
    if (userContactNo > 0 && id == userContactNo) return true;
    return false;
  }

  bool matchesTitle(String? title) {
    final mine = _fold(officeTitle);
    final theirs = _fold(title ?? '');
    if (mine.isEmpty || theirs.isEmpty) return false;
    return mine == theirs;
  }

  /// Başka ofise ait olduğu açıkça belli olan kayıt.
  /// Ofis bilgisi yoksa false döner; çalışan ekran boşalmaz.
  bool isForeignOffice({int? officeId, String? officeTitle}) {
    if (!officeTeam) return false;
    if (this.officeId <= 0 && this.officeTitle.trim().isEmpty) return false;
    final hasId = officeId != null && officeId > 0;
    final hasTitle = (officeTitle ?? '').trim().isNotEmpty;
    if (hasId && this.officeId > 0 && officeId == this.officeId) return false;
    if (hasTitle && matchesTitle(officeTitle)) return false;
    if (hasId && this.officeId > 0 && officeId != this.officeId) return true;
    if (hasTitle && this.officeTitle.trim().isNotEmpty) return true;
    return false;
  }

  /// Kısıt yoksa her kayıt kalır.
  /// Ofis veya kişi bağı başka ofise işaret ediyorsa düşer.
  /// Bağ alanı boşsa listeyi boşaltmamak için kayıt kalır.
  bool allows({int? officeId, int? personId, String? officeTitle}) {
    if (!restricted) return true;
    final hasOfficeId = officeId != null && officeId > 0;
    final hasPerson = personId != null && personId > 0;
    final hasTitle = (officeTitle ?? '').trim().isNotEmpty;
    if (!hasOfficeId && !hasPerson && !hasTitle) return true;
    if (hasOfficeId && matchesId(officeId)) return true;
    if (hasPerson && matchesId(personId)) return true;
    if (hasTitle && matchesTitle(officeTitle)) return true;
    return false;
  }

  static String _fold(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

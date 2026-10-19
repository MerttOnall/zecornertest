import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/visit/visit_repository.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/presentation/screens/franchise_map/franchise_map_data.dart';
import 'package:zecorner/presentation/screens/franchise_map/franchise_visit_detail_screen.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';

enum _MapLevel { country, province, district, neighborhood }

enum _BoardMode { map, list }

/// Saha ziyaret haritası. Kayıtlar şimdilik oturum içinde durur;
/// API gelince katalog ve liste repository'ye taşınacak.
class FranchiseMapScreen extends StatefulWidget {
  const FranchiseMapScreen({super.key});

  @override
  State<FranchiseMapScreen> createState() => _FranchiseMapScreenState();
}

class _FranchiseMapScreenState extends State<FranchiseMapScreen> {
  static const _red = Color(0xFFEE2E24);
  static const _ink = Color(0xFF101828);
  static const _muted = Color(0xFF667085);
  static const _line = Color(0xFFEAECF0);
  static const _paper = Color(0xFFF8FAFC);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  final TextEditingController _officeController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _mapReady = false;
  double _viewZoom = 6.15;
  String? _highlightedId;
  int _flyGen = 0;
  LatLng? _pendingCenter;
  double? _pendingZoom;
  _BoardMode _mode = _BoardMode.map;

  String? _provinceId;
  String? _districtId;
  String? _neighborhoodId;

  final VisitRepository _visitRepository = VisitRepository();
  final ContactApiRepository _placesApi = ContactApiRepository();
  List<ProvinceModel> _apiProvinces = [];
  List<DistrictModel> _apiDistricts = [];
  bool _districtsLoading = false;
  int? _districtsForCode;
  Future<void>? _districtsInFlight;
  int? _districtsInFlightCode;
  List<FieldVisit> _visits = const [];
  bool _visitsLoading = true;
  String? _visitsError;

  bool _sheetOpen = false;
  bool _movingPin = false;
  bool _saveAttempted = false;
  bool _saving = false;
  DateTime? _draftCreatedAt;
  String? _editingId;
  int? _draftScore;
  List<String> _draftNotes = [];
  LatLng? _draftPoint;

  @override
  void initState() {
    super.initState();
    _loadVisits();
    _loadApiProvinces();
  }

  Future<void> _loadApiProvinces() async {
    final result = await _placesApi.getProvinces();
    if (!mounted) return;
    result.fold((_) {}, (data) {
      setState(() {
        _apiProvinces = [...data.provinces]
          ..sort((a, b) => a.name.compareTo(b.name));
      });
    });
  }

  Future<void> _ensureDistricts(int provinceCode) {
    if (_districtsForCode == provinceCode && _apiDistricts.isNotEmpty) {
      return Future<void>.value();
    }
    final inFlight = _districtsInFlight;
    if (inFlight != null && _districtsInFlightCode == provinceCode) {
      return inFlight;
    }
    _districtsInFlightCode = provinceCode;
    final future = _fetchDistricts(provinceCode);
    _districtsInFlight = future;
    return future.whenComplete(() {
      if (_districtsInFlightCode == provinceCode) {
        _districtsInFlight = null;
      }
    });
  }

  Future<void> _fetchDistricts(int provinceCode) async {
    setState(() {
      _districtsLoading = true;
      _districtsForCode = provinceCode;
      _apiDistricts = [];
    });
    final result = await _placesApi.getDistrictsByProvince(provinceCode);
    if (!mounted || _districtsForCode != provinceCode) return;
    result.fold((_) {
      setState(() => _districtsLoading = false);
    }, (data) {
      setState(() {
        _apiDistricts = [...data.districts]
          ..sort((a, b) => a.name.compareTo(b.name));
        for (final district in _apiDistricts) {
          district.quarters.sort((a, b) => a.name.compareTo(b.name));
        }
        _districtsLoading = false;
      });
    });
  }

  bool _samePlaceId(String selected, String stored) {
    if (selected == stored) return true;
    final left = int.tryParse(selected);
    final right = int.tryParse(stored);
    return left != null && left == right;
  }

  String _foldSearch(String value) {
    return value
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  Future<void> _loadVisits({int? cityCode}) async {
    final result = await _visitRepository.fetchVisits(cityCode: cityCode);
    if (!mounted) return;
    setState(() {
      _visitsLoading = false;
      if (cityCode == null) {
        if (result.error != null) {
          _visitsError = result.error;
        } else {
          _visitsError = null;
          _visits = result.visits;
        }
        return;
      }
      if (result.error != null && result.visits.isEmpty) return;
      final plate = cityCode.toString().padLeft(2, '0');
      final rest = _visits
          .where((visit) => !_samePlaceId(plate, visit.provinceId))
          .toList();
      _visitsError = null;
      _visits = [...result.visits, ...rest]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  void _loadVisitCity(FieldVisit visit) {
    final code = int.tryParse(visit.provinceId);
    if (code != null) _loadVisits(cityCode: code);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _officeController.dispose();
    _personController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  _MapLevel get _level {
    if (_neighborhoodId != null) return _MapLevel.neighborhood;
    if (_districtId != null) return _MapLevel.district;
    if (_provinceId != null) return _MapLevel.province;
    return _MapLevel.country;
  }

  GeoNode? _provinceNode() {
    final id = _provinceId;
    if (id == null) return null;
    final code = int.tryParse(id);
    ProvinceModel? api;
    if (code != null) {
      for (final province in _apiProvinces) {
        if (province.code == code) {
          api = province;
          break;
        }
      }
    }
    final known = FranchiseMapCatalog.find(id, FranchiseMapCatalog.provinces);
    if (api == null && known == null) return null;
    return GeoNode(
      id: id,
      name: api?.name ?? known!.name,
      lat: known?.lat ?? FranchiseMapCatalog.turkey.latitude,
      lng: known?.lng ?? FranchiseMapCatalog.turkey.longitude,
    );
  }

  List<GeoNode> get _provinceNodes {
    return _apiProvinces.map((province) {
      final id = province.code.toString().padLeft(2, '0');
      final known = FranchiseMapCatalog.find(id, FranchiseMapCatalog.provinces);
      return GeoNode(
        id: id,
        name: province.name,
        lat: known?.lat ?? FranchiseMapCatalog.turkey.latitude,
        lng: known?.lng ?? FranchiseMapCatalog.turkey.longitude,
      );
    }).toList();
  }

  LatLng get _selectedProvincePoint {
    final node = _provinceNode();
    if (node == null) return FranchiseMapCatalog.turkey;
    return node.point;
  }

  List<GeoNode> _districtsOf(String provinceId) {
    if (_provinceId != provinceId) return const [];
    final point = _selectedProvincePoint;
    return _apiDistricts
        .map(
          (district) => GeoNode(
            id: district.code.toString(),
            name: district.name,
            parentId: provinceId,
            lat: point.latitude,
            lng: point.longitude,
          ),
        )
        .toList();
  }

  List<GeoNode> _neighborhoodsOf(String districtId) {
    final code = int.tryParse(districtId);
    DistrictModel? district;
    if (code != null) {
      for (final item in _apiDistricts) {
        if (item.code == code) {
          district = item;
          break;
        }
      }
    }
    if (district == null) return const [];
    final point = _selectedProvincePoint;
    return district.quarters
        .map(
          (quarter) => GeoNode(
            id: quarter.code.toString(),
            name: quarter.name,
            parentId: districtId,
            lat: point.latitude,
            lng: point.longitude,
          ),
        )
        .toList();
  }

  GeoNode? _districtNode(String id) {
    final fromApi = _districtsOf(_provinceId ?? '').cast<GeoNode?>().firstWhere(
          (node) => node?.id == id,
          orElse: () => null,
        );
    if (fromApi != null) return fromApi;
    return FranchiseMapCatalog.find(id, FranchiseMapCatalog.districts) ??
        _syntheticDistrict(id);
  }

  GeoNode? _syntheticDistrict(String id) {
    if (!id.endsWith('-merkez')) return null;
    final provinceId = id.replaceFirst('-merkez', '');
    final province = FranchiseMapCatalog.find(
      provinceId,
      FranchiseMapCatalog.provinces,
    );
    if (province == null) return null;
    return GeoNode(
      id: id,
      name: 'Merkez',
      parentId: provinceId,
      lat: province.lat,
      lng: province.lng,
    );
  }

  GeoNode? _neighborhoodNode(String id) {
    final fromApi = _neighborhoodsOf(_districtId ?? '').cast<GeoNode?>().firstWhere(
          (node) => node?.id == id,
          orElse: () => null,
        );
    if (fromApi != null) return fromApi;
    return FranchiseMapCatalog.find(id, FranchiseMapCatalog.neighborhoods) ??
        _syntheticNeighborhood(id);
  }

  GeoNode? _syntheticNeighborhood(String id) {
    if (!id.endsWith('-merkez')) return null;
    final districtId = id.replaceFirst(RegExp(r'-merkez$'), '');
    final district = _districtNode(districtId);
    if (district == null) return null;
    return GeoNode(
      id: id,
      name: 'Merkez',
      parentId: districtId,
      lat: district.lat,
      lng: district.lng,
    );
  }

  List<FieldVisit> _visitsIn({
    String? provinceId,
    String? districtId,
    String? neighborhoodId,
  }) {
    return _visits.where((v) {
      if (neighborhoodId != null) {
        return _samePlaceId(neighborhoodId, v.neighborhoodId);
      }
      if (districtId != null) return _samePlaceId(districtId, v.districtId);
      if (provinceId != null) return _samePlaceId(provinceId, v.provinceId);
      return true;
    }).toList();
  }

  double? _average(List<FieldVisit> list) {
    if (list.isEmpty) return null;
    final sum = list.fold<int>(0, (s, v) => s + v.score);
    return sum / list.length;
  }

  String get _regionLabel {
    final province = _provinceNode();
    final district = _districtId == null ? null : _districtNode(_districtId!);
    final neighborhood =
        _neighborhoodId == null ? null : _neighborhoodNode(_neighborhoodId!);
    if (province == null) return 'Türkiye';
    if (district == null) return province.name;
    if (neighborhood == null) return '${province.name} / ${district.name}';
    return '${province.name} / ${district.name} / ${neighborhood.name}';
  }

  List<FieldVisit> get _scopedVisits => _visitsIn(
        provinceId: _provinceId,
        districtId: _districtId,
        neighborhoodId: _neighborhoodId,
      );

  void _flyTo(LatLng target, double zoom) {
    _pendingCenter = target;
    _pendingZoom = zoom;
    final gen = ++_flyGen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateFly(target, zoom, gen);
    });
  }

  Future<void> _animateFly(LatLng target, double zoom, int gen) async {
    if (!mounted || gen != _flyGen || !_mapReady) return;
    late MapCamera start;
    try {
      start = _mapController.camera;
    } catch (_) {
      return;
    }
    const frames = 24;
    for (var i = 1; i <= frames; i++) {
      if (!mounted || gen != _flyGen) return;
      final t = Curves.easeInOutCubic.transform(i / frames);
      final lat = start.center.latitude +
          (target.latitude - start.center.latitude) * t;
      final lng = start.center.longitude +
          (target.longitude - start.center.longitude) * t;
      _mapController.move(
        LatLng(lat, lng),
        start.zoom + (zoom - start.zoom) * t,
      );
      await Future.delayed(const Duration(milliseconds: 16));
    }
    _pendingCenter = null;
    _pendingZoom = null;
  }

  void _focusSelection() {
    switch (_level) {
      case _MapLevel.country:
        _flyTo(FranchiseMapCatalog.turkey, 6.15);
      case _MapLevel.province:
        final node = _provinceNode();
        if (node != null) _flyTo(node.point, 10.6);
      case _MapLevel.district:
        final node = _districtNode(_districtId!);
        if (node != null) _flyTo(node.point, 12.6);
      case _MapLevel.neighborhood:
        if (_draftPoint != null) {
          _flyTo(_draftPoint!, 15.2);
          break;
        }
        final district =
            _districtId == null ? null : _districtNode(_districtId!);
        final province = _provinceNode();
        final point = district?.point ?? province?.point;
        if (point != null) _flyTo(point, 14.2);
    }
  }

  void _goCountry() {
    setState(() {
      _provinceId = null;
      _districtId = null;
      _neighborhoodId = null;
      _closeSheet();
    });
    _focusSelection();
  }

  void _goProvince() {
    setState(() {
      _districtId = null;
      _neighborhoodId = null;
      _closeSheet();
    });
    _focusSelection();
  }

  void _goDistrict() {
    setState(() {
      _neighborhoodId = null;
      _closeSheet();
    });
    _focusSelection();
  }

  void _closeSheet() {
    _sheetOpen = false;
    _movingPin = false;
    _saveAttempted = false;
    _saving = false;
    _draftCreatedAt = null;
    _editingId = null;
    _draftScore = null;
    _draftNotes = [];
    _draftPoint = null;
    _officeController.clear();
    _personController.clear();
    _noteController.clear();
  }

  void _beginVisit() {
    if (_neighborhoodId == null) {
      _openFilters(hint: 'Ziyaret için önce mahalle seçin.');
      return;
    }
    final point = _draftPoint;
    HapticFeedback.lightImpact();
    setState(() {
      _mode = _BoardMode.map;
      _closeSheet();
      _sheetOpen = true;
      _movingPin = true;
      _draftScore = 3;
      _draftCreatedAt = DateTime.now();
      _draftPoint = point;
    });
  }

  Future<void> _openVisitDetail(FieldVisit visit) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FranchiseVisitDetailScreen(
          visit: visit,
          onUpdated: (updated) {
            if (!mounted) return;
            setState(() {
              _visits = [
                for (final item in _visits)
                  if (item.id == updated.id) updated else item,
              ];
            });
          },
        ),
      ),
    );
  }

  void _highlightVisit(FieldVisit visit) {
    HapticFeedback.selectionClick();
    setState(() {
      _highlightedId = visit.id;
      if (_sheetOpen) _closeSheet();
      _viewZoom = 14.6;
    });
    _flyTo(visit.point, 14.6);
    _loadVisitCity(visit);
  }

  void _addNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _draftNotes = [..._draftNotes, text];
      _noteController.clear();
    });
  }

  Future<void> _saveVisit() async {
    if (_saving) return;
    final office = _officeController.text.trim();
    final person = _personController.text.trim();
    final score = _draftScore;
    final point = _draftPoint;
    if (point == null) {
      setState(() {
        _saveAttempted = true;
        _movingPin = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Haritaya dokunarak konumu işaretleyin.'),
        ),
      );
      return;
    }
    if (office.isEmpty || person.isEmpty || score == null) {
      setState(() => _saveAttempted = true);
      return;
    }
    final notes = [
      ..._draftNotes,
      if (_noteController.text.trim().isNotEmpty) _noteController.text.trim(),
    ];
    if (_editingId != null) {
      setState(() {
        _visits = _visits
            .map(
              (visit) => visit.id == _editingId
                  ? visit.copyWith(
                      officeName: office,
                      personName: person,
                      score: score,
                      notes: notes,
                      lat: point.latitude,
                      lng: point.longitude,
                    )
                  : visit,
            )
            .toList();
        _closeSheet();
      });
      return;
    }
    final cityCode = int.tryParse(_provinceId ?? '');
    if (cityCode == null || _districtId == null || _neighborhoodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ziyaret için önce mahalle seçin.')),
      );
      return;
    }
    final district = _districtNode(_districtId!);
    final neighborhood = _neighborhoodNode(_neighborhoodId!);
    setState(() => _saving = true);
    final result = await _visitRepository.createVisit(
      lat: point.latitude,
      lon: point.longitude,
      score: score,
      cityCode: cityCode,
      officeName: office,
      metPerson: person,
      notes: notes,
      districtCode: int.tryParse(_districtId!),
      quarterCode: int.tryParse(_neighborhoodId!),
      districtName: district?.name,
      quarterName: neighborhood?.name,
    );
    if (!mounted) return;
    if (result.error != null || result.visits.isEmpty) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Ziyaret kaydedilemedi.')),
      );
      return;
    }
    final saved = result.visits.first;
    setState(() {
      _visits = [
        saved,
        ..._visits.where((visit) => visit.id != saved.id && visit.id != _editingId),
      ];
      _closeSheet();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ziyaret kaydedildi')),
    );
  }

  void _deleteVisit() {
    setState(() {
      if (_editingId != null) {
        _visits = _visits.where((v) => v.id != _editingId).toList();
      }
      _closeSheet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _paper,
      drawer: const RoleSidebar(currentPage: 'Franchise Haritası'),
      drawerEdgeDragWidth: 0,
      appBar: _franchiseAppBar(),
      floatingActionButton: _mode == _BoardMode.list
          ? FloatingActionButton.extended(
              onPressed: _beginVisit,
              backgroundColor: _red,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text(
                'Ziyaret Ekle',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: _mode == _BoardMode.list
          ? Column(
              children: [
                _topOverlay(),
                Expanded(child: _buildList()),
              ],
            )
          : _buildMap(),
    );
  }

  // ---------------------------------------------------------------------------
  // Üst katman: bölge çubuğu + harita/liste geçişi + durum bildirimi
  // ---------------------------------------------------------------------------

  Widget _topOverlay() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _regionBar()),
              const SizedBox(width: 8),
              _modeToggle(),
            ],
          ),
          if (_visitsLoading)
            _statusPill(
              icon: Icons.sync_rounded,
              text: 'Ziyaretler yükleniyor…',
            )
          else if (_visitsError != null)
            _statusPill(
              icon: Icons.cloud_off_outlined,
              text: 'Ziyaretler alınamadı',
              actionLabel: 'Tekrar dene',
              onAction: () {
                setState(() {
                  _visitsLoading = true;
                  _visitsError = null;
                });
                _loadVisits();
              },
            ),
        ],
      ),
    );
  }

  Widget _regionBar() {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openFilters(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 4, 0),
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                const Icon(Icons.place_rounded, size: 18, color: _red),
                const SizedBox(width: 6),
                Expanded(child: _buildBreadcrumb()),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: _red),
                      SizedBox(width: 4),
                      Text(
                        'Bölge',
                        style: TextStyle(
                          color: _red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeToggle() {
    Widget item(_BoardMode mode, IconData icon, String tooltip) {
      final selected = _mode == mode;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_mode == mode) return;
            setState(() {
              _mode = mode;
              if (mode == _BoardMode.list) _closeSheet();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 40,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? _red : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 19,
              color: selected ? Colors.white : _muted,
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            item(_BoardMode.map, Icons.map_outlined, 'Harita'),
            item(_BoardMode.list, Icons.view_agenda_outlined, 'Liste'),
          ],
        ),
      ),
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String text,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.center,
        child: Material(
          color: _ink,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ülke / il / ilçe seviyesinde alt özet kartı: bölge, ziyaret sayısı,
  /// ortalama puan, puan lejantı ve ana aksiyonlar.
  Widget _regionSummaryCard() {
    final visits = _scopedVisits;
    final avg = _average(visits);
    final String hint;
    switch (_level) {
      case _MapLevel.country:
        hint = 'Ziyaret eklemek için il, ilçe ve mahalle seçin.';
      case _MapLevel.province:
        hint = 'Ziyaret eklemek için ilçe ve mahalle seçin.';
      case _MapLevel.district:
        hint = 'Ziyaret eklemek için mahalle seçin.';
      case _MapLevel.neighborhood:
        hint = '';
    }
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scoreColor(avg),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    avg == null ? '—' : avg.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _regionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _visitsLoading && visits.isEmpty
                            ? 'Ziyaretler yükleniyor…'
                            : visits.isEmpty
                                ? 'Henüz ziyaret yok'
                                : '${visits.length} ziyaret'
                                    '${avg == null ? '' : ' · Ort. ${avg.toStringAsFixed(1)}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _scoreLegend(),
              ],
            ),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: _muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hint,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: _line),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _openFilters(),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text(
                      'Bölge Seç',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _beginVisit,
                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                    label: const Text(
                      'Ziyaret Ekle',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreLegend() {
    return Tooltip(
      message: 'Puan renkleri: 1 zayıf → 5 çok iyi',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: scoreColor(i),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _franchiseAppBar() {
    return AppBar(
      toolbarHeight: 62,
      backgroundColor: _red,
      surfaceTintColor: _red,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Franchise Haritası',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _visitsLoading && _visits.isEmpty
                ? 'Saha ziyaretleri yükleniyor…'
                : '${_scopedVisits.length} saha ziyareti',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Bölge seç',
          onPressed: _openFilters,
          icon: const Icon(Icons.tune_rounded, color: Colors.white),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMap() {
    final preview = _highlightedVisit;
    final dockOpen = preview != null || _neighborhoodId != null;
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: FranchiseMapCatalog.turkey,
            initialZoom: 6.15,
            minZoom: 5,
            maxZoom: 18,
            backgroundColor: const Color(0xFFD6E2EE),
            onMapReady: () {
              _mapReady = true;
              final center = _pendingCenter;
              final zoom = _pendingZoom;
              if (center != null && zoom != null) {
                _flyTo(center, zoom);
              }
            },
            onTap: (_, point) {
              if (_sheetOpen && _movingPin) {
                setState(() => _draftPoint = point);
                return;
              }
              if (_highlightedId != null) {
                setState(() => _highlightedId = null);
              }
            },
            onMapEvent: (event) {
              if (event.source == MapEventSource.mapController) return;
              if (event is! MapEventMoveEnd &&
                  event is! MapEventFlingAnimationEnd &&
                  event is! MapEventDoubleTapZoomEnd) {
                return;
              }
              final zoom = event.camera.zoom;
              if ((zoom - _viewZoom).abs() < 0.2) return;
              setState(() => _viewZoom = zoom);
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
              userAgentPackageName: 'com.zecorner.app',
              maxNativeZoom: 19,
              maxZoom: 19,
            ),
            MarkerLayer(markers: _visitMarkers()),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _topOverlay(),
        ),
        Positioned(
          right: 12,
          bottom: _sheetOpen
              ? 20
              : preview != null
                  ? 212
                  : dockOpen
                      ? 108
                      : 196,
          child: _zoomStack(),
        ),
        if (_movingPin)
          Positioned(
            top: 68,
            left: 24,
            right: 24,
            child: Center(child: _moveHint()),
          ),
        if (preview != null && !_sheetOpen)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _visitPreview(preview),
          )
        else if (_neighborhoodId != null && !_sheetOpen)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _neighborhoodDock(),
          )
        else if (!_sheetOpen)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _regionSummaryCard(),
          ),
        if (_sheetOpen)
          Positioned(
            left: 10,
            right: 10,
            bottom: 10 + MediaQuery.viewInsetsOf(context).bottom,
            child: _visitSheet(),
          ),
      ],
    );
  }

  FieldVisit? get _highlightedVisit {
    if (_highlightedId == null) return null;
    for (final visit in _visits) {
      if (visit.id == _highlightedId) return visit;
    }
    return null;
  }

  List<Marker> _visitMarkers() {
    final markers = <Marker>[];
    final placed = _scopedVisits.where((visit) {
      return visit.lat.abs() > 0.01 || visit.lng.abs() > 0.01;
    }).toList();
    final clusters = List<_VisitCluster>.of(_clusterVisits(placed, _viewZoom));
    clusters.sort((a, b) {
      if (a.single?.id == _highlightedId) return 1;
      if (b.single?.id == _highlightedId) return -1;
      return 0;
    });
    for (final cluster in clusters) {
      final selected = cluster.single?.id == _highlightedId;
      markers.add(
        Marker(
          point: cluster.center,
          width: selected ? 210 : 188,
          height: cluster.subtitle == null ? 58 : 70,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () => _onClusterTap(cluster),
            child: _placeCard(
              title: cluster.title,
              subtitle: cluster.subtitle,
              score: cluster.score,
              selected: selected,
            ),
          ),
        ),
      );
    }
    if (_draftPoint != null && _editingId == null) {
      markers.add(
        Marker(
          point: _draftPoint!,
          width: 54,
          height: 54,
          alignment: Alignment.center,
          child: _scorePin(_draftScore ?? 3, draft: true),
        ),
      );
    }
    return markers;
  }

  List<_VisitCluster> _clusterVisits(List<FieldVisit> visits, double zoom) {
    if (visits.isEmpty) return [];
    if (zoom >= 12.4) {
      return visits.map(_VisitCluster.one).toList();
    }
    final groups = <String, List<FieldVisit>>{};
    for (final visit in visits) {
      final city = _visitCity(visit);
      final district = _visitDistrict(visit);
      final key = zoom < 8.4 || district.isEmpty
          ? city
          : '$city|$district';
      groups.putIfAbsent(key, () => []).add(visit);
    }
    return groups.values.map((group) {
      if (group.length == 1 && zoom >= 8.4) return _VisitCluster.one(group.first);
      final title = zoom < 8.4 || _visitDistrict(group.first).isEmpty
          ? _visitCity(group.first)
          : _visitDistrict(group.first);
      return _VisitCluster.many(group, title);
    }).toList();
  }

  void _onClusterTap(_VisitCluster cluster) {
    final only = cluster.single;
    if (only != null) {
      _highlightVisit(only);
      return;
    }
    final nextZoom = _viewZoom < 8.4 ? 10.6 : 13.4;
    setState(() => _viewZoom = nextZoom);
    _flyTo(cluster.center, nextZoom);
  }

  String _visitCity(FieldVisit visit) {
    final named = visit.ilName?.trim();
    if (named != null && named.isNotEmpty) return named;
    return _provinceName(visit.provinceId) ?? 'Bölge';
  }

  String _visitDistrict(FieldVisit visit) => visit.ilceName?.trim() ?? '';

  Widget _placeCard({
    required String title,
    required String? subtitle,
    required double? score,
    required bool selected,
  }) {
    final color = scoreColor(score);
    final label = score == null
        ? '—'
        : score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : _line,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -5),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: selected ? color : _line),
                  bottom: BorderSide(color: selected ? color : _line),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _visitPreview(FieldVisit visit) {
    final notes = visit.notes.where((note) => note.trim().isNotEmpty).join(' · ');
    final place = _visitPlace(visit);
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scoreColor(visit.score),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${visit.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.officeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        visit.personName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (place.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                place,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _ink, fontSize: 13),
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF475467),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _highlightedId = null),
                  child: const Text('Kapat'),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _openVisitDetail(visit),
                  child: const Text('Detay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scorePin(int score, {bool draft = false}) {
    final color = score == 0 ? const Color(0xFFF5B301) : scoreColor(score);
    return Container(
      width: draft ? 46 : 36,
      height: draft ? 46 : 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: draft ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: draft ? 18 : 8,
            spreadRadius: draft ? 2 : 0,
          ),
        ],
      ),
      child: Text(
        score == 0 ? '3' : '$score',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: draft ? 18 : 14,
        ),
      ),
    );
  }

  Widget _buildBreadcrumb({bool onBar = false}) {
    final province = _provinceNode();
    final district = _districtId == null ? null : _districtNode(_districtId!);
    final neighborhood =
        _neighborhoodId == null ? null : _neighborhoodNode(_neighborhoodId!);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: EdgeInsets.only(top: onBar ? 2 : 0),
        child: Row(
          children: [
            _crumb('Türkiye', _provinceId == null, _goCountry, onBar: onBar),
            if (province != null) ...[
              Icon(Icons.chevron_right, size: 14, color: onBar ? Colors.white70 : _muted),
              _crumb(province.name, _districtId == null, _goProvince, onBar: onBar),
            ],
            if (district != null) ...[
              Icon(Icons.chevron_right, size: 14, color: onBar ? Colors.white70 : _muted),
              _crumb(district.name, _neighborhoodId == null, _goDistrict, onBar: onBar),
            ],
            if (neighborhood != null) ...[
              Icon(Icons.chevron_right, size: 14, color: onBar ? Colors.white70 : _muted),
              _crumb(neighborhood.name, true, () {}, onBar: onBar),
            ],
          ],
        ),
      ),
    );
  }

  Widget _crumb(
    String label,
    bool active,
    VoidCallback onTap, {
    bool onBar = false,
  }) {
    final color = onBar
        ? (active ? Colors.white : Colors.white70)
        : (active ? _red : _ink);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: onBar ? 1 : 3,
          vertical: onBar ? 0 : 6,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: onBar ? 12 : 13,
          ),
        ),
      ),
    );
  }

  Widget _zoomStack() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _mapTool(Icons.add, () => _zoomBy(1)),
          Container(width: 22, height: 1, color: _line),
          _mapTool(Icons.remove, () => _zoomBy(-1)),
          Container(width: 22, height: 1, color: _line),
          _mapTool(Icons.near_me_outlined, _focusSelection),
        ],
      ),
    );
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    final zoom = (camera.zoom + delta).clamp(5.0, 18.0);
    _mapController.move(camera.center, zoom);
    setState(() => _viewZoom = zoom);
  }

  Widget _mapTool(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 36,
        child: Icon(icon, size: 18, color: _ink),
      ),
    );
  }

  Widget _moveHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Haritaya tıklayarak konum değiştirin',
        style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _neighborhoodDock() {
    final node = _neighborhoodNode(_neighborhoodId!);
    final visits = _visitsIn(neighborhoodId: _neighborhoodId);
    final avg = _average(visits);
    final place = _regionLabel;
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scoreColor(avg),
                shape: BoxShape.circle,
              ),
              child: Text(
                avg == null ? '—' : avg.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$place · ${visits.length} ziyaret',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _beginVisit,
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text(
                'Ziyaret Ekle',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visitSheet() {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;
    final missingOffice = _saveAttempted && _officeController.text.trim().isEmpty;
    final missingPerson = _saveAttempted && _personController.text.trim().isEmpty;
    final missingScore = _saveAttempted && _draftScore == null;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Material(
        color: Colors.white,
        elevation: 16,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(26),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAECF0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ZİYARET DETAYI',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _editingId == null
                              ? 'Yeni saha ziyareti'
                              : 'Saha ziyareti',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(_closeSheet),
                    icon: const Icon(Icons.close, color: _muted),
                  ),
                ],
              ),
              Text(
                _regionLabel,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              if (_draftCreatedAt != null)
                Text(
                  'Oluşturulma: ${_formatVisitStamp(_draftCreatedAt!)}',
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _movingPin ? _red : const Color(0xFFFFF2F1),
                  foregroundColor: _movingPin ? Colors.white : _red,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => setState(() => _movingPin = !_movingPin),
                icon: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                ),
                label: Text(
                  _movingPin ? 'Konum değiştirmeyi bitir' : 'Konumu değiştir',
                ),
              ),
              const SizedBox(height: 14),
              _fieldLabel('Ofis adı'),
              TextField(
                controller: _officeController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  'Örn. Kadıköy Ofisi',
                  error: missingOffice,
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Görüşülen kişi'),
              TextField(
                controller: _personController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  'Örn. Ayşe Yılmaz',
                  error: missingPerson,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    'Puan',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _draftScore == null ? '—/5' : '$_draftScore/5',
                    style: TextStyle(
                      color: missingScore ? _red : _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _scoreChoice(i),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Açıklama (isteğe bağlı)',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNote,
                    icon: const Icon(Icons.add, size: 16, color: _red),
                    label: const Text(
                      'Madde ekle',
                      style: TextStyle(color: _red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _noteController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addNote(),
                decoration: _inputDecoration('Madde yazın'),
              ),
              if (_draftNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (var i = 0; i < _draftNotes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _draftNotes[i],
                            style: const TextStyle(color: _ink, fontSize: 13.5),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() {
                            _draftNotes = [..._draftNotes]..removeAt(i);
                          }),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _deleteVisit,
                    child: Text(
                      'Ziyareti sil',
                      style: const TextStyle(
                        color: _red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _saveVisit,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreChoice(int value) {
    final selected = _draftScore == value;
    final color = scoreColor(value);
    return GestureDetector(
      onTap: () => setState(() => _draftScore = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: selected ? 42 : 36,
        height: selected ? 42 : 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: _ink,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {bool error = false}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: error ? _red : _line),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF667085), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red, width: 1.4),
      ),
    );
  }

  String _formatVisitStamp(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.${local.year} $hour:$minute';
  }

  String _formatVisitDate(DateTime date) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _visitPlace(FieldVisit visit) {
    final named = [
      visit.ilName,
      visit.ilceName,
      visit.mahalleName,
    ].whereType<String>().where((name) => name.trim().isNotEmpty);
    final fromApi = named.join('  ·  ');
    if (fromApi.isNotEmpty) return fromApi;
    final provinceName = _provinceName(visit.provinceId);
    final district = visit.districtId.isEmpty
        ? null
        : _districtNode(visit.districtId);
    final neighborhood = visit.neighborhoodId.isEmpty
        ? null
        : _neighborhoodNode(visit.neighborhoodId);
    return [
      provinceName,
      district?.name,
      neighborhood?.name,
    ].whereType<String>().join('  ·  ');
  }

  String? _provinceName(String provinceId) {
    final code = int.tryParse(provinceId);
    if (code != null) {
      for (final province in _apiProvinces) {
        if (province.code == code) return province.name;
      }
    }
    return FranchiseMapCatalog.find(
      provinceId,
      FranchiseMapCatalog.provinces,
    )?.name;
  }

  Widget _buildList() {
    final visits = _scopedVisits;
    if (_visitsLoading && visits.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _red),
      );
    }
    if (_visitsError != null && visits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: _muted),
              const SizedBox(height: 12),
              Text(
                _visitsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  setState(() {
                    _visitsLoading = true;
                    _visitsError = null;
                  });
                  _loadVisits();
                },
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }
    if (visits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 34,
                  color: _red,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Bu bölgede ziyaret yok',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_regionLabel için kayıtlı saha ziyareti bulunmuyor. '
                'Mahalle seçip yeni bir ziyaret ekleyebilirsiniz.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, height: 1.35),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: _line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _openFilters(),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Bölge Seç'),
              ),
            ],
          ),
        ),
      );
    }
    final avg = _average(visits);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Text(
                '${visits.length} ziyaret',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (avg != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor(avg).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ort. ${avg.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: scoreColor(avg),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
            itemCount: visits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _visitListCard(visits[index]),
          ),
        ),
      ],
    );
  }

  Widget _visitListCard(FieldVisit visit) {
    final notes = visit.notes.where((n) => n.trim().isNotEmpty).toList();
    final color = scoreColor(visit.score);
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _line),
      ),
      child: InkWell(
        onTap: () => _openVisitDetail(visit),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              visit.officeName,
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${visit.score}/5',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _listMeta(Icons.person_outline, visit.personName),
                      if (visit.createdByTitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _listMeta(
                          Icons.badge_outlined,
                          visit.createdByTitle,
                        ),
                      ],
                      if (_visitPlace(visit).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _listMeta(Icons.place_outlined, _visitPlace(visit)),
                      ],
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _paper,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            notes.join('  ·  '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF475467),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _formatVisitDate(visit.createdAt),
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listMeta(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: _muted),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _ink, fontSize: 13, height: 1.3),
          ),
        ),
      ],
    );
  }

  Future<void> _openFilters({String? hint}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            final province = _provinceNode();
            final district =
                _districtId == null ? null : _districtNode(_districtId!);
            final neighborhood = _neighborhoodId == null
                ? null
                : _neighborhoodNode(_neighborhoodId!);
            final step = _neighborhoodId != null
                ? 3
                : _districtId != null
                    ? 2
                    : _provinceId != null
                        ? 1
                        : 0;
            return Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAECF0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Bölge seç',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step == 0
                          ? 'Önce ili seçin, sonra ilçe ve mahalle açılır.'
                          : '$_regionLabel  ·  ${_scopedVisits.length} ziyaret',
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hint,
                          style: const TextStyle(
                            color: _red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _filterStep(
                      index: 1,
                      title: 'İl',
                      value: province?.name ?? 'Seçin',
                      done: province != null,
                      enabled: true,
                      onTap: () async {
                        if (_apiProvinces.isEmpty) await _loadApiProvinces();
                        if (!context.mounted) return;
                        final id = await _pick(
                          context,
                          'İl',
                          _provinceNodes,
                          _provinceId,
                        );
                        if (id == null || !mounted) return;
                        setState(() {
                          _provinceId = id.isEmpty ? null : id;
                          _districtId = null;
                          _neighborhoodId = null;
                          _apiDistricts = [];
                          _draftPoint = null;
                        });
                        setSheet(() {});
                        _focusSelection();
                        final cityCode = id.isEmpty ? null : int.tryParse(id);
                        if (cityCode != null) {
                          await _ensureDistricts(cityCode);
                        }
                        if (!mounted) return;
                        if (context.mounted) setSheet(() {});
                        _loadVisits(cityCode: cityCode).whenComplete(() {
                          if (context.mounted) setSheet(() {});
                        });
                      },
                    ),
                    _filterStep(
                      index: 2,
                      title: 'İlçe',
                      value: district?.name ??
                          (_provinceId == null
                              ? 'Önce il seçin'
                              : _districtsLoading
                                  ? 'Yükleniyor'
                                  : 'Seçin'),
                      done: district != null,
                      enabled: _provinceId != null,
                      onTap: () async {
                        final cityCode = int.tryParse(_provinceId ?? '');
                        if (cityCode != null) await _ensureDistricts(cityCode);
                        if (!context.mounted) return;
                        setSheet(() {});
                        final id = await _pick(
                          context,
                          'İlçe',
                          _districtsOf(_provinceId!),
                          _districtId,
                        );
                        if (id == null || !mounted) return;
                        setState(() {
                          _districtId = id.isEmpty ? null : id;
                          _neighborhoodId = null;
                          _draftPoint = null;
                        });
                        setSheet(() {});
                        _focusSelection();
                      },
                    ),
                    _filterStep(
                      index: 3,
                      title: 'Mahalle',
                      value: neighborhood?.name ??
                          (_districtId == null ? 'Önce ilçe seçin' : 'Seçin'),
                      done: neighborhood != null,
                      enabled: _districtId != null,
                      onTap: () async {
                        final id = await _pick(
                          context,
                          'Mahalle',
                          _neighborhoodsOf(_districtId!),
                          _neighborhoodId,
                        );
                        if (id == null || !mounted) return;
                        setState(() {
                          _neighborhoodId = id.isEmpty ? null : id;
                          _draftPoint = null;
                        });
                        setSheet(() {});
                        _focusSelection();
                      },
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ink,
                              side: const BorderSide(color: _line),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _provinceId = null;
                                _districtId = null;
                                _neighborhoodId = null;
                                _closeSheet();
                              });
                              setSheet(() {});
                              _focusSelection();
                              _loadVisits().whenComplete(() {
                                if (context.mounted) setSheet(() {});
                              });
                            },
                            child: const Text('Temizle'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _red,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() => _mode = _BoardMode.map);
                              _focusSelection();
                            },
                            child: const Text('Haritada göster'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterStep({
    required int index,
    required String title,
    required String value,
    required bool done,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final accent = done ? _red : (enabled ? _ink : const Color(0xFFD0D5DD));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: enabled ? Colors.white : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: done ? const Color(0xFFFFD5D3) : _line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? _red : const Color(0xFFF2F4F7),
                    shape: BoxShape.circle,
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$index',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled ? _ink : _muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: enabled ? _muted : const Color(0xFFD0D5DD),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _pick(
    BuildContext sheetContext,
    String title,
    List<GeoNode> nodes,
    String? selected,
  ) async {
    return showModalBottomSheet<String?>(
      context: sheetContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheet) {
            final needle = _foldSearch(query.trim());
            final filtered = nodes
                .where((n) => _foldSearch(n.name).contains(needle))
                .toList();
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.62,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAECF0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: TextField(
                        decoration: _inputDecoration('$title ara'),
                        onChanged: (v) => setSheet(() => query = v),
                      ),
                    ),
                    ListTile(
                      title: const Text('Tümü'),
                      trailing: selected == null
                          ? const Icon(Icons.check, color: _red)
                          : null,
                      onTap: () => Navigator.pop(context, ''),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final node = filtered[index];
                          final picked = node.id == selected;
                          return ListTile(
                            selected: picked,
                            selectedTileColor: const Color(0xFFFFF2F1),
                            title: Text(
                              node.name,
                              style: TextStyle(
                                color: _ink,
                                fontWeight:
                                    picked ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            trailing: picked
                                ? const Icon(Icons.check, color: _red)
                                : null,
                            onTap: () => Navigator.pop(context, node.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VisitCluster {
  final LatLng center;
  final String title;
  final String? subtitle;
  final double? score;
  final FieldVisit? single;

  const _VisitCluster({
    required this.center,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.single,
  });

  factory _VisitCluster.one(FieldVisit visit) {
    final person = visit.personName.trim();
    return _VisitCluster(
      center: visit.point,
      title: visit.officeName.trim().isEmpty ? 'Ziyaret' : visit.officeName,
      subtitle: person.isEmpty ? null : person,
      score: visit.score.toDouble(),
      single: visit,
    );
  }

  factory _VisitCluster.many(List<FieldVisit> visits, String title) {
    var lat = 0.0;
    var lng = 0.0;
    var sum = 0;
    for (final visit in visits) {
      lat += visit.lat;
      lng += visit.lng;
      sum += visit.score;
    }
    final count = visits.length;
    return _VisitCluster(
      center: LatLng(lat / count, lng / count),
      title: title,
      subtitle: '$count ziyaret',
      score: sum / count,
      single: null,
    );
  }
}

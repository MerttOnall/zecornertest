import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zecorner/presentation/screens/offers/add_offers_screen.dart';
import 'package:zecorner/presentation/screens/offers/edit_offers_screen.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/models/promo/promo_api_model.dart';
import 'package:zecorner/infrastructure/promo/promo_api_repository.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:dio/dio.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({Key? key}) : super(key: key);

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  static const Color _accent = Color(0xFFE53935);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  final Set<String> _selectedCategories = {};
  String _selectedTypeLabel = 'Hepsi';
  String? _selectedTypeApiValue;
  String search = '';
  bool isActive = true;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // API related variables
  late final PromoApiRepository _promoRepository;
  List<PromoApiModel> _promos = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  /// Arama/filtre değişince artar; eski HTTP cevapları yoksayılır.
  int _loadGeneration = 0;
  final ScrollController _scrollController = ScrollController();

  /// Yalnızca admin oluşturur / düzenler / siler.
  bool _isAdmin = false;

  /// Web ile uyumlu kategori listesi (çoklu seçim + API/istemci filtresi)
  static const List<String> _categoryOptions = [
    'Giyim',
    'Elektronik',
    'Gıda',
    'Kozmetik',
    'Seyahat',
    'Konaklama',
    'Otomobil',
    'Eğlence',
    'Yeme - İçme',
    'Diğer',
    'Sağlık',
    'Eğitim',
    'Hizmet',
    'Market',
  ];

  /// Tür seçenekleri: görünen metin → API `type` (JSON: percent-sale, price-cut, promo-code, gift-card)
  static const List<MapEntry<String, String?>> _typeOptions = [
    MapEntry('Hepsi', null),
    MapEntry('Yüzdelik İndirim', 'percent-sale'),
    MapEntry('Fiyat İndirimi', 'price-cut'),
    MapEntry('Promosyon Kodu', 'promo-code'),
    MapEntry('Hediye Kartı', 'gift-card'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = search;
    _promoRepository = PromoApiRepository(dio: Dio());
    
    // Scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && 
          _hasMoreData && !_isLoading) {
        _loadPromos(isLoadMore: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
    });

    // Initial load
    _loadPromos();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final authCubit = context.read<AuthCubit>();
      final roleCodes = await authCubit.getUserRoleCodes();
      if (!mounted) return;
      setState(() {
        _isAdmin = roleCodes.contains('role_admin') || authCubit.isAdmin;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<PromoApiModel> get _visiblePromos {
    return _promos.where(_passesClientFilters).toList();
  }

  bool _passesClientFilters(PromoApiModel p) {
    // Durum: Aktif=1 / Pasif=0 (API status alanı)
    if (isActive && p.status != 1) return false;
    if (!isActive && p.status != 0) return false;

    if (!_promoMatchesSearch(p)) return false;
    if (_selectedCategories.isNotEmpty) {
      final hit = _selectedCategories.any((sel) {
        final sl = sel.trim();
        if (sl.isEmpty) return false;
        return p.categories.any((c) => _categoryRoughMatch(c, sl));
      });
      if (!hit) return false;
    }
    if (_selectedTypeApiValue != null &&
        !_promoMatchesType(p, _selectedTypeApiValue!)) {
      return false;
    }
    return true;
  }

  String _normalizeSearchText(String s) {
    return s.trim().toLowerCase();
  }

  /// Ad, marka ve promo koduna göre arama (case-insensitive).
  bool _promoMatchesSearch(PromoApiModel p) {
    final q = _normalizeSearchText(search);
    if (q.isEmpty) return true;
    final name = _normalizeSearchText(p.name);
    final brand = _normalizeSearchText(p.brand);
    final code = _normalizeSearchText(p.promoCode);
    return name.contains(q) || brand.contains(q) || code.contains(q);
  }

  bool _categoryRoughMatch(String promoCategory, String selectedLabel) {
    final p = _normalizeSearchText(promoCategory);
    final s = _normalizeSearchText(selectedLabel);
    if (p.isEmpty || s.isEmpty) return false;
    if (p == s || p.contains(s) || s.contains(p)) return true;

    const synonymGroups = <Set<String>>{
      {'hizmet', 'service', 'servis'},
      {'market', 'grocery', 'marketplace', 'food'},
      {'eğitim', 'education', 'training', 'egitim'},
      {'diğer', 'other', 'diger'},
      {'giyim', 'clothing', 'fashion'},
      {'elektronik', 'electronics'},
      {'gıda', 'food', 'gida'},
      {'kozmetik', 'cosmetics'},
      {'seyahat', 'travel'},
      {'konaklama', 'accommodation', 'lodging'},
      {'otomobil', 'auto', 'car', 'automobile'},
      {'eğlence', 'entertainment', 'eglence'},
      {'yeme - içme', 'yeme içme', 'yeme-içme', 'catering'},
      {'sağlık', 'health', 'saglik'},
    };

    for (final g in synonymGroups) {
      final pin = g.any((k) => p == k || p.contains(k));
      final sin = g.any((k) => s == k || s.contains(k));
      if (pin && sin) return true;
    }
    return false;
  }

  bool _promoMatchesType(PromoApiModel p, String apiValue) {
    final t = p.type.toLowerCase().replaceAll('_', '-').trim();
    final v = apiValue.toLowerCase().replaceAll('_', '-').trim();
    if (t.isEmpty) return false;
    if (t == v) return true;

    if (v == 'percent-sale') {
      return t.contains('percent') || t == 'percentsale';
    }
    if (v == 'price-cut' || v == 'price-sale') {
      return t == 'price-cut' ||
          t == 'price-sale' ||
          (t.contains('price') && !t.contains('percent'));
    }
    if (v == 'promo-code' || v == 'discount-code') {
      return t == 'promo-code' ||
          t.contains('promo-code') ||
          t.contains('discount-code') ||
          (t.contains('code') && !t.contains('gift'));
    }
    if (v == 'gift-card' || v == 'gift-voucher') {
      return t == 'gift-card' ||
          t.contains('gift') ||
          t.contains('voucher') ||
          t.contains('hediye');
    }
    return false;
  }

  void _applySearchFromField({bool immediate = false}) {
    _searchDebounce?.cancel();
    void run() {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      setState(() {
        search = _searchController.text.trim();
      });
    }

    if (immediate) {
      run();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), run);
  }

  void _scheduleSearchReload() => _applySearchFromField(immediate: false);

  void _reloadFirstPage() {
    setState(() {
      _currentPage = 1;
      _promos.clear();
      _hasMoreData = true;
    });
    _loadPromos();
  }

  Future<void> _loadPromos({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      _loadGeneration++;
    }
    final gen = _loadGeneration;

    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    } else {
      if (_currentPage > _totalPages) {
        if (mounted) setState(() => _hasMoreData = false);
        return;
      }
      setState(() => _isLoading = true);
    }

    final pageToRequest = isLoadMore ? _currentPage : 1;
    // Web: page + pageSize (+ opsiyonel type). Filtrelerin tamamı istemcide uygulanır.
    final result = await _promoRepository.getPromos(
      page: pageToRequest,
      pageSize: 9999,
      search: null,
      category: null,
      status: null,
      promoType: null,
    );

    if (!mounted || gen != _loadGeneration) return;

    result.fold(
      (failure) {
        if (!mounted || gen != _loadGeneration) return;
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
          if (!isLoadMore) _promos.clear();
        });
      },
      (response) {
        if (!mounted || gen != _loadGeneration) return;
        setState(() {
          _isLoading = false;
          if (!isLoadMore) {
            _promos = response.promos;
          } else {
            _promos.addAll(response.promos);
          }
          _currentPage = response.page + 1;
          _totalPages = response.totalPages;
          _hasMoreData = response.page < response.totalPages;
        });
      },
    );
  }

  String _categoryFieldSummary() {
    if (_selectedCategories.isEmpty) return 'Çoklu Kategori Seçin...';
    if (_selectedCategories.length <= 2) {
      return _selectedCategories.join(', ');
    }
    return '${_selectedCategories.length} kategori seçildi';
  }

  Future<void> _openCategoryBottomSheet() {
    final catSearch = TextEditingController();
    final draft = Set<String>.from(_selectedCategories);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              final q = catSearch.text.trim().toLowerCase();
              final items =
                  _categoryOptions.where((c) => c.toLowerCase().contains(q)).toList();

              return Container(
                height: MediaQuery.of(ctx).size.height * 0.72,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Kategori',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: catSearch,
                        onChanged: (_) => setModal(() {}),
                        decoration: InputDecoration(
                          hintText: 'Ara...',
                          suffixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final c = items[i];
                          return CheckboxListTile(
                            value: draft.contains(c),
                            activeColor: _accent,
                            title: Text(c, style: const TextStyle(fontSize: 15)),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (v) {
                              setModal(() {
                                if (v == true) {
                                  draft.add(c);
                                } else {
                                  draft.remove(c);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => setModal(() => draft.clear()),
                            child: Text('Seçimi temizle', style: TextStyle(color: Colors.grey[700])),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('İptal'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategories
                                  ..clear()
                                  ..addAll(draft);
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Uygula'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openTypeBottomSheet() {
    final typeSearch = TextEditingController();
    String draftLabel = _selectedTypeLabel;
    String? draftApi = _selectedTypeApiValue;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              final q = typeSearch.text.trim().toLowerCase();
              final items = _typeOptions
                  .where((e) => e.key.toLowerCase().contains(q))
                  .toList();

              return Container(
                height: MediaQuery.of(ctx).size.height * 0.65,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Tür',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: typeSearch,
                        onChanged: (_) => setModal(() {}),
                        decoration: InputDecoration(
                          hintText: 'Ara...',
                          suffixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final e = items[i];
                          return RadioListTile<String>(
                            value: e.key,
                            groupValue: draftLabel,
                            activeColor: _accent,
                            title: Text(e.key, style: const TextStyle(fontSize: 15)),
                            onChanged: (_) {
                              setModal(() {
                                draftLabel = e.key;
                                draftApi = e.value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('İptal'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedTypeLabel = draftLabel;
                                _selectedTypeApiValue = draftApi;
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Uygula'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _labeledDropdownRow({
    required String label,
    required String displayText,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isPlaceholder ? Colors.grey[500] : Colors.grey[900],
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[700]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _accent.withOpacity(0.12) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _accent : Colors.grey.shade300,
              width: selected ? 1.6 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: selected ? _accent : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  void _clearListFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedTypeLabel = 'Hepsi';
      _selectedTypeApiValue = null;
      isActive = true;
    });
  }

  int _sheetFilterCount() {
    var count = 0;
    if (_selectedCategories.isNotEmpty) count++;
    if (_selectedTypeLabel != 'Hepsi') count++;
    if (!isActive) count++;
    return count;
  }

  Future<void> _openFilterSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4E6EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text(
                              'Filtrele',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D2E),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _sheetFilterCount() == 0
                                  ? null
                                  : () {
                                      _clearListFilters();
                                      setModal(() {});
                                    },
                              child: const Text('Sıfırla'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _labeledDropdownRow(
                          label: 'Kategori',
                          displayText: _categoryFieldSummary(),
                          isPlaceholder: _selectedCategories.isEmpty,
                          onTap: () async {
                            await _openCategoryBottomSheet();
                            if (ctx.mounted) setModal(() {});
                          },
                        ),
                        const SizedBox(height: 14),
                        _labeledDropdownRow(
                          label: 'Tür',
                          displayText: _selectedTypeLabel,
                          isPlaceholder: _selectedTypeLabel == 'Hepsi',
                          onTap: () async {
                            await _openTypeBottomSheet();
                            if (ctx.mounted) setModal(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Durum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _statusPill(
                                label: 'Aktif',
                                selected: isActive,
                                onTap: () {
                                  if (isActive) return;
                                  setState(() => isActive = true);
                                  setModal(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statusPill(
                                label: 'Pasif',
                                selected: !isActive,
                                onTap: () {
                                  if (!isActive) return;
                                  setState(() => isActive = false);
                                  setModal(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Kampanyaları göster',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 16, color: _accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeFilterChips() {
    final chips = <Widget>[];
    if (_selectedCategories.isNotEmpty) {
      chips.add(_filterChip(_categoryFieldSummary(), () {
        setState(_selectedCategories.clear);
      }));
    }
    if (_selectedTypeLabel != 'Hepsi') {
      chips.add(_filterChip(_selectedTypeLabel, () {
        setState(() {
          _selectedTypeLabel = 'Hepsi';
          _selectedTypeApiValue = null;
        });
      }));
    }
    if (!isActive) {
      chips.add(_filterChip('Pasif', () => setState(() => isActive = true)));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  /// Arama satırı sayfada kalır; kategori, tür ve durum alttan açılır.
  Widget _buildFilterCard() {
    final filterCount = _sheetFilterCount();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    setState(() {});
                    _scheduleSearchReload();
                  },
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                    _applySearchFromField(immediate: true);
                  },
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1A1D2E)),
                  decoration: InputDecoration(
                    hintText: 'Kampanya ara',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500], size: 22),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Temizle',
                            onPressed: () {
                              _searchDebounce?.cancel();
                              _searchController.clear();
                              setState(() => search = '');
                              _applySearchFromField(immediate: true);
                            },
                            icon: Icon(Icons.close_rounded, color: Colors.grey[500], size: 18),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: filterCount > 0 ? _accent : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _openFilterSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: filterCount > 0 ? Colors.white : const Color(0xFF3A3D4D),
                        ),
                        if (filterCount > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 16,
                              height: 16,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$filterCount',
                                style: const TextStyle(
                                  color: _accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          _activeFilterChips(),
          if (_isAdmin) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddOffersScreen()),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'Yeni Kampanya',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCampaignSlivers() {
    final visible = _visiblePromos;
    final bottomInset = MediaQuery.of(context).padding.bottom + 24;

    if (_isLoading && _promos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Kampanyalar yükleniyor…'),
              ],
            ),
          ),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadPromos(),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (_promos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Kampanya bulunamadı',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    if (visible.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_off_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Seçili filtrelere uygun kampanya yok',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == visible.length) {
                if (_isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (_hasMoreData) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => _loadPromos(isLoadMore: true),
                        child: const Text('Daha Fazla Yükle'),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.only(bottom: i < visible.length - 1 ? 16 : 0),
                child: ModernOfferCard(
                  promo: visible[i],
                  listContext: context,
                  onListRefresh: _reloadFirstPage,
                  canManage: _isAdmin,
                ),
              );
            },
            childCount: visible.length + (_hasMoreData ? 1 : 0),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'Kampanyalar');
        },
      ),
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpen = isOpened;
        });
      },
      drawerScrimColor: Colors.black54,
      drawerEdgeDragWidth: 0,
      appBar: AdminPanelAppBar(
        title: "Kampanyalar",
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: GestureDetector(
        onTap: () {
          if (_isDrawerOpen) {
            _scaffoldKey.currentState?.closeDrawer();
          }
        },
        child: AbsorbPointer(
          absorbing: _isDrawerOpen,
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildFilterCard()),
                ..._buildCampaignSlivers(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AdminNavbar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

}

class ModernOfferCard extends StatelessWidget {
  final PromoApiModel promo;
  final BuildContext listContext;
  final VoidCallback onListRefresh;
  final bool canManage;

  const ModernOfferCard({
    required this.promo,
    required this.listContext,
    required this.onListRefresh,
    this.canManage = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => OfferDetailScreen(
            promo: promo,
            listContext: listContext,
            canManage: canManage,
          ),
        ).then((deleted) {
          if (deleted != true) return;
          onListRefresh();
          if (!listContext.mounted) return;
          ScaffoldMessenger.maybeOf(listContext)?.showSnackBar(
            const SnackBar(content: Text('Kampanya silindi')),
          );
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (etiketler görsel üzerinde değil)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 160,
                child: ImageUtils.isValidS3Id(promo.bannerPicture)
                    ? Image.network(
                        ImageUtils.getS3FileUrl(promo.bannerPicture),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: const Color(0xFFE53935),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.campaign_outlined,
                            color: Colors.grey[400],
                            size: 48,
                          ),
                        ),
                      ),
              ),
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          promo.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          promo.categoryDisplay,
                          style: const TextStyle(
                            color: Color.fromRGBO(238, 46, 36, 1),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          promo.discountDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: promo.isActive ? Colors.green[600] : Colors.grey[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          promo.recordStatusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Description
                  if (promo.description.isNotEmpty)
                    Text(
                      promo.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 12),
                  
                  // Bitiş tarihi + (süresi dolmuşsa) tarihi geçti etiketi — API Aktif/Pasif üstte ayrı
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: promo.isExpired ? Colors.red[600] : Colors.green[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            promo.formattedEndDate,
                            style: TextStyle(
                              color: promo.isExpired ? Colors.red[600] : Colors.green[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (promo.isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Tarihi Geçti!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (!promo.isExpired && promo.isActive)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 20,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfferDetailScreen extends StatefulWidget {
  final PromoApiModel promo;
  final BuildContext listContext;
  final bool canManage;

  const OfferDetailScreen({
    required this.promo,
    required this.listContext,
    this.canManage = false,
    Key? key,
  }) : super(key: key);

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  bool _deleting = false;

  PromoApiModel get promo => widget.promo;

  void _openEdit(BuildContext sheetContext) {
    if (!widget.canManage) return;
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.listContext.mounted) return;
      Navigator.of(widget.listContext).push(
        MaterialPageRoute<void>(builder: (_) => const EditOffersScreen()),
      );
    });
  }

  Future<void> _confirmDelete() async {
    if (!widget.canManage) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kampanyayı sil'),
        content: Text('"${promo.name}" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    final result = await PromoApiRepository(dio: Dio()).deletePromo(promo.id);
    if (!mounted) return;
    setState(() => _deleting = false);

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.7,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kampanya Detayı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.red, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1.2),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  promo.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ImageUtils.isValidS3Id(promo.bannerPicture)
                                  ? Image.network(
                                      ImageUtils.getS3FileUrl(promo.bannerPicture),
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return SizedBox(
                                          height: 180,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              strokeWidth: 2,
                                              color: const Color(0xFFE53935),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: double.infinity,
                                        height: 180,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.campaign_outlined, color: Colors.grey, size: 48),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red[700],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    promo.discountDisplay,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: promo.isActive ? Colors.green[600] : Colors.grey[600],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    promo.recordStatusLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 18,
                                      color: promo.isExpired ? Colors.red[700] : Colors.green[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      promo.formattedEndDate,
                                      style: TextStyle(
                                        color: promo.isExpired ? Colors.red[700] : Colors.green[700],
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                if (promo.isExpired)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.red[600],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Tarihi Geçti!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (!promo.isExpired && promo.isActive)
                                  Icon(Icons.check_circle, color: Colors.green[600], size: 26),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Bilgi kutusu
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 15, color: Colors.black),
                                children: [
                                  const                                   TextSpan(text: 'İndirim Kodu: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                  TextSpan(text: promo.promoCode, style: TextStyle(color: Color.fromRGBO(238, 46, 36, 1), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 15, color: Colors.black),
                                children: [
                                  const TextSpan(text: 'İndirim Türü: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                  TextSpan(text: promo.typeDisplayLabel, style: const TextStyle(color: Color.fromRGBO(238, 46, 36, 1), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 15, color: Colors.black),
                                children: [
                                  const TextSpan(text: 'Kampanya Kategorisi: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                  TextSpan(text: promo.categoryDisplay, style: const TextStyle(color: Color.fromRGBO(238, 46, 36, 1), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 15, color: Colors.black),
                                children: [
                                  TextSpan(text: 'Kampanyayı Görüntüleyen Gruplar: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                  TextSpan(text: 'Broker, Gayrimenkul Danışmanı, Takım Lideri, Ofis Asistanı, Franchise Satış Destek Uzmanı, Franchise Satış Ve Geliştirme Direktörü, Franchise Satış Yöneticisi, Saha Satış Asistanı, Saha Satış Uzmanı', style: TextStyle(color: Color.fromRGBO(238, 46, 36, 1), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Başlık ve kapsam
                      const SizedBox(height: 10),
                      Text(promo.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                      const SizedBox(height: 10),
                      const Text('Kapsam:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        promo.promoScope.isNotEmpty ? promo.promoScope : promo.description,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 28),
                      if (widget.canManage) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _deleting ? null : () => _openEdit(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE53935),
                              side: const BorderSide(color: Color.fromRGBO(238, 46, 36, 1), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Düzenle'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _deleting ? null : _confirmDelete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            child: _deleting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sil', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../infrastructure/coupon/coupon_api_repository.dart';
import '../../models/coupon/coupon_model.dart';
import '../error/failures.dart';

part 'coupon_state.dart';

/// [loadCoupons] içinde "parametre verilmedi = mevcut değeri koru" ayrımı için.
const Object _couponFilterUnset = Object();

class CouponCubit extends Cubit<CouponState> {
  final CouponApiRepository _repository;
  List<CouponModel> _allCoupons = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  int? _currentStatusFilter;
  String? _currentTypeFilter;
  
  // Silinen kupon ID'lerini tut (refresh sonrası tekrar gelmesin)
  final Set<String> _deletedCouponIds = <String>{};

  CouponCubit(this._repository) : super(CouponInitial());

  /// Getter'lar
  List<CouponModel> get allCoupons => _allCoupons;
  bool get hasMoreData => _hasMoreData;
  int? get currentStatusFilter => _currentStatusFilter;
  String? get currentTypeFilter => _currentTypeFilter;

  int? _apiStatusFromCurrentFilter() {
    switch (_currentStatusFilter) {
      case 1:
        return 1;
      case 0:
        return 0;
      default:
        return null;
    }
  }

  /// Kuponları yükle
  ///
  /// [statusFilter] / [typeFilter] için varsayılan [_couponFilterUnset]:
  /// refresh sırasında verilmezse ilgili filtre değişmez.
  Future<void> loadCoupons({
    bool refresh = false,
    Object? statusFilter = _couponFilterUnset,
    Object? typeFilter = _couponFilterUnset,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _allCoupons.clear();
      _hasMoreData = true;
      if (statusFilter != _couponFilterUnset) {
        _currentStatusFilter = statusFilter as int?;
      }
      if (typeFilter != _couponFilterUnset) {
        _currentTypeFilter = typeFilter as String?;
      }
    }

    if (!_hasMoreData && !refresh) return;

    try {
      if (refresh || _currentPage == 1) {
        emit(CouponLoading());
      }

      final apiStatus = _apiStatusFromCurrentFilter();

      final result = await _repository.getCoupons(
        page: _currentPage,
        limit: 20,
        status: apiStatus,
        type: _currentTypeFilter,
        search: null,
      );

      result.fold(
        (failure) {
          print('❌ CouponCubit Error: ${failure.message}');
          emit(CouponError(failure));
        },
        (couponResponse) {
          print('✅ CouponCubit: ${couponResponse.coupons.length} kupon geldi');
          print('📊 Total: ${couponResponse.totalCount}, Pages: ${couponResponse.totalPages}, Current Page: ${couponResponse.page}');
          
          // Silinen kuponları filtrele
          final filteredCoupons = couponResponse.coupons
              .where((coupon) => !_deletedCouponIds.contains(coupon.id))
              .toList();
          
          print('🗑️ Silinen kuponlar filtrelendi: ${_deletedCouponIds.length} kupon');
          print('📋 Filtre sonrası: ${filteredCoupons.length} kupon (API: ${couponResponse.coupons.length})');
          
          if (refresh || _currentPage == 1) {
            _allCoupons = filteredCoupons;
            print('🔄 İlk yükleme veya refresh: ${_allCoupons.length} kupon');
          } else {
            _allCoupons.addAll(filteredCoupons);
            print('➕ Daha fazla yüklendi: Toplam ${_allCoupons.length} kupon');
          }

          _currentPage++;
          _hasMoreData = _currentPage <= couponResponse.totalPages;
          print('📄 Current Page: $_currentPage, Has More: $_hasMoreData');

          emit(CouponLoaded(
            couponResponse: couponResponse,
            allCoupons: List.from(_allCoupons),
          ));
          print('✅ CouponLoaded state emit edildi: ${_allCoupons.length} kupon');
        },
      );
    } catch (e) {
      emit(CouponError(ServerFailure(message: 'Kuponlar yüklenirken hata oluştu: $e')));
    }
  }

  /// Daha fazla kupon yükle (pagination)
  Future<void> loadMoreCoupons() async {
    if (!_hasMoreData) return;

    final currentState = state;
    if (currentState is CouponLoaded) {
      emit(CouponLoadingMore(currentState.allCoupons));
      
      try {
        final result = await _repository.getCoupons(
          page: _currentPage,
          limit: 20,
          status: _apiStatusFromCurrentFilter(),
          type: _currentTypeFilter,
          search: null,
        );

        result.fold(
          (failure) {
            // Hata durumunda mevcut listeyi koru
            emit(CouponLoaded(
              couponResponse: currentState.couponResponse,
              allCoupons: currentState.allCoupons,
            ));
          },
          (couponResponse) {
            // Silinen kuponları filtrele
            final filteredCoupons = couponResponse.coupons
                .where((coupon) => !_deletedCouponIds.contains(coupon.id))
                .toList();
            
            _allCoupons.addAll(filteredCoupons);
            _currentPage++;
            _hasMoreData = _currentPage <= couponResponse.totalPages;

            emit(CouponLoaded(
              couponResponse: couponResponse,
              allCoupons: List.from(_allCoupons),
            ));
          },
        );
      } catch (e) {
        emit(CouponError(ServerFailure(message: 'Kuponlar yüklenirken hata oluştu: $e')));
      }
    }
  }

  /// Status'e göre filtrele (arama ve diğer filtreler korunur)
  void filterByStatus(String statusText) {
    int? status;
    if (statusText == 'Aktif') {
      status = 1;
    } else if (statusText == 'Pasif') {
      status = 0;
    } else {
      status = null;
    }
    loadCoupons(refresh: true, statusFilter: status);
  }

  /// Type'e göre filtrele
  void filterByType(String typeText) {
    String? type;
    if (typeText == 'Ücretsiz') {
      type = 'FREE';
    } else if (typeText == 'İndirim') {
      type = 'DISCOUNT';
    } else {
      type = null;
    }
    loadCoupons(refresh: true, typeFilter: type);
  }

  /// Sadece durum filtresini kaldır (arama korunur)
  void clearStatusFilterOnly() {
    loadCoupons(refresh: true, statusFilter: null);
  }

  /// Listeyi yenile
  Future<void> refreshCoupons() async {
    await loadCoupons(refresh: true);
  }

  /// Kuponu sil
  Future<void> deleteCoupon(String couponId) async {
    try {
      // Silme başladı state'i
      final currentState = state;
      if (currentState is CouponLoaded) {
        emit(CouponDeleting(currentState.allCoupons, couponId));
      }

      final result = await _repository.deleteCoupon(couponId);

      result.fold(
        (failure) {
          // Hata durumunda mevcut state'i koru
          if (currentState is CouponLoaded) {
            emit(CouponDeleteError(currentState.allCoupons, failure.message));
          }
        },
        (success) {
          // Başarılı - kuponu listeden kaldır ve state'i güncelle
          if (currentState is CouponLoaded) {
            // Silinen kupon ID'sini Set'e ekle (refresh sonrası tekrar gelmesin)
            _deletedCouponIds.add(couponId);
            
            // Listedeki kuponu kaldır
            _allCoupons.removeWhere((coupon) => coupon.id == couponId);
            
            // Güncellenmiş liste ile yeni CouponResponse oluştur
            final updatedList = List<CouponModel>.from(_allCoupons);
            final updatedResponse = CouponResponse(
              coupons: updatedList,
              totalCount: _allCoupons.length,
              totalPages: (_allCoupons.length / 20).ceil().clamp(1, double.infinity).toInt(),
              page: 1,
            );
            
            // Güncellenmiş state'i emit et
            emit(CouponLoaded(
              couponResponse: updatedResponse,
              allCoupons: updatedList,
            ));
            
            print('✅ Kupon listeden kaldırıldı: $couponId');
            print('📊 Güncel kupon sayısı: ${_allCoupons.length}');
            print('🗑️ Silinen kupon ID seti: ${_deletedCouponIds.length} kupon');
            
            // Web'deki gibi refresh yap (silinen kuponlar filtrelenecek)
            Future.delayed(const Duration(milliseconds: 300), () {
              loadCoupons(refresh: true);
            });
          }
        },
      );
    } catch (e) {
      // Hata durumunda mevcut state'i koru
      final currentState = state;
      if (currentState is CouponLoaded) {
        emit(CouponDeleteError(currentState.allCoupons, 'Kupon silinirken hata oluştu: $e'));
      }
    }
  }

  /// State'i sıfırla
  void reset() {
    _currentPage = 1;
    _allCoupons.clear();
    _hasMoreData = true;
    _currentStatusFilter = null;
    _currentTypeFilter = null;
    _deletedCouponIds.clear();
    emit(CouponInitial());
  }

  /// Mevcut filtreleri temizle
  void clearFilters() {
    loadCoupons(
      refresh: true,
      statusFilter: null,
      typeFilter: null,
    );
  }
}


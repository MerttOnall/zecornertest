import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';
import '../../infrastructure/realestate/myrealestate_repo.dart';
import '../../models/realestate/myrealestate_model.dart';

part 'portfolio_state.dart';

class PortfolioCubit extends Cubit<PortfolioState> {
  final MyRealEstateRepository _repository = MyRealEstateRepository();
  static const int pageSize = 10;
  bool _loadingMore = false;

  PortfolioCubit() : super(PortfolioInitial());

  Future<void> loadPortfolios({int page = 1, int limit = pageSize}) async {
    await loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    _loadingMore = false;
    emit(PortfolioLoading());

    final result = await _repository.getMyRealEstates(page: 1, limit: pageSize);

    result.fold(
      (failure) => emit(PortfolioError(failure)),
      (response) => emit(
        PortfolioLoaded(
          response,
          lastPageCount: response.realEstates.length,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;
    if (_loadingMore || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    _loadingMore = true;
    emit(PortfolioLoaded(
      currentState.response,
      isLoadingMore: true,
      lastPageCount: currentState.lastPageCount,
    ));

    final nextPage = currentState.response.page <= 0
        ? 2
        : currentState.response.page + 1;
    final result = await _repository.getMyRealEstates(
      page: nextPage,
      limit: pageSize,
    );

    result.fold(
      (failure) {
        _loadingMore = false;
        emit(PortfolioLoaded(
          currentState.response,
          lastPageCount: currentState.lastPageCount,
        ));
      },
      (response) {
        _loadingMore = false;
        final existingIds =
            currentState.response.realEstates.map((e) => e.id).toSet();
        final appended = response.realEstates
            .where((item) => !existingIds.contains(item.id))
            .toList();
        final merged = MyRealEstateResponseModel(
          realEstates: [...currentState.response.realEstates, ...appended],
          totalCount: appended.isEmpty
              ? currentState.response.realEstates.length
              : response.totalCount,
          totalPages: appended.isEmpty
              ? nextPage
              : (response.totalPages <= 0 ? nextPage : response.totalPages),
          page: appended.isEmpty
              ? nextPage
              : (response.page <= 0 ? nextPage : response.page),
        );
        emit(PortfolioLoaded(merged, lastPageCount: appended.length));
      },
    );
  }

  Future<void> loadAllPortfolios() async {
    await loadFirstPage();
  }

  // Portfolio ara
  Future<void> searchPortfolios({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    emit(PortfolioLoading());
    
    final result = await _repository.searchMyRealEstates(
      query: query,
      page: page,
      limit: limit,
    );
    
    result.fold(
      (failure) => emit(PortfolioError(failure)),
      (response) => emit(PortfolioLoaded(response)),
    );
  }

  // Portfolio'ları yenile
  Future<void> refreshPortfolios() async {
    await loadFirstPage();
  }

  // Portfolio'yu güncelle (optimistic update)
  void updatePortfolio(RealEstateModel updatedPortfolio) {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      final updatedRealEstates = currentState.response.realEstates.map((portfolio) {
        return portfolio.id == updatedPortfolio.id ? updatedPortfolio : portfolio;
      }).toList();

      final updatedResponse = MyRealEstateResponseModel(
        realEstates: updatedRealEstates,
        totalCount: currentState.response.totalCount,
        totalPages: currentState.response.totalPages,
        page: currentState.response.page,
      );

      emit(PortfolioLoaded(updatedResponse));
    }
  }

  // Portfolio'yu kaldır (optimistic update)
  void removePortfolio(String portfolioId) {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      final updatedRealEstates = currentState.response.realEstates
          .where((portfolio) => portfolio.id != portfolioId)
          .toList();

      final updatedResponse = MyRealEstateResponseModel(
        realEstates: updatedRealEstates,
        totalCount: currentState.response.totalCount - 1,
        totalPages: currentState.response.totalPages,
        page: currentState.response.page,
      );

      emit(PortfolioLoaded(updatedResponse));
    }
  }

  // Portfolio'ları filtrele
  void filterPortfolios({
    String? searchQuery,
    String? portfolioType,
    String? status,
  }) {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      List<RealEstateModel> filteredPortfolios = currentState.response.realEstates;

      // Arama filtresi
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredPortfolios = filteredPortfolios.where((portfolio) {
          final searchLower = searchQuery.toLowerCase();
          return portfolio.title.toLowerCase().contains(searchLower) ||
                 (portfolio.address.city?.toLowerCase().contains(searchLower) ?? false) ||
                 (portfolio.address.district?.toLowerCase().contains(searchLower) ?? false) ||
                 portfolio.address.address.toLowerCase().contains(searchLower) ||
                 portfolio.type.toLowerCase().contains(searchLower);
        }).toList();
      }

      // Portfolio türü filtresi
      if (portfolioType != null && portfolioType != 'Tümü') {
        filteredPortfolios = filteredPortfolios.where((portfolio) {
          return portfolio.type == portfolioType;
        }).toList();
      }

      // Durum filtresi
      if (status != null && status != 'Tümü') {
        filteredPortfolios = filteredPortfolios.where((portfolio) {
          return portfolio.status == (status == 'Aktif' ? 1 : 0);
        }).toList();
      }

      // Filtrelenmiş sonuçları yeni state olarak emit et
      final filteredResponse = MyRealEstateResponseModel(
        realEstates: filteredPortfolios,
        totalCount: filteredPortfolios.length,
        totalPages: 1,
        page: 1,
      );

      emit(PortfolioLoaded(filteredResponse));
    }
  }

  // Filtreleri temizle ve orijinal veriyi geri yükle
  void clearFilters() {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      // Orijinal veriyi yeniden yükle
      loadPortfolios();
    }
  }

  // State'i temizle
  void clearState() {
    emit(PortfolioInitial());
  }

  // Loading state'i kontrol et
  bool get isLoading => state is PortfolioLoading;

  // Error state'i kontrol et
  bool get hasError => state is PortfolioError;

  // Loaded state'i kontrol et
  bool get isLoaded => state is PortfolioLoaded;

  // Error mesajını al
  String? get errorMessage {
    final currentState = state;
    if (currentState is PortfolioError) {
      return currentState.failure.message;
    }
    return null;
  }

  // Portfolio listesini al
  List<RealEstateModel> get portfolios {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      return currentState.response.realEstates;
    }
    return [];
  }

  // Toplam sayıyı al
  int get totalCount {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      return currentState.response.totalCount;
    }
    return 0;
  }
}

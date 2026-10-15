import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../infrastructure/bform/bform_api_repository.dart';
import '../../infrastructure/transaction/transaction_api_repository.dart';
import '../../models/transaction/transaction_model.dart';
import '../../core/network/dio_client.dart';
import '../error/failures.dart';

part 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionApiRepository _repository;
  final BformApiRepository _contactRepository =
      BformApiRepository(dio: DioClient().dio);

  static const int _pageSize = 10;

  List<TransactionModel> _allTransactions = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  int _generation = 0;
  String? _currentStateFilter;
  String? _currentSourceFilter;
  String? _currentSearch;
  TransactionResponse? _lastResponse;
  bool _approveSnackPending = false;
  bool _rejectSnackPending = false;

  TransactionCubit(this._repository) : super(TransactionInitial());

  List<TransactionModel> get allTransactions =>
      _allTransactions.where(_rowMatches).toList();
  bool get hasMoreData => _hasMoreData;

  bool _rowMatches(TransactionModel transaction) {
    return transaction.matchesStatus(_currentStateFilter ?? 'Tümü') &&
        transaction.matchesPayment(_currentSourceFilter ?? 'Tümü') &&
        transaction.matchesQuery(_currentSearch ?? '');
  }

  bool get _needsExtraPages {
    final status = _currentStateFilter ?? 'Tümü';
    final source = _currentSourceFilter ?? 'Tümü';
    final search = _currentSearch?.trim() ?? '';
    return status != 'Tümü' || source != 'Tümü' || search.isNotEmpty;
  }
  String? get currentStateFilter => _currentStateFilter;
  String? get currentSourceFilter => _currentSourceFilter;

  String? _mapStateToApi(String? filter) {
    switch (filter) {
      case 'Bekleyen':
        return 'PENDING';
      case 'Onaylandı':
      case 'Onaylanmış':
        return 'APPROVED';
      case 'İptal':
        return 'REJECTED';
      case 'Tümü':
      case null:
      case '':
        return null;
      default:
        return null;
    }
  }

  String? _mapSourceToApi(String? filter) {
    switch (filter) {
      case 'Havale/EFT':
        return 'transfer';
      case 'Kredi Kartı':
        return 'creditcard';
      case 'Tümü':
      case null:
      case '':
        return null;
      default:
        return null;
    }
  }

  Future<void> _enrichContactTitles() async {
    final contactIds = _allTransactions
        .where((t) => t.needsContactLookup)
        .map((t) => t.contact)
        .where((id) => id > 0)
        .toSet();

    if (contactIds.isEmpty) return;

    final titleMap = <int, String>{};
    for (final contactId in contactIds) {
      final result = await _contactRepository.getContactInfo(contactId);
      result.fold((_) => null, (contact) {
        if (contact != null && contact.title.trim().isNotEmpty) {
          titleMap[contactId] = contact.title.trim();
        }
      });
    }

    if (titleMap.isEmpty) return;

    _allTransactions = _allTransactions
        .map(
          (t) => titleMap.containsKey(t.contact)
              ? t.copyWith(contactTitle: titleMap[t.contact])
              : t,
        )
        .toList();
  }

  void _emitLoadedList() {
    final visible = List<TransactionModel>.from(allTransactions);
    emit(
      TransactionLoaded(
        transactionResponse: _lastResponse ??
            TransactionResponse(
              transactions: visible,
              totalCount: visible.length,
              totalPages: 1,
              page: 1,
            ),
        allTransactions: visible,
      ),
    );
  }

  /// Bir sayfa çeker. Yeni satır yoksa veya istek düşerse false.
  Future<bool> _appendPage(int generation) async {
    if (generation != _generation || !_hasMoreData) return false;

    final result = await _repository.getTransactions(
      page: _currentPage,
      limit: _pageSize,
      state: _mapStateToApi(_currentStateFilter),
      source: _mapSourceToApi(_currentSourceFilter),
      search: null,
    );

    if (generation != _generation) return false;

    return result.fold((failure) {
      if (_allTransactions.isEmpty) {
        emit(TransactionError(failure));
      }
      _hasMoreData = false;
      return false;
    }, (transactionResponse) {
      _lastResponse = transactionResponse;
      final existing = _allTransactions.map((e) => e.id).toSet();
      final fresh = transactionResponse.transactions
          .where((item) => !existing.contains(item.id))
          .toList();
      _allTransactions.addAll(fresh);
      _currentPage++;
      _hasMoreData =
          fresh.isNotEmpty && _currentPage <= transactionResponse.totalPages;
      return fresh.isNotEmpty;
    });
  }

  Future<void> loadTransactions({
    bool refresh = false,
    String? stateFilter,
    String? sourceFilter,
    String? search,
  }) async {
    if (refresh) {
      _generation++;
      _currentPage = 1;
      _hasMoreData = true;
      _allTransactions = [];
      if (stateFilter != null) _currentStateFilter = stateFilter;
      if (sourceFilter != null) _currentSourceFilter = sourceFilter;
      if (search != null) _currentSearch = search;
      emit(TransactionLoading());
    }

    if (!_hasMoreData && !refresh) return;

    final generation = _generation;

    try {
      if (!refresh && _allTransactions.isEmpty) {
        emit(TransactionLoading());
      }

      final target = _needsExtraPages ? 8 : 1;
      var pages = 0;
      while (pages < 30 && generation == _generation && _hasMoreData) {
        final added = await _appendPage(generation);
        if (!added || generation != _generation) break;
        pages++;
        if (allTransactions.length >= target) break;
      }

      if (generation != _generation) return;
      if (state is TransactionError && _allTransactions.isEmpty) return;

      await _enrichContactTitles();
      if (generation != _generation) return;
      _emitLoadedList();

      if (_approveSnackPending) {
        _approveSnackPending = false;
        emit(TransactionApproved());
        _emitLoadedList();
      } else if (_rejectSnackPending) {
        _rejectSnackPending = false;
        emit(TransactionRejected());
        _emitLoadedList();
      }
    } catch (e) {
      emit(
        TransactionError(
          ServerFailure(message: 'Havale işlemleri yüklenirken hata oluştu: $e'),
        ),
      );
    }
  }

  Future<void> loadMoreTransactions() async {
    if (!_hasMoreData) return;
    if (state is! TransactionLoaded) return;

    final generation = _generation;
    final before = allTransactions.length;
    emit(TransactionLoadingMore(List<TransactionModel>.from(allTransactions)));

    try {
      var pages = 0;
      while (pages < 8 &&
          generation == _generation &&
          _hasMoreData &&
          allTransactions.length == before) {
        final added = await _appendPage(generation);
        if (!added) break;
        pages++;
      }
      if (generation != _generation) return;
      await _enrichContactTitles();
      if (generation != _generation) return;
      _emitLoadedList();
    } catch (_) {
      if (generation != _generation) return;
      _emitLoadedList();
    }
  }

  Future<void> filterByState(String stateFilter) async {
    await loadTransactions(
      refresh: true,
      stateFilter: stateFilter,
      sourceFilter: _currentSourceFilter ?? 'Tümü',
      search: _currentSearch ?? '',
    );
  }

  Future<void> filterBySource(String sourceFilter) async {
    await loadTransactions(
      refresh: true,
      stateFilter: _currentStateFilter ?? 'Tümü',
      sourceFilter: sourceFilter,
      search: _currentSearch ?? '',
    );
  }

  Future<void> searchTransactions(String query) async {
    await loadTransactions(
      refresh: true,
      stateFilter: _currentStateFilter ?? 'Tümü',
      sourceFilter: _currentSourceFilter ?? 'Tümü',
      search: query,
    );
  }

  Future<void> refreshTransactions() async {
    await loadTransactions(
      refresh: true,
      stateFilter: _currentStateFilter ?? 'Tümü',
      sourceFilter: _currentSourceFilter ?? 'Tümü',
      search: _currentSearch ?? '',
    );
  }

  Future<void> approveTransaction(int transactionId) async {
    try {
      final result = await _repository.approveTransaction(transactionId);
      await result.fold(
        (failure) async => emit(TransactionApproveError(failure)),
        (_) async {
          _approveSnackPending = true;
          await refreshTransactions();
        },
      );
    } catch (e) {
      emit(
        TransactionApproveError(
          ServerFailure(message: 'Havale onaylanırken hata oluştu: $e'),
        ),
      );
    }
  }

  Future<void> rejectTransaction(int transactionId) async {
    try {
      final result = await _repository.rejectTransaction(transactionId);
      await result.fold(
        (failure) async => emit(TransactionRejectError(failure)),
        (_) async {
          _rejectSnackPending = true;
          await refreshTransactions();
        },
      );
    } catch (e) {
      emit(
        TransactionRejectError(
          ServerFailure(message: 'Havale reddedilirken hata oluştu: $e'),
        ),
      );
    }
  }

  void reset() {
    _currentPage = 1;
    _allTransactions.clear();
    _hasMoreData = true;
    _lastResponse = null;
    _currentStateFilter = null;
    _currentSourceFilter = null;
    _currentSearch = null;
    _approveSnackPending = false;
    _rejectSnackPending = false;
    emit(TransactionInitial());
  }

  void clearFilters() {
    _currentStateFilter = null;
    _currentSourceFilter = null;
    _currentSearch = null;
  }
}

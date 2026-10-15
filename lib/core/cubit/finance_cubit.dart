import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zecorner/core/auth/advisor_office_scope.dart';
import '../../infrastructure/finance/finance_api_repository.dart';
import '../../models/finance/finance_record_model.dart';
import '../../models/finance/finance_type_model.dart';
import '../error/failures.dart';

part 'finance_state.dart';

class FinanceCubit extends Cubit<FinanceState> {
  final FinanceApiRepository _repository;
  List<FinanceRecord> _allRecords = [];
  List<FinanceType> _financeTypes = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  String? _currentFilter;

  FinanceCubit(this._repository) : super(FinanceInitial());

  List<FinanceType> get financeTypes => _financeTypes;

  Future<void> loadFinanceTypes() async {
    try {
      final result = await _repository.getFinanceTypes();
      result.fold(
        (_) => _financeTypes = [],
        (types) => _financeTypes = types,
      );
    } catch (_) {
      _financeTypes = [];
    }
  }

  /// Web Next → BAMMA `GET /finance/records` (yalnız finans kayıtları; fatura birleştirmesi yok).
  Future<void> loadFinanceRecords({
    bool refresh = false,
    String? filterType,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _allRecords.clear();
      _hasMoreData = true;
      _currentFilter = filterType;
    }

    if (!_hasMoreData && !refresh) return;

    try {
      if (refresh || _currentPage == 1) {
        emit(FinanceLoading());
      }

      final scope = await AdvisorOfficeScope.load();
      final page = _currentPage;
      final result = await _repository.getFinanceRecords(
        page: scope.restricted ? 1 : page,
        pageSize: scope.restricted ? 500 : 20,
        type: filterType ?? _currentFilter,
      );

      await result.fold(
        (failure) async {
          if (_allRecords.isEmpty) {
            emit(FinanceError(failure));
          }
        },
        (response) async {
          final incoming = response.records.where((record) {
            return scope.allows(
              officeId: record.office > 0 ? record.office : null,
              personId: record.relatedContact ?? record.contact,
              officeTitle: record.officeTitle,
            );
          }).toList();

          if (scope.restricted || refresh || page == 1) {
            _allRecords = List<FinanceRecord>.from(incoming);
          } else {
            final existing = _allRecords.map((e) => e.id).toSet();
            _allRecords.addAll(
              incoming.where((r) => !existing.contains(r.id)),
            );
          }

          if (scope.restricted) {
            _currentPage = 2;
            _hasMoreData = false;
          } else {
            _currentPage = page + 1;
            _hasMoreData = page < response.totalPages;
          }

          final visible = _applyClientFilter(_allRecords);
          emit(FinanceLoaded(
            financeResponse: FinanceResponse(
              records: visible,
              totalCount: response.totalCount,
              totalPages: response.totalPages,
              page: response.page,
              sum: response.sum,
            ),
            allRecords: visible,
          ));
        },
      );
    } catch (e) {
      emit(FinanceError(
        ServerFailure(message: 'Finansal kayıtlar yüklenirken hata oluştu: $e'),
      ));
    }
  }

  List<FinanceRecord> _applyClientFilter(List<FinanceRecord> source) {
    final filter = _currentFilter;
    if (filter == 'Gelir') {
      return source.where((r) => !r.isExpense || r.amountAsDouble > 0).toList();
    }
    if (filter == 'Gider') {
      return source.where((r) => r.isExpense || r.amountAsDouble < 0).toList();
    }
    return source;
  }

  Future<void> loadMoreRecords() async {
    if (!_hasMoreData) return;
    if (state is FinanceLoaded) {
      await loadFinanceRecords(filterType: _currentFilter);
    }
  }

  Future<void> filterRecords(String filterType) async {
    _currentFilter = filterType;
    await loadFinanceRecords(refresh: true, filterType: filterType);
  }

  Future<Failure?> addExpense({
    required String description,
    required double amount,
    required String type,
  }) async {
    try {
      final result = await _repository.addExpense(
        description: description,
        amount: amount,
        type: type,
      );
      return result.fold((failure) => failure, (_) => null);
    } catch (e) {
      return ServerFailure(message: 'Gider eklenirken hata oluştu: $e');
    }
  }

  Future<void> refreshRecords() async {
    await loadFinanceRecords(refresh: true, filterType: _currentFilter);
  }

  void reset() {
    _currentPage = 1;
    _allRecords.clear();
    _hasMoreData = true;
    _currentFilter = null;
    emit(FinanceInitial());
  }
}

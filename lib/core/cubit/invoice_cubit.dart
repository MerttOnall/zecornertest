import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zecorner/core/auth/advisor_office_scope.dart';
import '../../infrastructure/invoice/invoice_api_repository.dart';
import '../../models/invoice/invoice_model.dart';
import '../error/failures.dart';

part 'invoice_state.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  final InvoiceApiRepository _repository;
  final bool fetchAllInvoices;
  List<InvoiceModel> _allInvoices = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  String? _currentStateFilter;
  String? _currentTypeFilter;
  String? _currentSearch;
  DateTime? _startDate;
  DateTime? _endDate;

  InvoiceCubit(this._repository, {this.fetchAllInvoices = false}) : super(InvoiceInitial());

  List<InvoiceModel> get allInvoices => _allInvoices;
  bool get hasMoreData => _hasMoreData;
  String? get currentStateFilter => _currentStateFilter;
  String? get currentTypeFilter => _currentTypeFilter;
  String? get currentSearch => _currentSearch;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  String? get _apiState {
    switch (_currentStateFilter) {
      case 'Ödendi':
        return 'PAID';
      case 'Bekliyor':
        return 'PENDING';
      case 'İptal':
        return 'CANCELLED';
      case 'Ödenmedi':
        return 'NOT_PAID';
      case 'Havale':
        return 'AWAITING_PAYMENT';
      default:
        return null;
    }
  }

  /// Faturaları yükle — mevcut filtreleri korur
  Future<void> loadInvoices({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _allInvoices.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    try {
      if (refresh || _currentPage == 1) {
        emit(InvoiceLoading());
      }

      final scope = await AdvisorOfficeScope.load();
      final result = await _repository.getInvoices(
        page: scope.restricted ? 1 : _currentPage,
        limit: scope.restricted ? 500 : 20,
        state: _apiState,
        type: _currentTypeFilter,
        search: _currentSearch,
        startDate: _startDate,
        endDate: _endDate,
        all: scope.restricted ? false : fetchAllInvoices,
      );

      result.fold(
        (failure) => emit(InvoiceError(failure)),
        (invoiceResponse) {
          final scoped = invoiceResponse.invoices.where((invoice) {
            return scope.allows(
              personId: invoice.contact,
              officeTitle: invoice.ofisContactTitle,
            );
          }).toList();
          final filtered = _applyLocalFilters(scoped);

          if (scope.restricted || refresh || _currentPage == 1) {
            _allInvoices = filtered;
          } else {
            final existingIds = _allInvoices.map((e) => e.id).toSet();
            _allInvoices.addAll(
              filtered.where((invoice) => !existingIds.contains(invoice.id)),
            );
          }

          if (scope.restricted) {
            _hasMoreData = false;
          } else {
            _currentPage++;
            _hasMoreData = _currentPage <= invoiceResponse.totalPages;
          }

          emit(InvoiceLoaded(
            invoiceResponse: InvoiceResponse(
              invoices: invoiceResponse.invoices,
              totalCount: invoiceResponse.totalCount,
              totalPages: invoiceResponse.totalPages,
              page: invoiceResponse.page,
              amounts: _resolveAmounts(invoiceResponse.amounts, _allInvoices),
            ),
            allInvoices: List.from(_allInvoices),
          ));
        },
      );
    } catch (e) {
      emit(InvoiceError(ServerFailure(message: 'Faturalar yüklenirken hata oluştu: $e')));
    }
  }

  InvoiceAmounts _resolveAmounts(InvoiceAmounts apiAmounts, List<InvoiceModel> invoices) {
    if (apiAmounts.totalAmount > 0 || apiAmounts.paidAmount > 0) {
      return apiAmounts;
    }

    double total = 0;
    double paid = 0;
    for (final invoice in invoices) {
      total += invoice.amount;
      paid += invoice.paidAmount;
    }
    return InvoiceAmounts(totalAmount: total, paidAmount: paid);
  }

  List<InvoiceModel> _applyLocalFilters(List<InvoiceModel> invoices) {
    var filtered = invoices;

    if (_startDate != null || _endDate != null) {
      final start = _startDate == null
          ? null
          : DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final end = _endDate == null
          ? null
          : DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

      filtered = filtered.where((invoice) {
        final date = DateTime(invoice.date.year, invoice.date.month, invoice.date.day);
        if (start != null && date.isBefore(start)) return false;
        if (end != null && date.isAfter(end)) return false;
        return true;
      }).toList();
    }

    final query = _currentSearch?.trim().toLowerCase();
    if (query != null && query.isNotEmpty) {
      filtered = filtered.where((invoice) {
        final haystack = [
          invoice.invoiceNumber,
          invoice.contactTitle,
          invoice.typeDescription,
          invoice.type,
          invoice.stateText,
          invoice.ofisContactTitle ?? '',
          invoice.amount.toString(),
          invoice.paidAmount.toString(),
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> loadMoreInvoices() async {
    if (!_hasMoreData) return;

    final currentState = state;
    if (currentState is! InvoiceLoaded) return;

    emit(InvoiceLoadingMore(
      currentState.allInvoices,
      amounts: currentState.invoiceResponse.amounts,
    ));

    try {
      final result = await _repository.getInvoices(
        page: _currentPage,
        limit: 20,
        state: _apiState,
        type: _currentTypeFilter,
        search: _currentSearch,
        startDate: _startDate,
        endDate: _endDate,
        all: fetchAllInvoices,
      );

      result.fold(
        (failure) {
          emit(InvoiceLoaded(
            invoiceResponse: currentState.invoiceResponse,
            allInvoices: currentState.allInvoices,
          ));
        },
        (invoiceResponse) {
          final filtered = _applyLocalFilters(invoiceResponse.invoices);
          final existingIds = _allInvoices.map((e) => e.id).toSet();
          _allInvoices.addAll(
            filtered.where((invoice) => !existingIds.contains(invoice.id)),
          );
          _currentPage++;
          _hasMoreData = _currentPage <= invoiceResponse.totalPages;

          emit(InvoiceLoaded(
            invoiceResponse: InvoiceResponse(
              invoices: invoiceResponse.invoices,
              totalCount: invoiceResponse.totalCount,
              totalPages: invoiceResponse.totalPages,
              page: invoiceResponse.page,
              amounts: _resolveAmounts(invoiceResponse.amounts, _allInvoices),
            ),
            allInvoices: List.from(_allInvoices),
          ));
        },
      );
    } catch (_) {
      emit(InvoiceLoaded(
        invoiceResponse: currentState.invoiceResponse,
        allInvoices: currentState.allInvoices,
      ));
    }
  }

  Future<void> filterByState(String stateFilter) async {
    _currentStateFilter = stateFilter == 'Tümü' ? null : stateFilter;
    await loadInvoices(refresh: true);
  }

  Future<void> filterByType(String? typeFilter) async {
    _currentTypeFilter = typeFilter;
    await loadInvoices(refresh: true);
  }

  Future<void> searchInvoices(String query) async {
    final trimmed = query.trim();
    _currentSearch = trimmed.isEmpty ? null : trimmed;
    await loadInvoices(refresh: true);
  }

  Future<void> filterByDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _startDate = startDate;
    _endDate = endDate;
    await loadInvoices(refresh: true);
  }

  /// Tüm filtreleri tek seferde uygula (sheet / clear için)
  Future<void> applyFilters({
    String? stateFilter,
    String? typeFilter,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _currentStateFilter =
        (stateFilter == null || stateFilter == 'Tümü') ? null : stateFilter;
    _currentTypeFilter = typeFilter;
    final trimmed = search?.trim();
    _currentSearch = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    _startDate = startDate;
    _endDate = endDate;
    await loadInvoices(refresh: true);
  }

  Future<void> refreshInvoices() async {
    await loadInvoices(refresh: true);
  }

  Future<void> loadInvoiceDetail(String invoiceId) async {
    emit(InvoiceDetailLoading());

    try {
      final result = await _repository.getInvoiceDetail(invoiceId);

      result.fold(
        (failure) => emit(InvoiceDetailError(failure)),
        (invoice) => emit(InvoiceDetailLoaded(invoice)),
      );
    } catch (e) {
      emit(InvoiceDetailError(
        ServerFailure(message: 'Fatura detayı yüklenirken hata oluştu: $e'),
      ));
    }
  }

  Future<void> downloadInvoicePdf(String invoiceId) async {
    emit(InvoicePdfDownloading());

    try {
      final result = await _repository.getInvoicePdfUrl(invoiceId);

      result.fold(
        (failure) => emit(InvoicePdfError(failure)),
        (pdfUrl) => emit(InvoicePdfDownloaded(pdfUrl)),
      );
    } catch (e) {
      emit(InvoicePdfError(
        ServerFailure(message: 'PDF indirilirken hata oluştu: $e'),
      ));
    }
  }

  Future<void> approveInvoice(String invoiceId) async {
    try {
      final result = await _repository.approveInvoice(invoiceId);

      result.fold(
        (failure) {
          final currentState = state;
          if (currentState is InvoiceLoaded) {
            emit(currentState);
          }
        },
        (success) {
          refreshInvoices();
        },
      );
    } catch (_) {
      final currentState = state;
      if (currentState is InvoiceLoaded) {
        emit(currentState);
      }
    }
  }

  void reset() {
    _currentPage = 1;
    _allInvoices.clear();
    _hasMoreData = true;
    _currentStateFilter = null;
    _currentTypeFilter = null;
    _currentSearch = null;
    _startDate = null;
    _endDate = null;
    emit(InvoiceInitial());
  }

  Future<void> clearFilters() async {
    await applyFilters();
  }
}

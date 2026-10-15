part of 'invoice_cubit.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();
  
  @override
  List<Object?> get props => [];
}

/// Başlangıç durumu
class InvoiceInitial extends InvoiceState {}

/// Yükleniyor durumu
class InvoiceLoading extends InvoiceState {}

/// Faturalar yüklendi
class InvoiceLoaded extends InvoiceState {
  final InvoiceResponse invoiceResponse;
  final List<InvoiceModel> allInvoices;

  const InvoiceLoaded({
    required this.invoiceResponse,
    required this.allInvoices,
  });

  @override
  List<Object?> get props => [invoiceResponse, allInvoices];
}

/// Hata durumu
class InvoiceError extends InvoiceState {
  final Failure failure;

  const InvoiceError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Daha fazla veri yükleniyor (pagination)
class InvoiceLoadingMore extends InvoiceState {
  final List<InvoiceModel> currentInvoices;
  final InvoiceAmounts amounts;

  const InvoiceLoadingMore(
    this.currentInvoices, {
    this.amounts = const InvoiceAmounts(),
  });

  @override
  List<Object?> get props => [currentInvoices, amounts];
}

/// Fatura detayı yükleniyor
class InvoiceDetailLoading extends InvoiceState {}

/// Fatura detayı yüklendi
class InvoiceDetailLoaded extends InvoiceState {
  final InvoiceModel invoice;

  const InvoiceDetailLoaded(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

/// Fatura detayı hatası
class InvoiceDetailError extends InvoiceState {
  final Failure failure;

  const InvoiceDetailError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// PDF indirme durumu
class InvoicePdfDownloading extends InvoiceState {}

/// PDF indirildi
class InvoicePdfDownloaded extends InvoiceState {
  final String pdfUrl;

  const InvoicePdfDownloaded(this.pdfUrl);

  @override
  List<Object?> get props => [pdfUrl];
}

/// PDF indirme hatası
class InvoicePdfError extends InvoiceState {
  final Failure failure;

  const InvoicePdfError(this.failure);

  @override
  List<Object?> get props => [failure];
}


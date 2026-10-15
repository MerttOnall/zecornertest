part of 'transaction_cubit.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TransactionInitial extends TransactionState {}

/// Loading transactions
class TransactionLoading extends TransactionState {}

/// Loading more transactions (pagination)
class TransactionLoadingMore extends TransactionState {
  final List<TransactionModel> currentTransactions;

  const TransactionLoadingMore(this.currentTransactions);

  @override
  List<Object?> get props => [currentTransactions];
}

/// Transactions loaded successfully
class TransactionLoaded extends TransactionState {
  final TransactionResponse transactionResponse;
  final List<TransactionModel> allTransactions;

  const TransactionLoaded({
    required this.transactionResponse,
    required this.allTransactions,
  });

  @override
  List<Object?> get props => [transactionResponse, allTransactions];
}

/// Error loading transactions
class TransactionError extends TransactionState {
  final Failure failure;

  const TransactionError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Approving transaction
class TransactionApproving extends TransactionState {}

/// Transaction approved successfully
class TransactionApproved extends TransactionState {}

/// Error approving transaction
class TransactionApproveError extends TransactionState {
  final Failure failure;

  const TransactionApproveError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Rejecting transaction
class TransactionRejecting extends TransactionState {}

/// Transaction rejected successfully
class TransactionRejected extends TransactionState {}

/// Error rejecting transaction
class TransactionRejectError extends TransactionState {
  final Failure failure;

  const TransactionRejectError(this.failure);

  @override
  List<Object?> get props => [failure];
}


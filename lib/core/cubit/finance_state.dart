part of 'finance_cubit.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final FinanceResponse financeResponse;
  final List<FinanceRecord> allRecords;

  const FinanceLoaded({
    required this.financeResponse,
    required this.allRecords,
  });

  @override
  List<Object?> get props => [financeResponse, allRecords];
}

class FinanceError extends FinanceState {
  final Failure failure;

  const FinanceError(this.failure);

  @override
  List<Object?> get props => [failure];
}

class FinanceExpenseAdding extends FinanceState {}

class FinanceExpenseAdded extends FinanceState {
  final FinanceRecord newRecord;

  const FinanceExpenseAdded(this.newRecord);

  @override
  List<Object?> get props => [newRecord];
}

class FinanceExpenseError extends FinanceState {
  final Failure failure;

  const FinanceExpenseError(this.failure);

  @override
  List<Object?> get props => [failure];
}


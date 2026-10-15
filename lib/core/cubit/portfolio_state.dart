part of 'portfolio_cubit.dart';

abstract class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object?> get props => [];
}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final MyRealEstateResponseModel response;
  final bool isLoadingMore;
  final int lastPageCount;

  const PortfolioLoaded(
    this.response, {
    this.isLoadingMore = false,
    this.lastPageCount = 0,
  });

  bool get hasMore {
    if (response.totalCount > 0) {
      return response.realEstates.length < response.totalCount;
    }
    if (response.totalPages > 0) {
      return response.page < response.totalPages;
    }
    return lastPageCount >= PortfolioCubit.pageSize;
  }

  @override
  List<Object> get props => [response, isLoadingMore, lastPageCount];
}

class PortfolioError extends PortfolioState {
  final Failure failure;

  const PortfolioError(this.failure);

  @override
  List<Object> get props => [failure];
}

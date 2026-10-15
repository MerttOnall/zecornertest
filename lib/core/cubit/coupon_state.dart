part of 'coupon_cubit.dart';

abstract class CouponState extends Equatable {
  const CouponState();
  
  @override
  List<Object?> get props => [];
}

/// Başlangıç durumu
class CouponInitial extends CouponState {}

/// Yükleniyor durumu
class CouponLoading extends CouponState {}

/// Kuponlar yüklendi
class CouponLoaded extends CouponState {
  final CouponResponse couponResponse;
  final List<CouponModel> allCoupons;

  const CouponLoaded({
    required this.couponResponse,
    required this.allCoupons,
  });

  @override
  List<Object?> get props => [couponResponse, allCoupons];
}

/// Hata durumu
class CouponError extends CouponState {
  final Failure failure;

  const CouponError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Daha fazla veri yükleniyor (pagination)
class CouponLoadingMore extends CouponState {
  final List<CouponModel> currentCoupons;

  const CouponLoadingMore(this.currentCoupons);

  @override
  List<Object?> get props => [currentCoupons];
}

/// Kupon siliniyor
class CouponDeleting extends CouponState {
  final List<CouponModel> currentCoupons;
  final String deletingCouponId;

  const CouponDeleting(this.currentCoupons, this.deletingCouponId);

  @override
  List<Object?> get props => [currentCoupons, deletingCouponId];
}

/// Kupon silindi
class CouponDeleted extends CouponState {
  final List<CouponModel> allCoupons;

  const CouponDeleted(this.allCoupons);

  @override
  List<Object?> get props => [allCoupons];
}

/// Kupon silme hatası
class CouponDeleteError extends CouponState {
  final List<CouponModel> currentCoupons;
  final String errorMessage;

  const CouponDeleteError(this.currentCoupons, this.errorMessage);

  @override
  List<Object?> get props => [currentCoupons, errorMessage];
}


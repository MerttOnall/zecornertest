part of 'coupon_template_cubit.dart';

abstract class CouponTemplateState extends Equatable {
  const CouponTemplateState();

  @override
  List<Object?> get props => [];
}

class CouponTemplateInitial extends CouponTemplateState {}

class CouponTemplateLoading extends CouponTemplateState {}

class CouponTemplateLoaded extends CouponTemplateState {
  final List<CouponTemplateModel> templates;

  const CouponTemplateLoaded(this.templates);

  @override
  List<Object?> get props => [templates];
}

class CouponTemplateError extends CouponTemplateState {
  final Failure failure;

  const CouponTemplateError(this.failure);

  @override
  List<Object?> get props => [failure];
}

class CouponTemplateCreating extends CouponTemplateState {
  final List<CouponTemplateModel> currentTemplates;

  const CouponTemplateCreating(this.currentTemplates);

  @override
  List<Object?> get props => [currentTemplates];
}

class CouponTemplateUpdating extends CouponTemplateState {
  final List<CouponTemplateModel> currentTemplates;
  final int updatingId;

  const CouponTemplateUpdating(this.currentTemplates, this.updatingId);

  @override
  List<Object?> get props => [currentTemplates, updatingId];
}

class CouponTemplateDeleting extends CouponTemplateState {
  final List<CouponTemplateModel> currentTemplates;
  final int deletingId;

  const CouponTemplateDeleting(this.currentTemplates, this.deletingId);

  @override
  List<Object?> get props => [currentTemplates, deletingId];
}

class CouponTemplateDeleteError extends CouponTemplateState {
  final List<CouponTemplateModel> currentTemplates;
  final String errorMessage;

  const CouponTemplateDeleteError(this.currentTemplates, this.errorMessage);

  @override
  List<Object?> get props => [currentTemplates, errorMessage];
}


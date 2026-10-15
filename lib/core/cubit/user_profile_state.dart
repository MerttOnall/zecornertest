import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/users/user_profile_model.dart';

abstract class UserProfileState {}

class UserProfileInitial extends UserProfileState {}

class UserProfileLoading extends UserProfileState {}

class UserProfileLoaded extends UserProfileState {
  final UserProfileModel userProfile;

  UserProfileLoaded(this.userProfile);
}

class UserProfileError extends UserProfileState {
  final Failure failure;

  UserProfileError(this.failure);
}
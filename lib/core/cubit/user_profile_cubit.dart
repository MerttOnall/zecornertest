import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/auth/auth_session_storage.dart';
import 'package:zecorner/core/services/permission_service.dart';
import 'package:zecorner/infrastructure/users/user_profile_repository.dart';
import 'package:zecorner/models/users/user_profile_model.dart';
import 'package:zecorner/core/cubit/user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  final UserProfileRepository _userProfileRepository;

  UserProfileCubit({
    required UserProfileRepository userProfileRepository,
  })  : _userProfileRepository = userProfileRepository,
        super(UserProfileInitial());

  /// Load user profile data
  Future<void> loadUserProfile() async {
    final generation = AuthSessionStorage.sessionGeneration;
    emit(UserProfileLoading());
    
    final result = await _userProfileRepository.getUserProfile();
    if (!AuthSessionStorage.isCurrent(generation)) return;

    await result.fold(
      (failure) async {
        if (!AuthSessionStorage.isCurrent(generation)) return;
        emit(UserProfileError(failure));
      },
      (userProfile) async {
        await AuthSessionStorage.synchronized(() async {
          if (!AuthSessionStorage.isCurrent(generation)) return;
          await _syncAdminSession(userProfile);
        });
        if (!AuthSessionStorage.isCurrent(generation)) return;
        emit(UserProfileLoaded(userProfile));
      },
    );
  }

  /// Yalnızca kök `is_admin` yazılır. Rol listesine dokunulmaz.
  Future<void> _syncAdminSession(UserProfileModel profile) async {
    PermissionService().setSessionAdmin(profile.isAdmin);

    final pref = await SharedPreferences.getInstance();
    await pref.setBool('userIsAdmin', profile.isAdmin);

    final typeDescription = profile.typeDescription.trim();
    if (typeDescription.isNotEmpty) {
      await pref.setString('userTypeDescription', typeDescription);
    }

    final apiCodes = profile.roles
        .map((role) => role.code)
        .where((code) => code.isNotEmpty)
        .toList();
    if (!profile.isAdmin) {
      apiCodes.remove('role_admin');
    }
    if (apiCodes.isEmpty) return;
    await pref.setStringList('userRoleCodes', apiCodes);
    await pref.setString('userRoles', apiCodes.join(','));
    await pref.setString('roleCode', apiCodes.first);
  }

  /// Update user profile data
  Future<void> updateUserProfile({
    required String name,
    required String surname,
    required String profession,
    required String phone,
    required String city,
    required String district,
    required String neighborhood,
    required String address,
    required String about,
    String? facebook,
    String? instagram,
    String? x,
    String? linkedin,
    required String education,
    required bool marketingPermission,
  }) async {
    final generation = AuthSessionStorage.sessionGeneration;
    emit(UserProfileLoading());
    
    final result = await _userProfileRepository.updateUserProfile(
      name: name,
      surname: surname,
      profession: profession,
      phone: phone,
      city: city,
      district: district,
      neighborhood: neighborhood,
      address: address,
      about: about,
      facebook: facebook,
      instagram: instagram,
      x: x,
      linkedin: linkedin,
      education: education,
      marketingPermission: marketingPermission,
    );
    
    if (!AuthSessionStorage.isCurrent(generation)) return;
    await result.fold(
      (failure) async {
        if (!AuthSessionStorage.isCurrent(generation)) return;
        emit(UserProfileError(failure));
      },
      (userProfile) async {
        await AuthSessionStorage.synchronized(() async {
          if (!AuthSessionStorage.isCurrent(generation)) return;
          await _syncAdminSession(userProfile);
        });
        if (!AuthSessionStorage.isCurrent(generation)) return;
        emit(UserProfileLoaded(userProfile));
      },
    );
  }

  /// Clear state
  void clearState() {
    if (isClosed) return;
    emit(UserProfileInitial());
  }
}

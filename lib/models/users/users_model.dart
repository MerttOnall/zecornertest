class RoleModel {
  final String name;
  final String code;
  final bool isAdmin;
  final List<String>? permissions;
  final int? contactType;

  RoleModel({
    required this.name,
    required this.code,
    required this.isAdmin,
    this.permissions,
    this.contactType,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    bool asBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v?.toString().toLowerCase().trim();
      return s == 'true' || s == '1';
    }

    List<String>? asStringList(dynamic v) {
      if (v == null || v is! List) return null;
      return v.map((e) => e.toString()).toList();
    }

    int? asIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim());
    }

    return RoleModel(
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      isAdmin: asBool(json['is_admin']),
      permissions: asStringList(json['permissions']),
      contactType: asIntOrNull(json['contact_type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'is_admin': isAdmin,
      'permissions': permissions,
      'contact_type': contactType,
    };
  }

  List<Object?> get props => [name, code, isAdmin, permissions, contactType];
}

class UserModel {
  final String userId;
  final int userStatus;
  final int contactNo;
  final String title;
  final int type;
  final String email;
  final String tel;
  final int status;
  final String? picture;
  final List<RoleModel> roles;

  UserModel({
    required this.userId,
    required this.userStatus,
    required this.contactNo,
    required this.title,
    required this.type,
    required this.email,
    required this.tel,
    required this.status,
    this.picture,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim()) ?? 0;
    }

    String asString(dynamic v) => v?.toString() ?? '';

    List<RoleModel> rolesList = [];
    final rawRoles = json['roles'];
    if (rawRoles is List) {
      rolesList = rawRoles
          .whereType<Map>()
          .map((role) => RoleModel.fromJson(Map<String, dynamic>.from(role)))
          .toList();
    }

    return UserModel(
      userId: asString(json['user_id']),
      userStatus: asInt(json['user_status']),
      contactNo: asInt(json['contact_no']),
      title: asString(json['title']),
      type: asInt(json['type']),
      email: asString(json['e_mail'] ?? json['email']),
      tel: asString(json['tel']),
      status: asInt(json['status']),
      picture: json['picture']?.toString(),
      roles: rolesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_status': userStatus,
      'contact_no': contactNo,
      'title': title,
      'type': type,
      'e_mail': email,
      'tel': tel,
      'status': status,
      'picture': picture,
      'roles': roles.map((role) => role.toJson()).toList(),
    };
  }

  // Helper methods
  bool get isActive => status == 1;
  bool get isAdvisor => roles.any((role) => role.code == 'role_advisor');
  bool get isAdmin => roles.any((role) => role.isAdmin);
  String get roleDescription {
    final names = roles
        .map((role) => role.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) return 'Kullanıcı';
    return names.join(', ');
  }

  List<Object?> get props => [
    userId, userStatus, contactNo, title, type, email, tel, status, picture, roles
  ];
}

class UsersResponseModel {
  final List<UserModel> users;
  final int totalCount;
  final int totalPages;
  final int page;

  UsersResponseModel({
    required this.users,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory UsersResponseModel.fromJson(dynamic json) {
    int asInt(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim()) ?? fallback;
    }

    List<UserModel> parseUsers(dynamic raw) {
      if (raw is! List) return const [];
      final users = <UserModel>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final userId = map['user_id']?.toString().trim() ?? '';
        if (userId.isEmpty) continue;
        try {
          users.add(UserModel.fromJson(map));
        } catch (e) {
          print('⚠️ Kullanıcı parse atlandı: $e');
        }
      }
      return users;
    }

    if (json is List) {
      return UsersResponseModel(
        users: const [],
        totalCount: 0,
        totalPages: 1,
        page: 1,
      );
    }

    final map = json is Map<String, dynamic>
        ? json
        : json is Map
            ? Map<String, dynamic>.from(json)
            : <String, dynamic>{};
    if (map.containsKey('contacts') && !map.containsKey('users')) {
      return UsersResponseModel(
        users: const [],
        totalCount: 0,
        totalPages: 1,
        page: 1,
      );
    }
    final inner = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    final usersList = parseUsers(inner['users'] ?? map['users']);
    print('👥 ${usersList.length} kullanıcı parse edildi');

    return UsersResponseModel(
      users: usersList,
      totalCount: asInt(inner['totalCount'] ?? map['totalCount'], usersList.length),
      totalPages: asInt(inner['totalPages'] ?? map['totalPages'], 1),
      page: asInt(inner['page'] ?? map['page'], 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((user) => user.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }

  List<Object?> get props => [users, totalCount, totalPages, page];
}

import 'package:json_annotation/json_annotation.dart';

part 'permission_model.g.dart';

@JsonSerializable()
class Permission {
  final String id;
  final String name;
  final String resource;
  final String action;
  final String description;

  const Permission({
    required this.id,
    required this.name,
    required this.resource,
    required this.action,
    required this.description,
  });

  factory Permission.fromJson(Map<String, dynamic> json) => _$PermissionFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionToJson(this);

  factory Permission.fromMap(Map<String, dynamic> map) {
    return Permission(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      resource: map['resource'] ?? '',
      action: map['action'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'resource': resource,
      'action': action,
      'description': description,
    };
  }

  @override
  String toString() => 'Permission(id: $id, name: $name, resource: $resource, action: $action)';
}

@JsonSerializable()
class Role {
  final String id;
  final String name;
  final String description;
  final String? code;
  final List<Permission> permissions;
  final int level;

  const Role({
    required this.id,
    required this.name,
    required this.description,
    this.code,
    required this.permissions,
    required this.level,
  });

  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);
  Map<String, dynamic> toJson() => _$RoleToJson(this);

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      code: map['code'],
      permissions: (map['permissions'] as List<dynamic>?)
          ?.map((e) => Permission.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      level: map['level'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'permissions': permissions.map((p) => p.toMap()).toList(),
      'level': level,
    };
  }

  @override
  String toString() => 'Role(id: $id, name: $name, level: $level)';
} 
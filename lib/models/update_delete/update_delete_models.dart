/// Güncelleme ve Silme İşlemleri için Model Sınıfları
/// Bu dosya tüm güncelleme ve silme işlemleri için ortak model yapılarını içerir

/// Güncelleme işlemi için temel model
class UpdateModel {
  final String id;
  final Map<String, dynamic> updatedData;
  final DateTime updatedAt;
  final String updatedBy;
  final String? reason;

  UpdateModel({
    required this.id,
    required this.updatedData,
    required this.updatedAt,
    required this.updatedBy,
    this.reason,
  });

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    return UpdateModel(
      id: json['id'] ?? '',
      updatedData: Map<String, dynamic>.from(json['updated_data'] ?? {}),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      updatedBy: json['updated_by'] ?? '',
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'updated_data': updatedData,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
      'reason': reason,
    };
  }
}

/// Silme işlemi için temel model
class DeleteModel {
  final String id;
  final DateTime deletedAt;
  final String deletedBy;
  final String? reason;
  final bool isSoftDelete;

  DeleteModel({
    required this.id,
    required this.deletedAt,
    required this.deletedBy,
    this.reason,
    this.isSoftDelete = true,
  });

  factory DeleteModel.fromJson(Map<String, dynamic> json) {
    return DeleteModel(
      id: json['id'] ?? '',
      deletedAt: DateTime.parse(json['deleted_at'] ?? DateTime.now().toIso8601String()),
      deletedBy: json['deleted_by'] ?? '',
      reason: json['reason'],
      isSoftDelete: json['is_soft_delete'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deleted_at': deletedAt.toIso8601String(),
      'deleted_by': deletedBy,
      'reason': reason,
      'is_soft_delete': isSoftDelete,
    };
  }
}

/// API Response için genel model
class ApiResponseModel {
  final bool success;
  final String message;
  final dynamic data;
  final int? statusCode;

  ApiResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      statusCode: json['status_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'status_code': statusCode,
    };
  }
}

/// Güncelleme/Silme işlemi sonucu için model
class OperationResultModel {
  final bool isSuccess;
  final String message;
  final String? errorCode;
  final dynamic resultData;
  final DateTime timestamp;

  OperationResultModel({
    required this.isSuccess,
    required this.message,
    this.errorCode,
    this.resultData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory OperationResultModel.success({
    required String message,
    dynamic resultData,
  }) {
    return OperationResultModel(
      isSuccess: true,
      message: message,
      resultData: resultData,
    );
  }

  factory OperationResultModel.error({
    required String message,
    String? errorCode,
  }) {
    return OperationResultModel(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_success': isSuccess,
      'message': message,
      'error_code': errorCode,
      'result_data': resultData,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Toplu işlemler için model
class BulkOperationModel {
  final List<String> ids;
  final String operation; // 'update' veya 'delete'
  final Map<String, dynamic>? updateData;
  final String? reason;
  final String performedBy;

  BulkOperationModel({
    required this.ids,
    required this.operation,
    this.updateData,
    this.reason,
    required this.performedBy,
  });

  factory BulkOperationModel.fromJson(Map<String, dynamic> json) {
    return BulkOperationModel(
      ids: List<String>.from(json['ids'] ?? []),
      operation: json['operation'] ?? '',
      updateData: json['update_data'] != null 
          ? Map<String, dynamic>.from(json['update_data'])
          : null,
      reason: json['reason'],
      performedBy: json['performed_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
      'operation': operation,
      'update_data': updateData,
      'reason': reason,
      'performed_by': performedBy,
    };
  }
}

/// Toplu işlem sonucu için model
class BulkOperationResultModel {
  final int totalCount;
  final int successCount;
  final int failureCount;
  final List<String> successIds;
  final List<String> failureIds;
  final List<String> errorMessages;
  final DateTime timestamp;

  BulkOperationResultModel({
    required this.totalCount,
    required this.successCount,
    required this.failureCount,
    required this.successIds,
    required this.failureIds,
    required this.errorMessages,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory BulkOperationResultModel.fromJson(Map<String, dynamic> json) {
    return BulkOperationResultModel(
      totalCount: json['total_count'] ?? 0,
      successCount: json['success_count'] ?? 0,
      failureCount: json['failure_count'] ?? 0,
      successIds: List<String>.from(json['success_ids'] ?? []),
      failureIds: List<String>.from(json['failure_ids'] ?? []),
      errorMessages: List<String>.from(json['error_messages'] ?? []),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_count': totalCount,
      'success_count': successCount,
      'failure_count': failureCount,
      'success_ids': successIds,
      'failure_ids': failureIds,
      'error_messages': errorMessages,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

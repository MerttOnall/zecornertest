import '../models/update_delete/update_delete_models.dart';
import '../models/property_model.dart';

/// Güncelleme ve Silme İşlemleri için Servis Sınıfı
/// Bu servis tüm CRUD işlemlerini yönetir
class UpdateDeleteService {
  static final UpdateDeleteService _instance = UpdateDeleteService._internal();
  factory UpdateDeleteService() => _instance;
  UpdateDeleteService._internal();

  // Simulated API base URL - gerçek projede API endpoint'leri buraya gelecek
  // static const String _baseUrl = 'https://api.zecorner.com';

  /// Tekil güncelleme işlemi
  Future<OperationResultModel> updateItem({
    required String id,
    required Map<String, dynamic> updateData,
    required String updatedBy,
    String? reason,
    String endpoint = '/update',
  }) async {
    try {
      // Simulated API call delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Simulated API response - gerçek projede HTTP client kullanılacak
      final updateModel = UpdateModel(
        id: id,
        updatedData: updateData,
        updatedAt: DateTime.now(),
        updatedBy: updatedBy,
        reason: reason,
      );

      // Simulated success response
      return OperationResultModel.success(
        message: 'Güncelleme işlemi başarıyla tamamlandı',
        resultData: updateModel.toJson(),
      );
    } catch (e) {
      return OperationResultModel.error(
        message: 'Güncelleme işlemi sırasında hata oluştu: $e',
        errorCode: 'UPDATE_ERROR',
      );
    }
  }

  /// Tekil silme işlemi
  Future<OperationResultModel> deleteItem({
    required String id,
    required String deletedBy,
    String? reason,
    bool isSoftDelete = true,
    String endpoint = '/delete',
  }) async {
    try {
      // Simulated API call delay
      await Future.delayed(const Duration(milliseconds: 600));

      // Simulated API response
      final deleteModel = DeleteModel(
        id: id,
        deletedAt: DateTime.now(),
        deletedBy: deletedBy,
        reason: reason,
        isSoftDelete: isSoftDelete,
      );

      // Simulated success response
      return OperationResultModel.success(
        message: isSoftDelete 
            ? 'Silme işlemi başarıyla tamamlandı (soft delete)'
            : 'Silme işlemi başarıyla tamamlandı (hard delete)',
        resultData: deleteModel.toJson(),
      );
    } catch (e) {
      return OperationResultModel.error(
        message: 'Silme işlemi sırasında hata oluştu: $e',
        errorCode: 'DELETE_ERROR',
      );
    }
  }

  /// Toplu güncelleme işlemi
  Future<BulkOperationResultModel> bulkUpdate({
    required List<String> ids,
    required Map<String, dynamic> updateData,
    required String updatedBy,
    String? reason,
    String endpoint = '/bulk-update',
  }) async {
    try {
      // Simulated API call delay
      await Future.delayed(const Duration(milliseconds: 1200));

      // final bulkModel = BulkOperationModel(
      //   ids: ids,
      //   operation: 'update',
      //   updateData: updateData,
      //   reason: reason,
      //   performedBy: updatedBy,
      // );

      // Simulated bulk operation results
      final successCount = (ids.length * 0.9).round(); // %90 başarı oranı simülasyonu
      final failureCount = ids.length - successCount;
      
      final successIds = ids.take(successCount).toList();
      final failureIds = ids.skip(successCount).toList();
      final errorMessages = failureIds.map((id) => 'ID $id güncellenemedi').toList();

      return BulkOperationResultModel(
        totalCount: ids.length,
        successCount: successCount,
        failureCount: failureCount,
        successIds: successIds,
        failureIds: failureIds,
        errorMessages: errorMessages,
      );
    } catch (e) {
      return BulkOperationResultModel(
        totalCount: ids.length,
        successCount: 0,
        failureCount: ids.length,
        successIds: [],
        failureIds: ids,
        errorMessages: ['Toplu güncelleme işlemi sırasında hata oluştu: $e'],
      );
    }
  }

  /// Toplu silme işlemi
  Future<BulkOperationResultModel> bulkDelete({
    required List<String> ids,
    required String deletedBy,
    String? reason,
    bool isSoftDelete = true,
    String endpoint = '/bulk-delete',
  }) async {
    try {
      // Simulated API call delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // final bulkModel = BulkOperationModel(
      //   ids: ids,
      //   operation: 'delete',
      //   reason: reason,
      //   performedBy: deletedBy,
      // );

      // Simulated bulk operation results
      final successCount = (ids.length * 0.95).round(); // %95 başarı oranı simülasyonu
      final failureCount = ids.length - successCount;
      
      final successIds = ids.take(successCount).toList();
      final failureIds = ids.skip(successCount).toList();
      final errorMessages = failureIds.map((id) => 'ID $id silinemedi').toList();

      return BulkOperationResultModel(
        totalCount: ids.length,
        successCount: successCount,
        failureCount: failureCount,
        successIds: successIds,
        failureIds: failureIds,
        errorMessages: errorMessages,
      );
    } catch (e) {
      return BulkOperationResultModel(
        totalCount: ids.length,
        successCount: 0,
        failureCount: ids.length,
        successIds: [],
        failureIds: ids,
        errorMessages: ['Toplu silme işlemi sırasında hata oluştu: $e'],
      );
    }
  }

  /// Property güncelleme işlemi (özel)
  Future<OperationResultModel> updateProperty({
    required String propertyId,
    required PropertyModel updatedProperty,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      final updateData = updatedProperty.toJson();
      
      return await updateItem(
        id: propertyId,
        updateData: updateData,
        updatedBy: updatedBy,
        reason: reason,
        endpoint: '/properties/update',
      );
    } catch (e) {
      return OperationResultModel.error(
        message: 'Property güncelleme işlemi sırasında hata oluştu: $e',
        errorCode: 'PROPERTY_UPDATE_ERROR',
      );
    }
  }

  /// Property silme işlemi (özel)
  Future<OperationResultModel> deleteProperty({
    required String propertyId,
    required String deletedBy,
    String? reason,
    bool isSoftDelete = true,
  }) async {
    try {
      return await deleteItem(
        id: propertyId,
        deletedBy: deletedBy,
        reason: reason,
        isSoftDelete: isSoftDelete,
        endpoint: '/properties/delete',
      );
    } catch (e) {
      return OperationResultModel.error(
        message: 'Property silme işlemi sırasında hata oluştu: $e',
        errorCode: 'PROPERTY_DELETE_ERROR',
      );
    }
  }

  /// İşlem geçmişini getir
  Future<List<Map<String, dynamic>>> getOperationHistory({
    String? itemId,
    String? operationType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      // Simulated API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulated operation history data
      final history = <Map<String, dynamic>>[
        {
          'id': '1',
          'item_id': itemId ?? 'prop_001',
          'operation_type': operationType ?? 'update',
          'performed_by': 'admin@zecorner.com',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'details': 'Property bilgileri güncellendi',
          'success': true,
        },
        {
          'id': '2',
          'item_id': itemId ?? 'prop_002',
          'operation_type': 'delete',
          'performed_by': 'admin@zecorner.com',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
          'details': 'Property soft delete yapıldı',
          'success': true,
        },
      ];

      return history.take(limit).toList();
    } catch (e) {
      throw Exception('İşlem geçmişi alınırken hata oluştu: $e');
    }
  }

  /// İşlem durumunu kontrol et
  Future<bool> checkOperationStatus(String operationId) async {
    try {
      // Simulated API call delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Simulated status check - gerçek projede operation ID ile status kontrol edilecek
      return true; // Başarılı olarak simüle edildi
    } catch (e) {
      return false;
    }
  }

  /// Geri alma işlemi (undo)
  Future<OperationResultModel> undoOperation({
    required String operationId,
    required String performedBy,
    String? reason,
  }) async {
    try {
      // Simulated API call delay
      await Future.delayed(const Duration(milliseconds: 700));

      // Simulated undo operation
      return OperationResultModel.success(
        message: 'İşlem başarıyla geri alındı',
        resultData: {
          'operation_id': operationId,
          'undone_by': performedBy,
          'undo_reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      return OperationResultModel.error(
        message: 'Geri alma işlemi sırasında hata oluştu: $e',
        errorCode: 'UNDO_ERROR',
      );
    }
  }
}

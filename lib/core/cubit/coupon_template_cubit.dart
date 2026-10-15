import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../infrastructure/coupon/coupon_api_repository.dart';
import '../../models/coupon/coupon_template_model.dart';
import '../error/failures.dart';

part 'coupon_template_state.dart';

class CouponTemplateCubit extends Cubit<CouponTemplateState> {
  final CouponApiRepository _repository;
  List<CouponTemplateModel> _allTemplates = [];
  
  // Silinen template ID'lerini tut (refresh sonrası tekrar gelmesin)
  final Set<int> _deletedTemplateIds = <int>{};

  CouponTemplateCubit(this._repository) : super(CouponTemplateInitial());

  /// Getter'lar
  List<CouponTemplateModel> get allTemplates => _allTemplates;

  /// Kupon şablonlarını yükle
  Future<void> loadTemplates() async {
    try {
      emit(CouponTemplateLoading());

      final result = await _repository.getCouponTemplateList();

      result.fold(
        (failure) {
          print('❌ CouponTemplateCubit Error: ${failure.message}');
          emit(CouponTemplateError(failure));
        },
        (templateResponse) {
          print('✅ CouponTemplateCubit: ${templateResponse.templates.length} şablon geldi');
          
          // Silinen şablonları filtrele
          final filteredTemplates = templateResponse.templates
              .where((template) => !_deletedTemplateIds.contains(template.id))
              .toList();
          
          print('🗑️ Silinen şablonlar filtrelendi: ${_deletedTemplateIds.length} şablon');
          print('📋 Filtre sonrası: ${filteredTemplates.length} şablon (API: ${templateResponse.templates.length})');
          
          _allTemplates = filteredTemplates;

          emit(CouponTemplateLoaded(_allTemplates));
          print('✅ CouponTemplateLoaded state emit edildi: ${_allTemplates.length} şablon');
        },
      );
    } catch (e) {
      emit(CouponTemplateError(ServerFailure(message: 'Kupon şablonları yüklenirken hata oluştu: $e')));
    }
  }

  /// Listeyi yenile
  Future<void> refreshTemplates() async {
    await loadTemplates();
  }

  /// Kupon şablonu oluştur
  Future<void> createTemplate(Map<String, dynamic> data) async {
    try {
      final currentState = state;
      if (currentState is CouponTemplateLoaded) {
        emit(CouponTemplateCreating(currentState.templates));
      }

      final result = await _repository.createCouponTemplate(data);

      result.fold(
        (failure) {
          if (currentState is CouponTemplateLoaded) {
            emit(CouponTemplateError(failure));
          }
        },
        (template) {
          // Yeni şablonu listeye ekle
          _allTemplates.insert(0, template);
          emit(CouponTemplateLoaded(List.from(_allTemplates)));
          
          print('✅ Yeni şablon oluşturuldu: ${template.id}');
        },
      );
    } catch (e) {
      final currentState = state;
      if (currentState is CouponTemplateLoaded) {
        emit(CouponTemplateError(ServerFailure(message: 'Kupon şablonu oluşturulurken hata oluştu: $e')));
      }
    }
  }

  /// Kupon şablonu güncelle
  Future<void> updateTemplate(int id, Map<String, dynamic> data) async {
    try {
      final currentState = state;
      if (currentState is CouponTemplateLoaded) {
        emit(CouponTemplateUpdating(currentState.templates, id));
      }

      final result = await _repository.updateCouponTemplate(id, data);

      result.fold(
        (failure) {
          if (currentState is CouponTemplateLoaded) {
            emit(CouponTemplateError(failure));
          }
        },
        (updatedTemplate) {
          // Şablonu listede güncelle
          final index = _allTemplates.indexWhere((t) => t.id == id);
          if (index != -1) {
            _allTemplates[index] = updatedTemplate;
          }
          emit(CouponTemplateLoaded(List.from(_allTemplates)));
          
          print('✅ Şablon güncellendi: $id');
        },
      );
    } catch (e) {
      final currentState = state;
      if (currentState is CouponTemplateLoaded) {
        emit(CouponTemplateError(ServerFailure(message: 'Kupon şablonu güncellenirken hata oluştu: $e')));
      }
    }
  }

  /// Kupon şablonu sil (pasif hale getir - soft delete)
  /// Şablon listeden kaldırılmaz, sadece status'u 0 yapılır ve pasif olarak gösterilir
  Future<void> deleteTemplate(int templateId) async {
    try {
      // Silme başladı state'i
      final currentState = state;
      if (currentState is CouponTemplateLoaded) {
        emit(CouponTemplateDeleting(currentState.templates, templateId));
      }

      final result = await _repository.deleteCouponTemplate(templateId);

      result.fold(
        (failure) {
          // Hata durumunda mevcut state'i koru
          if (currentState is CouponTemplateLoaded) {
            emit(CouponTemplateDeleteError(currentState.templates, failure.message));
          }
        },
        (updatedTemplate) {
          // Başarılı - şablonu pasif hale getir ve state'i güncelle
          if (currentState is CouponTemplateLoaded) {
            // Listedeki şablonu bul ve status'unu güncelle
            final templateIndex = _allTemplates.indexWhere((template) => template.id == templateId);
            if (templateIndex != -1) {
              // Şablonu güncellenmiş haliyle değiştir (status: 0)
              _allTemplates[templateIndex] = updatedTemplate;
              
              // Güncellenmiş state'i emit et
              emit(CouponTemplateLoaded(List.from(_allTemplates)));
              
              print('✅ Şablon pasif hale getirildi: $templateId');
              print('📊 Güncel şablon sayısı: ${_allTemplates.length}');
              print('📋 Şablon status: ${updatedTemplate.status} (0 = Pasif)');
            } else {
              // Şablon listede yoksa, refresh yap
              loadTemplates();
            }
          }
        },
      );
    } catch (e) {
      // Hata durumunda mevcut state'i koru
      final currentState = state;
      if (currentState is CouponTemplateLoaded) {
        emit(CouponTemplateDeleteError(currentState.templates, 'Kupon şablonu silinirken hata oluştu: $e'));
      }
    }
  }

  /// State'i sıfırla
  void reset() {
    _allTemplates.clear();
    _deletedTemplateIds.clear();
    emit(CouponTemplateInitial());
  }
}


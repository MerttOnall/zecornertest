import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../infrastructure/announcement/announcement_api_repository.dart';
import '../../models/announcement/announcement_model.dart';
import '../../models/announcement/contact_type_model.dart';
import '../error/failures.dart';

part 'announcement_state.dart';

class AnnouncementCubit extends Cubit<AnnouncementState> {
  final AnnouncementApiRepository _repository;
  List<Announcement> _allAnnouncements = [];
  List<ContactType> _contactTypes = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  String? _currentSearch;

  AnnouncementCubit(this._repository) : super(AnnouncementInitial());

  // Contact types'ı getir
  List<ContactType> get contactTypes => _contactTypes;

  /// Contact Types (Roller) yükle
  Future<void> loadContactTypes() async {
    try {
      final result = await _repository.getContactTypes();

      result.fold(
        (failure) {
          print('❌ Contact types yüklenemedi: ${failure.message}');
          _contactTypes = [];
        },
        (types) {
          _contactTypes = types;
          print('✅ ${_contactTypes.length} adet contact type yüklendi');
          
          // Contact types yüklendikten sonra mevcut state'i güncelle (UI'ın yeniden çizilmesi için)
          final currentState = state;
          if (currentState is AnnouncementLoaded) {
            emit(AnnouncementLoaded(
              announcementResponse: currentState.announcementResponse,
              allAnnouncements: currentState.allAnnouncements,
            ));
          }
        },
      );
    } catch (e) {
      print('❌ Contact types yüklenirken hata: $e');
      _contactTypes = [];
    }
  }

  /// Contact type ID'ye göre isim getir
  String getContactTypeName(int id) {
    final contactType = _contactTypes.firstWhere(
      (ct) => ct.id == id,
      orElse: () => ContactType(id: id, name: 'Rol $id'),
    );
    return contactType.name;
  }

  /// Duyuruları yükle
  Future<void> loadAnnouncements({
    bool refresh = false,
    String? search,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _allAnnouncements.clear();
      _hasMoreData = true;
      _currentSearch = search;
    }

    if (!_hasMoreData && !refresh) return;

    try {
      if (refresh || _currentPage == 1) {
        emit(AnnouncementLoading());
      }

      final result = await _repository.getAnnouncements(
        page: _currentPage,
        limit: 20,
        search: search ?? _currentSearch,
      );

      result.fold(
        (failure) => emit(AnnouncementError(failure)),
        (announcementResponse) {
          if (refresh || _currentPage == 1) {
            _allAnnouncements = announcementResponse.announcements;
          } else {
            _allAnnouncements.addAll(announcementResponse.announcements);
          }

          _currentPage++;
          _hasMoreData = _currentPage <= announcementResponse.totalPages;

          emit(AnnouncementLoaded(
            announcementResponse: announcementResponse,
            allAnnouncements: List.from(_allAnnouncements),
          ));
        },
      );
    } catch (e) {
      emit(AnnouncementError(ServerFailure(message: 'Duyurular yüklenirken hata oluştu: $e')));
    }
  }

  /// Daha fazla duyuru yükle (pagination)
  Future<void> loadMoreAnnouncements() async {
    if (!_hasMoreData) return;

    final currentState = state;
    if (currentState is AnnouncementLoaded) {
      await loadAnnouncements(search: _currentSearch);
    }
  }

  /// Duyuru ara
  Future<void> searchAnnouncements(String query) async {
    _currentSearch = query;
    await loadAnnouncements(refresh: true, search: query);
  }

  /// Yeni duyuru oluştur
  Future<void> createAnnouncement({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    DateTime? announcementTime,
    required String category,
    required List<int> contactTypes,
    String? content,
  }) async {
    emit(AnnouncementCreating());

    try {
      final result = await _repository.createAnnouncement(
        title: title,
        startTime: startTime,
        endTime: endTime,
        announcementTime: announcementTime,
        category: category,
        contactTypes: contactTypes,
        content: content,
      );

      result.fold(
        (failure) => emit(AnnouncementCreateError(failure)),
        (newAnnouncement) {
          emit(AnnouncementCreated(newAnnouncement));
          // Duyuru oluşturulduktan sonra listeyi yenile
          loadAnnouncements(refresh: true);
        },
      );
    } catch (e) {
      emit(AnnouncementCreateError(ServerFailure(message: 'Duyuru oluşturulurken hata oluştu: $e')));
    }
  }

  /// Duyuruları yenile
  Future<void> refreshAnnouncements() async {
    // Contact types'ı da yeniden yükle
    if (_contactTypes.isEmpty) {
      await loadContactTypes();
    }
    await loadAnnouncements(refresh: true, search: _currentSearch);
  }

  /// State'i sıfırla
  void reset() {
    _currentPage = 1;
    _allAnnouncements.clear();
    _hasMoreData = true;
    _currentSearch = null;
    emit(AnnouncementInitial());
  }
}


import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/note/note_repository.dart';
import 'note_state.dart';

class NoteCubit extends Cubit<NoteState> {
  final NoteRepository _repository;

  NoteCubit({NoteRepository? repository}) 
      : _repository = repository ?? NoteRepository(),
        super(NoteInitial());

  void reset() {
    if (isClosed) return;
    emit(NoteInitial());
  }

  Future<void> fetchNotes({int page = 0, int? pageSize, String? search}) async {
    emit(NoteLoading());
    final result = await _repository.getNotes(page: page, pageSize: pageSize, search: search);
    result.fold(
      (failure) => emit(NoteError(failure.message)),
      (response) => emit(NoteLoaded(response.notes)),
    );
  }
}

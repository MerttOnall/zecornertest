import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/services/local_device_notification_service.dart';
import '../../infrastructure/task/task_repository.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final TaskRepository _repository;

  TaskCubit({TaskRepository? repository}) 
      : _repository = repository ?? TaskRepository(),
        super(TaskInitial());

  void reset() {
    if (isClosed) return;
    emit(TaskInitial());
  }

  Future<void> fetchTasks({int page = 0, String sort = 'desc'}) async {
    emit(TaskLoading());
    final result = await _repository.getTasks(page: page, sort: sort);
    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (response) {
        emit(TaskLoaded(response.tasks));
        LocalDeviceNotificationService.instance
            .syncTaskDueReminders(response.tasks);
      },
    );
  }
}

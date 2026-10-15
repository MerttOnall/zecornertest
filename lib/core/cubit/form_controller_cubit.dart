import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:zecorner/core/enums/action_enum.dart';
import 'package:zecorner/core/interfaces/form_model_interface.dart';

enum FormStatus {
  initial,
  loading,
  success,
  error,
}

class FormControllerState<T> {
  final FormStatus status;
  final T? data;
  final String? errorMessage;
  final ACTION action;

  FormControllerState({
    required this.status,
    this.data,
    this.errorMessage,
    required this.action,
  });

  FormControllerState<T> copyWith({
    FormStatus? status,
    T? data,
    String? errorMessage,
    ACTION? action,
  }) {
    return FormControllerState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      action: action ?? this.action,
    );
  }
}

class FormControllerCubit<T extends IFormModel, R> extends Cubit<FormControllerState<R>> {
  FormControllerCubit() : super(FormControllerState<R>(
    status: FormStatus.initial,
    action: ACTION.none,
  ));

  void setAction(ACTION action) {
    emit(state.copyWith(action: action));
  }

  Future<void> validateForm(T formModel, Future<Either<dynamic, R>> Function(T) submitFunction) async {
    emit(state.copyWith(status: FormStatus.loading));

    // Form validasyonu
    if (!formModel.isValid()) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: formModel.getErrorMessage(),
      ));
      return;
    }

    try {
      final result = await submitFunction(formModel);
      
      result.fold(
        (failure) {
          emit(state.copyWith(
            status: FormStatus.error,
            errorMessage: failure.message ?? 'Bir hata oluştu',
          ));
        },
        (data) {
          emit(state.copyWith(
            status: FormStatus.success,
            data: data,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: 'Beklenmeyen hata: $e',
      ));
    }
  }

  void reset() {
    emit(FormControllerState<R>(
      status: FormStatus.initial,
      action: ACTION.none,
    ));
  }
}
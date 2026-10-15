import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';
import '../utils/either.dart';

part 'item_watcher_state.dart';

abstract class ItemWatcherCubit<T> extends Cubit<ItemWatcherState<T>> {
  ItemWatcherCubit() : super(ItemWatcherInitial<T>());

  // Abstract method that subclasses must implement
  Future<Either<Failure, List<T>>> fetchItems();
  Future<Either<Failure, T>> fetchItem(String id);

  // Load all items
  Future<void> loadItems() async {
    emit(ItemWatcherLoading<T>());
    
    final result = await fetchItems();
    
    result.fold(
      (failure) => emit(ItemWatcherError<T>(failure)),
      (items) => emit(ItemWatcherLoaded<T>(items)),
    );
  }

  // Load single item
  Future<void> loadItem(String id) async {
    emit(ItemWatcherLoading<T>());
    
    final result = await fetchItem(id);
    
    result.fold(
      (failure) => emit(ItemWatcherError<T>(failure)),
      (item) => emit(ItemWatcherSingleLoaded<T>(item)),
    );
  }

  // Refresh items
  Future<void> refreshItems() async {
    // Don't show loading state for refresh
    final result = await fetchItems();
    
    result.fold(
      (failure) => emit(ItemWatcherError<T>(failure)),
      (items) => emit(ItemWatcherLoaded<T>(items)),
    );
  }

  // Clear state
  void clearState() {
    emit(ItemWatcherInitial<T>());
  }

  // Add item to current list (for optimistic updates)
  void addItem(T item) {
    final currentState = state;
    if (currentState is ItemWatcherLoaded<T>) {
      final updatedItems = [...currentState.items, item];
      emit(ItemWatcherLoaded<T>(updatedItems));
    }
  }

  // Update item in current list
  void updateItem(T item, bool Function(T) predicate) {
    final currentState = state;
    if (currentState is ItemWatcherLoaded<T>) {
      final updatedItems = currentState.items.map((existingItem) {
        return predicate(existingItem) ? item : existingItem;
      }).toList();
      emit(ItemWatcherLoaded<T>(updatedItems));
    }
  }

  // Remove item from current list
  void removeItem(bool Function(T) predicate) {
    final currentState = state;
    if (currentState is ItemWatcherLoaded<T>) {
      final updatedItems = currentState.items.where((item) => !predicate(item)).toList();
      emit(ItemWatcherLoaded<T>(updatedItems));
    }
  }

  // Get current items
  List<T> get currentItems {
    final currentState = state;
    if (currentState is ItemWatcherLoaded<T>) {
      return currentState.items;
    }
    return [];
  }

  // Check if has items
  bool get hasItems => currentItems.isNotEmpty;

  // Check if loading
  bool get isLoading => state is ItemWatcherLoading<T>;

  // Check if error
  bool get hasError => state is ItemWatcherError<T>;

  // Get error message
  String? get errorMessage {
    final currentState = state;
    if (currentState is ItemWatcherError<T>) {
      return currentState.failure.message;
    }
    return null;
  }
} 
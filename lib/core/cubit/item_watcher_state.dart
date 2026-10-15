part of 'item_watcher_cubit.dart';

abstract class ItemWatcherState<T> extends Equatable {
  const ItemWatcherState();

  @override
  List<Object?> get props => [];
}

class ItemWatcherInitial<T> extends ItemWatcherState<T> {}

class ItemWatcherLoading<T> extends ItemWatcherState<T> {}

class ItemWatcherLoaded<T> extends ItemWatcherState<T> {
  final List<T> items;

  const ItemWatcherLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class ItemWatcherSingleLoaded<T> extends ItemWatcherState<T> {
  final T item;

  const ItemWatcherSingleLoaded(this.item);

  @override
  List<Object?> get props => [item];
}

class ItemWatcherError<T> extends ItemWatcherState<T> {
  final Failure failure;

  const ItemWatcherError(this.failure);

  @override
  List<Object?> get props => [failure];
} 
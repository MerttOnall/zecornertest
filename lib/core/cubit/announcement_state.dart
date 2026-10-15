part of 'announcement_cubit.dart';

abstract class AnnouncementState extends Equatable {
  const AnnouncementState();

  @override
  List<Object?> get props => [];
}

class AnnouncementInitial extends AnnouncementState {}

class AnnouncementLoading extends AnnouncementState {}

class AnnouncementLoaded extends AnnouncementState {
  final AnnouncementResponse announcementResponse;
  final List<Announcement> allAnnouncements;

  const AnnouncementLoaded({
    required this.announcementResponse,
    required this.allAnnouncements,
  });

  @override
  List<Object?> get props => [announcementResponse, allAnnouncements];
}

class AnnouncementError extends AnnouncementState {
  final Failure failure;

  const AnnouncementError(this.failure);

  @override
  List<Object?> get props => [failure];
}

class AnnouncementCreating extends AnnouncementState {}

class AnnouncementCreated extends AnnouncementState {
  final Announcement newAnnouncement;

  const AnnouncementCreated(this.newAnnouncement);

  @override
  List<Object?> get props => [newAnnouncement];
}

class AnnouncementCreateError extends AnnouncementState {
  final Failure failure;

  const AnnouncementCreateError(this.failure);

  @override
  List<Object?> get props => [failure];
}


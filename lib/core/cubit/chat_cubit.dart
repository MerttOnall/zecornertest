import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/infrastructure/chat/chat_repository.dart';
import 'package:zecorner/models/chat/chat_model.dart';

// States
abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final ChatListModel chatList;
  final List<ChatItem> allChats;

  ChatLoaded({
    required this.chatList,
    required this.allChats,
  });
}

class ChatError extends ChatState {
  final String message;

  ChatError(this.message);
}

class ChatMessageSending extends ChatState {}

class ChatMessageSent extends ChatState {}

class ChatMessageError extends ChatState {
  final String message;

  ChatMessageError(this.message);
}

// Cubit
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  List<ChatItem> _allChats = [];
  int _currentPage = 1;
  bool _hasMoreData = true;

  ChatCubit(this._chatRepository) : super(ChatInitial());

  /// Chat listesini yükle
  Future<void> loadChatList({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _allChats.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    try {
      if (refresh) {
        emit(ChatLoading());
      }

      final result = await _chatRepository.getChatList(
        page: _currentPage,
        limit: 20,
      );

      result.fold(
        (failure) => emit(ChatError(failure.message)),
        (chatList) {
          if (refresh) {
            _allChats = chatList.chatList;
          } else {
            _allChats.addAll(chatList.chatList);
          }

          _currentPage++;
          _hasMoreData = _currentPage <= chatList.totalPages;

          emit(ChatLoaded(
            chatList: chatList,
            allChats: List.from(_allChats),
          ));
        },
      );
    } catch (e) {
      emit(ChatError('Chat listesi yüklenirken hata oluştu: $e'));
    }
  }

  /// Daha fazla chat yükle (pagination)
  Future<void> loadMoreChats() async {
    if (!_hasMoreData) return;
    await loadChatList();
  }

  /// Mesaj gönder
  Future<void> sendMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      emit(ChatMessageSending());

      final result = await _chatRepository.sendMessage(
        chatId: chatId,
        message: message,
      );

      result.fold(
        (failure) => emit(ChatMessageError(failure.message)),
        (success) {
          if (success) {
            emit(ChatMessageSent());
            // Chat listesini yenile
            loadChatList(refresh: true);
          } else {
            emit(ChatMessageError('Mesaj gönderilemedi'));
          }
        },
      );
    } catch (e) {
      emit(ChatMessageError('Mesaj gönderilirken hata oluştu: $e'));
    }
  }

  /// Mesajları okundu olarak işaretle
  Future<void> markAsRead(String chatId) async {
    try {
      final result = await _chatRepository.markAsRead(chatId);
      
      result.fold(
        (failure) {
          // Hata durumunda sessizce devam et
          print('Mesajlar okundu olarak işaretlenirken hata: ${failure.message}');
        },
        (success) {
          if (success) {
            // Local state'i güncelle
            final index = _allChats.indexWhere((chat) => chat.chatId == chatId);
            if (index != -1) {
              _allChats[index] = ChatItem(
                chatId: _allChats[index].chatId,
                name: _allChats[index].name,
                contactNo: _allChats[index].contactNo,
                typeDescription: _allChats[index].typeDescription,
                type: _allChats[index].type,
                picture: _allChats[index].picture,
                lastMessage: _allChats[index].lastMessage,
                lastMessageDate: _allChats[index].lastMessageDate,
                unseenCount: '0', // Okunmamış mesaj sayısını sıfırla
              );

              if (state is ChatLoaded) {
                emit(ChatLoaded(
                  chatList: (state as ChatLoaded).chatList,
                  allChats: List.from(_allChats),
                ));
              }
            }
          }
        },
      );
    } catch (e) {
      // Hata durumunda sessizce devam et
      print('Mesajlar okundu olarak işaretlenirken hata: $e');
    }
  }

  /// Chat'i arama
  List<ChatItem> searchChats(String query) {
    if (query.isEmpty) return _allChats;

    return _allChats.where((chat) {
      return chat.name.toLowerCase().contains(query.toLowerCase()) ||
             chat.lastMessage.toLowerCase().contains(query.toLowerCase()) ||
             chat.typeDescription.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Belirli bir chat'i getir
  ChatItem? getChatById(String chatId) {
    try {
      return _allChats.firstWhere((chat) => chat.chatId == chatId);
    } catch (e) {
      return null;
    }
  }

  /// State'i temizle
  void clearState() {
    emit(ChatInitial());
  }
}

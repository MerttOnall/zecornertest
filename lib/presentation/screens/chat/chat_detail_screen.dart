import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/infrastructure/chat/chat_repository.dart';
import 'package:zecorner/models/chat/chat_message_model.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String chatId;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.chatId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepository = ChatRepository();
  
  // Mesajları tutmak için liste
  List<ChatMessage> messages = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final result = await _chatRepository.getChatMessages(
        chatId: widget.chatId,
        page: 1,
        limit: 50,
      );

      result.fold(
        (failure) {
          setState(() {
            errorMessage = failure.message;
            isLoading = false;
          });
        },
        (chatMessagesModel) {
          setState(() {
            messages = chatMessagesModel.messages;
            isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Mesajlar yüklenirken hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final messageText = _messageController.text;
      _messageController.clear();

      // Optimistic update - mesajı hemen göster
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        contact: 61, // Current user ID
        chat: widget.chatId,
        messageDate: DateTime.now().toIso8601String(),
        message: messageText,
      );

      setState(() {
        messages.insert(0, tempMessage);
      });

      // Scroll'u en üste çek
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      // API'ye mesajı gönder
      try {
        final result = await _chatRepository.sendMessage(
          chatId: widget.chatId,
          message: messageText,
        );

        result.fold(
          (failure) {
            // Hata durumunda mesajı kaldır ve hata göster
            setState(() {
              messages.removeWhere((msg) => msg.id == tempMessage.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mesaj gönderilemedi: ${failure.message}'),
                backgroundColor: const Color.fromRGBO(238, 46, 36, 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          (success) {
            if (success) {
              // Başarılı ise mesajları yenile
              _loadMessages();
            } else {
              // Başarısız ise mesajı kaldır
              setState(() {
                messages.removeWhere((msg) => msg.id == tempMessage.id);
              });
            }
          },
        );
      } catch (e) {
        // Hata durumunda mesajı kaldır
        setState(() {
          messages.removeWhere((msg) => msg.id == tempMessage.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e'),
            backgroundColor: const Color.fromRGBO(238, 46, 36, 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leadingWidth: 30,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.imageUrl.isNotEmpty 
                  ? NetworkImage(widget.imageUrl)
                  : null,
              child: widget.imageUrl.isEmpty
                  ? Text(
                      widget.name.isNotEmpty 
                          ? widget.name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'çevrimiçi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // En altta arka plan rengi
          Container(
            color: Colors.grey[50],
          ),
          // Ortada SVG logo
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60.0),
              child: Opacity(
                opacity: 0.15,
                child: SvgPicture.asset(
                  'assets/logo/zecorner-logo1.svg',
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.width * 0.7,
                  fit: BoxFit.contain,
                  color: const Color(0xFFE53935).withOpacity(0.7),
                ),
              ),
            ),
          ),
          // En üstte mesajlaşma içeriği
          Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color.fromRGBO(238, 46, 36, 1),
                        ),
                      )
                    : errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  errorMessage!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadMessages,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromRGBO(238, 46, 36, 1),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Tekrar Dene'),
                                ),
                              ],
                            ),
                          )
                        : messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Henüz mesaj bulunamadı',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.all(16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  return _buildMessage(
                                    message: message.message,
                                    time: message.formattedTime,
                                    isMe: message.isFromCurrentUser,
                                  );
                                },
                              ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.white,
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.emoji_emotions_outlined),
                                onPressed: () {},
                                color: Colors.grey[600],
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: "Mesaj",
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.attach_file),
                                onPressed: () {},
                                color: Colors.grey[600],
                              ),
                              IconButton(
                                icon: const Icon(Icons.camera_alt),
                                onPressed: () {},
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(238, 46, 36, 1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // Role sistemine göre navbar seçimi
      bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final authCubit = context.read<AuthCubit>();
            return FutureBuilder<List<String>>(
              future: authCubit.getUserRoleCodes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                
                final userRoleCodes = snapshot.data ?? [];
                print('Chat Detail Screen - Bottom Navbar - User Role Codes: $userRoleCodes');
                
                // Role'e göre navbar seçimi
                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: 4); // Profile tab
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: 4); // Profile tab
                } else if (userRoleCodes.contains('role_office_broker') || userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: 4); // Profile tab
                } else if (userRoleCodes.contains('role_form_applications') || userRoleCodes.contains('role_form_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 4); // Profile tab
                } else if (userRoleCodes.contains('role_sale_applications') || userRoleCodes.contains('role_sale_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 4); // Profile tab
                } else {
                  return const FrancahiseNavbar(currentIndex: 3); // Chat tab
                }
              },
            );
          }
          return const AdminNavbar(currentIndex: 4);
        },
      ),
    );
  }

  Widget _buildMessage({
    required String message,
    required String time,
    required bool isMe,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE53935) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:zecorner/core/cubit/chat_cubit.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/infrastructure/chat/chat_repository.dart';
import 'package:zecorner/models/chat/chat_model.dart';
import 'package:zecorner/presentation/screens/chat/chat_detail_screen.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';

class ProfileChatScreen extends StatefulWidget {
  const ProfileChatScreen({super.key});

  @override
  State<ProfileChatScreen> createState() => _ProfileChatScreenState();
}

class ProfileChatScreenWrapper extends StatelessWidget {
  const ProfileChatScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubit(ChatRepository()),
      child: const ProfileChatScreen(),
    );
  }
}

// BlocProvider olmadan çalışan basit versiyon
class SimpleProfileChatScreen extends StatefulWidget {
  const SimpleProfileChatScreen({super.key});

  @override
  State<SimpleProfileChatScreen> createState() => _SimpleProfileChatScreenState();
}

class _SimpleProfileChatScreenState extends State<SimpleProfileChatScreen> {
  List<ChatItem> contacts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChatList();
  }

  Future<void> _loadChatList() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // API çağrısı yap
      final chatRepository = ChatRepository();
      final result = await chatRepository.getChatList();

      result.fold(
        (failure) {
          setState(() {
            errorMessage = failure.message;
            isLoading = false;
          });
        },
        (chatList) {
          setState(() {
            contacts = chatList.chatList;
            isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Chat listesi yüklenirken hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(238, 46, 36, 1),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
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
                onPressed: _loadChatList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(238, 46, 36, 1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mesajlar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: contacts.isEmpty
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
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return _buildContactTile(contact);
              },
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
                print('Chat Screen - Bottom Navbar - User Role Codes: $userRoleCodes');
                
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

  Widget _buildContactTile(ChatItem contact) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: contact.profileImageUrl.isNotEmpty
                ? Image.network(
                    contact.profileImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[600]!,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Text(
                            contact.initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Text(
                        contact.initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          contact.lastMessage,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              contact.formattedTime,
              style: TextStyle(
                color: contact.unreadCount > 0 ? const Color(0xFFE53935) : Colors.grey[500],
                fontSize: 12,
                fontWeight: contact.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (contact.unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(238, 46, 36, 1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  contact.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          // Chat detayına git
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                name: contact.name,
                imageUrl: contact.profileImageUrl.isNotEmpty 
                    ? contact.profileImageUrl 
                    : 'https://via.placeholder.com/100x100/cccccc/ffffff?text=${contact.initials}',
                chatId: contact.chatId,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileChatScreenState extends State<ProfileChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  
  late Animation<double> _floatingAnimation;
  
  int _currentIndex = 4; // Profile tab index
  
  String? selectedContactId;
  TextEditingController messageController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  
  // Dynamic message storage for each contact
  Map<String, List<ChatMessage>> contactMessages = {};
  
  // Scroll controller for automatic scrolling
  final ScrollController _scrollController = ScrollController();
  
  // Search functionality
  bool _isSearchMode = false;
  String _searchQuery = '';
  
  // Selected messages for bulk operations
  Set<String> _selectedMessages = {};
  bool _isSelectionMode = false;


  // API'den gelen chat verileri
  List<ChatItem> contacts = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize messages for each contact
    _initializeMessages();
    
    // Animation controllers
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    // Animations
    _floatingAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Chat listesini yükle - WidgetsBinding.instance.addPostFrameCallback kullanarak
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        try {
          context.read<ChatCubit>().loadChatList(refresh: true);
        } catch (e) {
          print('ChatCubit bulunamadı: $e');
        }
      }
    });
  }

  void _initializeMessages() {
    // Initialize with some sample messages for each contact
    // Bu metod artık API'den gelen verilerle çalışacak
    // Örnek mesajlar sadece demo amaçlı
  }

  // Message operations
  void _deleteMessage(String messageId) {
    if (selectedContactId == null) return;
    
    setState(() {
      contactMessages[selectedContactId!]?.removeWhere((msg) => msg.id == messageId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mesaj silindi'),
        backgroundColor: Color.fromRGBO(238, 46, 36, 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteSelectedMessages() {
    if (selectedContactId == null || _selectedMessages.isEmpty) return;
    
    setState(() {
      contactMessages[selectedContactId!]?.removeWhere((msg) => _selectedMessages.contains(msg.id));
      _selectedMessages.clear();
      _isSelectionMode = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seçili mesajlar silindi'),
        backgroundColor: Color.fromRGBO(238, 46, 36, 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _forwardMessage(String messageId) {
    // Implementation for message forwarding
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mesaj iletme özelliği yakında eklenecek'),
        backgroundColor: Color.fromRGBO(238, 46, 36, 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyMessage(String message) {
    // Implementation for copying message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mesaj kopyalandı'),
        backgroundColor: Color.fromRGBO(238, 46, 36, 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Search functionality
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchQuery = '';
        searchController.clear();
      }
    });
  }

  List<ChatItem> _getFilteredContacts() {
    if (_searchQuery.isEmpty) return contacts;
    
    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             contact.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<ChatMessage> _getFilteredMessages() {
    if (selectedContactId == null) return [];
    
    final messages = contactMessages[selectedContactId!] ?? [];
    if (_searchQuery.isEmpty) return messages;
    
    return messages.where((message) {
      return message.message.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty || selectedContactId == null) return;
    
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      message: message.trim(),
      time: _getCurrentTime(),
      isMe: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      // Add message to selected contact's message list
      if (contactMessages[selectedContactId!] == null) {
        contactMessages[selectedContactId!] = [];
      }
      contactMessages[selectedContactId!]!.add(newMessage);
      
      // Update contact's last message and time
      final contactIndex = contacts.indexWhere((c) => c.chatId == selectedContactId);
      if (contactIndex != -1) {
        contacts[contactIndex] = ChatItem(
          chatId: contacts[contactIndex].chatId,
          name: contacts[contactIndex].name,
          contactNo: contacts[contactIndex].contactNo,
          typeDescription: contacts[contactIndex].typeDescription,
          type: contacts[contactIndex].type,
          picture: contacts[contactIndex].picture,
          lastMessage: message.trim(),
          lastMessageDate: DateTime.now().toIso8601String(),
          unseenCount: contacts[contactIndex].unseenCount,
        );
      }
      
      messageController.clear();
    });
    
    // Auto scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<ChatMessage> _getCurrentMessages() {
    if (_isSearchMode) {
      return _getFilteredMessages();
    }
    if (selectedContactId == null) return [];
    return contactMessages[selectedContactId!] ?? [];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectContact(String contactId) {
    setState(() {
      selectedContactId = contactId;
      _isSearchMode = false;
      _searchQuery = '';
      searchController.clear();
      _isSelectionMode = false;
      _selectedMessages.clear();
    });
    
    // Mesajları okundu olarak işaretle
    context.read<ChatCubit>().markAsRead(contactId);
    
    // Scroll to bottom when selecting a contact
    _scrollToBottom();
  }

  void _makeCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arama özelliği yakında eklenecek'),
        backgroundColor: Color.fromRGBO(238, 46, 36, 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _makeVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video arama özelliği yakında eklenecek'),
        backgroundColor: Color.fromRGBO(238, 46, 36, 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(Icons.search, 'Sohbette Ara', _toggleSearchMode),
            _buildOptionTile(Icons.block, 'Engelle', () {}),
            _buildOptionTile(Icons.delete, 'Sohbeti Sil', _deleteChatConfirmation),
            _buildOptionTile(Icons.report, 'Şikayet Et', () {}),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _deleteChatConfirmation() {
    if (selectedContactId == null) return;
    
    final selectedContact = contacts.firstWhere((c) => c.chatId == selectedContactId);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sohbeti Sil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${selectedContact.name} ile olan tüm mesajları silmek istediğinize emin misiniz?',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bu işlem geri alınamaz.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCurrentChat();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Evet, Sil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteCurrentChat() {
    if (selectedContactId == null) return;
    
    final selectedContact = contacts.firstWhere((c) => c.chatId == selectedContactId);
    
    setState(() {
      // Remove contact from list
      contacts.removeWhere((c) => c.chatId == selectedContactId);
      
      // Remove all messages for this contact
      contactMessages.remove(selectedContactId);
      
      // Go back to contact list
      selectedContactId = null;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${selectedContact.name} ile olan sohbet silindi',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFE53935)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }


  void _showNewChatOptions() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewMessageScreen(),
      ),
    );
    
    // Handle the result if a message was sent
    if (result != null && result['action'] == 'send_message') {
      final contactData = result['contact'];
      final message = result['message'];
      
      // Create new contact
      final newContact = ChatItem(
        chatId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: contactData['name'],
        contactNo: 0,
        typeDescription: contactData['role'] ?? 'Kullanıcı',
        type: 'PRIVATE',
        picture: null,
        lastMessage: message,
        lastMessageDate: DateTime.now().toIso8601String(),
        unseenCount: '0',
      );
      
      // Create initial message
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'me',
        message: message,
        time: _getCurrentTime(),
        isMe: true,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        // Check if contact already exists
        final existingIndex = contacts.indexWhere((c) => c.name == contactData['name']);
        
        if (existingIndex != -1) {
          // Update existing contact
          contacts[existingIndex] = ChatItem(
            chatId: contacts[existingIndex].chatId,
            name: contacts[existingIndex].name,
            contactNo: contacts[existingIndex].contactNo,
            typeDescription: contacts[existingIndex].typeDescription,
            type: contacts[existingIndex].type,
            picture: contacts[existingIndex].picture,
            lastMessage: message,
            lastMessageDate: DateTime.now().toIso8601String(),
            unseenCount: contacts[existingIndex].unseenCount,
          );
          
          // Add message to existing contact
          if (contactMessages[contacts[existingIndex].chatId] == null) {
            contactMessages[contacts[existingIndex].chatId] = [];
          }
          contactMessages[contacts[existingIndex].chatId]!.add(newMessage);
         } else {
           // Add new contact to the top of the list
           contacts.insert(0, newContact);
           contactMessages[newContact.chatId] = [newMessage];
         }
         
         // Stay on contact list screen (don't auto-select contact)
         selectedContactId = null;
       });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj ${contactData['name']} kişisine gönderildi'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _scrollController.dispose();
    messageController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          current is ChatLoaded || current is ChatError,
      listener: (context, state) {
        if (state is ChatLoaded) {
          setState(() {
            contacts = state.allChats;
          });
        }
        if (state is ChatError && contacts.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color.fromRGBO(238, 46, 36, 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (selectedContactId != null) {
          return _buildChatScreen();
        }

        if (state is ChatError && contacts.isEmpty) {
          return _buildFullScreenError(state.message);
        }

        if (state is ChatInitial ||
            (state is ChatLoading && contacts.isEmpty)) {
          return _buildFullScreenLoading();
        }

        return _buildContactListScreen(
          isRefreshing: state is ChatLoading && contacts.isNotEmpty,
        );
      },
    );
  }

  Widget _buildFullScreenLoading() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mesajlar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: CircularProgressIndicator(
          color: Color.fromRGBO(238, 46, 36, 1),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildFullScreenError(String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mesajlar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    context.read<ChatCubit>().loadChatList(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(238, 46, 36, 1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildContactListScreen({bool isRefreshing = false}) {
    final filteredContacts = _getFilteredContacts();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSearchMode
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ara...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Mesajlar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
        centerTitle: !_isSearchMode,
        actions: [
          IconButton(
            icon: Icon(
              _isSearchMode ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: _toggleSearchMode,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildSubtleBackground()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isRefreshing)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFFE53935),
                  backgroundColor: Color(0xFFFFCDD2),
                ),
              if (!_isSearchMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Text(
                    filteredContacts.isEmpty
                        ? 'Henüz mesaj bulunamadı'
                        : 'Daha fazla mesaj bulunamadı',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: filteredContacts.isEmpty && _isSearchMode
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Arama sonucu bulunamadı',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = filteredContacts[index];
                          return _buildContactTile(contact);
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatOptions,
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildChatScreen() {
    final selectedContact = contacts.firstWhere((c) => c.chatId == selectedContactId);
    final currentMessages = _getCurrentMessages();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              selectedContactId = null;
              _isSearchMode = false;
              _searchQuery = '';
              searchController.clear();
              _isSelectionMode = false;
              _selectedMessages.clear();
            });
          },
        ),
        title: _isSearchMode
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Mesajlarda ara...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: selectedContact.profileImageUrl.isNotEmpty
                          ? Image.network(
                              selectedContact.profileImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.white,
                                  child: Center(
                                    child: Text(
                                      selectedContact.initials,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromRGBO(238, 46, 36, 1),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.white,
                              child: Center(
                                child: Text(
                                  selectedContact.initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(238, 46, 36, 1),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedContact.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          selectedContact.typeDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteSelectedMessages,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedMessages.clear();
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: Icon(
                    _isSearchMode ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: _toggleSearchMode,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  onPressed: _makeVideoCall,
                ),
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.white),
                  onPressed: _makeCall,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: _showChatOptions,
                ),
              ],
      ),
      body: Column(
        children: [
          // Selection mode info bar
          if (_isSelectionMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFE53935).withOpacity(0.1),
              child: Text(
                '${_selectedMessages.length} mesaj seçildi',
                style: const TextStyle(
                  color: Color.fromRGBO(238, 46, 36, 1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          // Messages Area
          Expanded(
            child: currentMessages.isEmpty 
              ? _buildEmptyMessageArea(selectedContact)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: currentMessages.length,
                  reverse: false,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final message = currentMessages[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _buildMessageBubble(message),
                    );
                  },
                ),
          ),
          
          // Message Input Area
          if (!_isSearchMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
                              onPressed: () {},
                            ),
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Mesaj yazın...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _sendMessage(value);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.camera_alt, color: Colors.grey[600]),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(238, 46, 36, 1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          if (messageController.text.isNotEmpty) {
                            _sendMessage(messageController.text);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessageArea(ChatItem contact) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: ClipOval(
              child: contact.profileImageUrl.isNotEmpty
                  ? Image.network(
                      contact.profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Text(
                              contact.initials,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                fontSize: 24,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          contact.initials,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            contact.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            contact.typeDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Mesajlaşmaya başlamak için bir mesaj yazın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtleBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFBFB),
            Color(0xFFFFF5F5),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle floating particles
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Positioned(
                  left: (index * 150.0) % MediaQuery.of(context).size.width,
                  top: 100 + (index * 200.0) % 400 + _floatingAnimation.value,
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE53935).withOpacity(0.1),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactTile(ChatItem contact) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: contact.profileImageUrl.isNotEmpty
                    ? Image.network(
                        contact.profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Text(
                                contact.initials,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Text(
                            contact.initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            // Online durumu için şimdilik boş bırakıyoruz
          ],
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          contact.lastMessage,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              contact.formattedTime,
              style: TextStyle(
                color: contact.unreadCount > 0 ? const Color(0xFFE53935) : Colors.grey[500],
                fontSize: 12,
                fontWeight: contact.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (contact.unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(238, 46, 36, 1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  contact.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          _selectContact(contact.chatId);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isSelected = _selectedMessages.contains(message.id);
    
    return GestureDetector(
      onTap: _isSelectionMode 
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedMessages.remove(message.id);
                  if (_selectedMessages.isEmpty) {
                    _isSelectionMode = false;
                  }
                } else {
                  _selectedMessages.add(message.id);
                }
              });
            }
          : null,
      onLongPress: () {
        if (!_isSelectionMode) {
          _showMessageOptions(message);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Row(
          mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (_isSelectionMode && !message.isMe) ...[
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedMessages.add(message.id);
                    } else {
                      _selectedMessages.remove(message.id);
                      if (_selectedMessages.isEmpty) {
                        _isSelectionMode = false;
                      }
                    }
                  });
                },
                activeColor: const Color(0xFFE53935),
              ),
            ],
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFFE53935).withOpacity(0.8)
                    : message.isMe ? const Color(0xFFE53935) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: message.isMe ? const Radius.circular(12) : const Radius.circular(2),
                  bottomRight: message.isMe ? const Radius.circular(2) : const Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: isSelected 
                    ? Border.all(color: const Color(0xFFE53935), width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: message.isMe || isSelected ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.time,
                        style: TextStyle(
                          color: message.isMe || isSelected ? Colors.white70 : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      if (message.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 16,
                          color: isSelected ? Colors.white70 : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (_isSelectionMode && message.isMe) ...[
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedMessages.add(message.id);
                    } else {
                      _selectedMessages.remove(message.id);
                      if (_selectedMessages.isEmpty) {
                        _isSelectionMode = false;
                      }
                    }
                  });
                },
                activeColor: const Color(0xFFE53935),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildMessageOptionTile(Icons.copy, 'Kopyala', () => _copyMessage(message.message)),
            if (message.isMe) 
              _buildMessageOptionTile(Icons.delete, 'Sil', () => _deleteMessage(message.id)),
            _buildMessageOptionTile(Icons.forward, 'İlet', () => _forwardMessage(message.id)),
            _buildMessageOptionTile(Icons.select_all, 'Seç', () {
              setState(() {
                _isSelectionMode = true;
                _selectedMessages.add(message.id);
              });
            }),
            if (message.isMe)
              _buildMessageOptionTile(Icons.info_outline, 'Bilgi', () => _showMessageInfo(message)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFE53935)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _showMessageInfo(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mesaj Bilgisi', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Gönderilme:', message.time),
            const SizedBox(height: 8),
            _buildInfoRow('Durum:', 'İletildi'),
            const SizedBox(height: 8),
            _buildInfoRow('Mesaj:', message.message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

// New Message Screen (WhatsApp style)
class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Sample contacts - in real app this would come from phone contacts
  final List<Map<String, String>> _contacts = [
    {'name': 'Ali Yılmaz', 'email': 'danisman1@gmail.com', 'role': 'Gayrimenkul Danışmanı'},
    {'name': 'Danışman Yeni', 'email': 'danismann@gmail.com', 'role': 'Gayrimenkul Danışmanı'},
    {'name': 'Deniz Şimşek', 'email': 'deniz.simsek@zecorner.com', 'role': 'Gayrimenkul Danışmanı'},
    {'name': 'Ebru Yılmaz', 'email': 'danisman2@gmail.com', 'role': 'Gayrimenkul Danışmanı'},
    {'name': 'Elif Yılmaz', 'email': 'danisman6@gmail.com', 'role': 'Gayrimenkul Danışmanı'},
    {'name': 'Fatih Kara', 'email': 'danisman5@gmail.com', 'role': 'Gayrimenkul Danışmanı'},
  ];

  List<Map<String, String>> _getFilteredContacts() {
    if (_searchQuery.isEmpty) return _contacts;
    
    return _contacts.where((contact) {
      final name = contact['name'] ?? '';
      final email = contact['email'] ?? '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Color _getAvatarColor(int index) {
    final colors = [
      const Color(0xFFE8F5E8), // Light green
      const Color(0xFFF0F0F0), // Light gray
      const Color(0xFFFFE8E8), // Light red
      const Color(0xFFE8E8FF), // Light blue
      const Color(0xFFFFF0E8), // Light orange
      const Color(0xFFE8FFE8), // Light mint
    ];
    return colors[index % colors.length];
  }

  Color _getTextColor(int index) {
    final colors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF757575), // Gray
      const Color(0xFFE53935), // Red
      const Color(0xFF3F51B5), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF009688), // Teal
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _getFilteredContacts();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yeni Mesaj',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Mesaj göndermek istediğiniz kişiyi ve mesaj giriniz.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kullanıcı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ara',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE53935)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contacts list
          Expanded(
            child: ListView.builder(
              itemCount: filteredContacts.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageComposeScreen(
                            recipientName: contact['name'] ?? '',
                            recipientEmail: contact['email'] ?? '',
                            recipientRole: contact['role'] ?? '',
                          ),
                        ),
                      );
                      
                      // If message was sent, return the result to chat screen
                      if (result != null && result['action'] == 'send_message') {
                        Navigator.of(context).pop(result);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getAvatarColor(index),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                (contact['name'] ?? 'U').substring(0, 2).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getTextColor(index),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Contact info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact['name'] ?? 'Bilinmeyen',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  contact['email'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  contact['role'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Message Compose Screen
class MessageComposeScreen extends StatefulWidget {
  final String recipientName;
  final String recipientEmail;
  final String recipientRole;

  const MessageComposeScreen({
    super.key,
    required this.recipientName,
    required this.recipientEmail,
    required this.recipientRole,
  });

  @override
  State<MessageComposeScreen> createState() => _MessageComposeScreenState();
}

class _MessageComposeScreenState extends State<MessageComposeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _searchController.text = widget.recipientName;
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir mesaj yazın'),
          backgroundColor: Color.fromRGBO(238, 46, 36, 1),
        ),
      );
      return;
    }

    // Return the new contact data and message to the previous screen
    Navigator.of(context).pop({
      'action': 'send_message',
      'contact': {
        'name': widget.recipientName,
        'email': widget.recipientEmail,
        'role': widget.recipientRole,
      },
      'message': _messageController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yeni Mesaj',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Mesaj göndermek istediğiniz kişiyi ve mesaj giriniz.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          
          // Recipient field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kullanıcı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Ara',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Message field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mesaj',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı buraya yazın...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE53935)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Send button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Gönder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatContact {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String avatar;
  final bool isOnline;
  final int unreadCount;

  ChatContact({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatar,
    required this.isOnline,
    required this.unreadCount,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String message;
  final String time;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.time,
    required this.isMe,
    required this.timestamp,
  });
}


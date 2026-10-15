import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/screens/chat/chat_detail_screen.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'dart:math' as math;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  
  String? selectedContactId;
  TextEditingController messageController = TextEditingController();
  
  // Dynamic message storage for each contact
  Map<String, List<ChatMessage>> contactMessages = {};
  
  // Scroll controller for automatic scrolling
  final ScrollController _scrollController = ScrollController();
  
  // Sample chat data
  List<ChatContact> contacts = [
    ChatContact(
      id: '1',
      name: 'Fatih Çamcıoğlu',
      lastMessage: 'aynen kenks',
      time: '5 ay önce',
      avatar: 'https://picsum.photos/200?random=1',
      isOnline: false,
      unreadCount: 0,
    ),
    ChatContact(
      id: '2',
      name: 'Enes Karaca',
      lastMessage: 'Merhaba',
      time: '7 ay önce',
      avatar: 'https://picsum.photos/200?random=2',
      isOnline: true,
      unreadCount: 1,
    ),
    ChatContact(
      id: '3',
      name: 'Ali Yılmaz',
      lastMessage: 'Nasılsınız?',
      time: '2 gün önce',
      avatar: 'https://picsum.photos/200?random=3',
      isOnline: false,
      unreadCount: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize messages for each contact
    _initializeMessages();
    
    // Animation controllers
    _rotationController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    // Animations
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeMessages() {
    // Initialize with some sample messages for each contact
    contactMessages['1'] = [
      ChatMessage(
        id: '1_1',
        senderId: '1',
        message: 'Merhaba, nasılsınız?',
        time: '14:30',
        isMe: false,
      ),
      ChatMessage(
        id: '1_2',
        senderId: '1',
        message: 'aynen kenks',
        time: '14:35',
        isMe: false,
      ),
    ];
    
    contactMessages['2'] = [
      ChatMessage(
        id: '2_1',
        senderId: '2',
        message: 'Merhaba',
        time: '09:15',
        isMe: false,
      ),
      ChatMessage(
        id: '2_2',
        senderId: 'me',
        message: 'Merhaba, nasılsınız?',
        time: '09:20',
        isMe: true,
      ),
    ];
    
    contactMessages['3'] = [
      ChatMessage(
        id: '3_1',
        senderId: '3',
        message: 'Nasılsınız?',
        time: '18:10',
        isMe: false,
      ),
      ChatMessage(
        id: '3_2',
        senderId: 'me',
        message: 'İyi, teşekkürler. Siz nasılsınız?',
        time: '18:12',
        isMe: true,
      ),
      ChatMessage(
        id: '3_3',
        senderId: '3',
        message: 'Ben de iyiyim, sağ olun',
        time: '18:15',
        isMe: false,
      ),
    ];
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty || selectedContactId == null) return;
    
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      message: message.trim(),
      time: _getCurrentTime(),
      isMe: true,
    );
    
    setState(() {
      // Add message to selected contact's message list
      if (contactMessages[selectedContactId!] == null) {
        contactMessages[selectedContactId!] = [];
      }
      contactMessages[selectedContactId!]!.add(newMessage);
      
      // Update contact's last message and time
      final contactIndex = contacts.indexWhere((c) => c.id == selectedContactId);
      if (contactIndex != -1) {
        contacts[contactIndex] = ChatContact(
          id: contacts[contactIndex].id,
          name: contacts[contactIndex].name,
          lastMessage: message.trim(),
          time: 'Şimdi',
          avatar: contacts[contactIndex].avatar,
          isOnline: contacts[contactIndex].isOnline,
          unreadCount: contacts[contactIndex].unreadCount,
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
    });
    // Scroll to bottom when selecting a contact
    _scrollToBottom();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedContactId == null) {
      return _buildContactListScreen();
    } else {
      return _buildChatScreen();
    }
  }

  Widget _buildContactListScreen() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'Mesajlar');
        },
      ),
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpen = isOpened;
        });
      },
      drawerScrimColor: Colors.black54,
      drawerEdgeDragWidth: 0,
      appBar: AdminPanelAppBar(
        title: "Mesajlar",
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: GestureDetector(
        onTap: () {
          if (_isDrawerOpen) {
            _scaffoldKey.currentState?.closeDrawer();
          }
        },
        child: AbsorbPointer(
          absorbing: _isDrawerOpen,
          child: Stack(
            children: [
              // Subtle background
              _buildSubtleBackground(),
              
              // Contact List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    // Search Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Mesaj Ara...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                        ),
                      ),
                    ),
                    
                    // Contact List
                    Expanded(
                      child: contacts.isEmpty
                          ? Center(
                              child: Text(
                                'Henüz mesaj bulunmuyor',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: contacts.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final contact = contacts[index];
                                return _buildContactTile(contact);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: AdminNavbar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildChatScreen() {
    final selectedContact = contacts.firstWhere((c) => c.id == selectedContactId);
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
            });
          },
        ),
        title: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  selectedContact.avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white,
                      child: Center(
                        child: Text(
                          selectedContact.name.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(238, 46, 36, 1),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
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
                    selectedContact.isOnline ? 'çevrimiçi' : 'son görülme belirsiz',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
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

  Widget _buildEmptyMessageArea(ChatContact contact) {
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
              child: Image.network(
                contact.avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Text(
                        contact.name.substring(0, 2).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontSize: 24,
                        ),
                      ),
                    ),
                  );
                },
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
            'Mesaj Kişisi',
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

  Widget _buildContactTile(ChatContact contact) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                child: Image.network(
                  contact.avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Text(
                          contact.name.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (contact.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
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
              contact.time,
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
          _selectContact(contact.id);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: message.isMe ? const Color(0xFFE53935) : Colors.white,
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    color: message.isMe ? Colors.white : Colors.black87,
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
                        color: message.isMe ? Colors.white70 : Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    if (message.isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.time,
    required this.isMe,
  });
}

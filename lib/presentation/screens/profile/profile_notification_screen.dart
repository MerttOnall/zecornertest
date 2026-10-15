import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:zecorner/presentation/screens/users/users_screen.dart';
import 'package:zecorner/presentation/screens/list/listings_screen.dart';
import 'package:zecorner/infrastructure/notification/notification_repository.dart';
import 'package:zecorner/models/notification/p_notification_model.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:intl/intl.dart';

class ProfileNotificationScreen extends StatefulWidget {
  const ProfileNotificationScreen({super.key});

  @override
  State<ProfileNotificationScreen> createState() => _ProfileNotificationScreenState();
}

class _ProfileNotificationScreenState extends State<ProfileNotificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;
  
  int _currentIndex = 4; // Profile tab index
  
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  List<PNotificationModel> _notifications = [];
  List<PNotificationModel> _filteredNotifications = [];
  
  // API related variables
  final NotificationRepository _notificationRepository = NotificationRepository();
  bool _isLoading = false;
  int _currentPage = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
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
    
    // Load notifications from API
    _loadNotifications();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _searchController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Bildirim ara...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _filterNotifications,
              )
            : const Text(
                'Bildirimler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Subtle Background
          _buildSubtleBackground(),
          
          // Main Content
          Column(
            children: [
              // Header Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Row(
                  children: [
                    const Text(
                      'Bildirimler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filteredNotifications.where((n) => !n.isRead).length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Notification List
              Expanded(
                child: _buildNotificationList(),
              ),
            ],
          ),
        ],
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

  Widget _buildNotificationList() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
        ),
      );
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return Center(
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
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_filteredNotifications.isEmpty && _isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aradığınız bildirim bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: const Color(0xFFE53935),
      child: ListView.builder(
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];
          final isRead = notification.isRead;
          final notificationType = _getNotificationTypeFromAction(notification.action);
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: isRead ? Colors.white : const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isRead ? Colors.grey.withOpacity(0.2) : const Color(0xFFE53935).withOpacity(0.2),
                width: isRead ? 0.5 : 1,
              ),
              boxShadow: isRead ? [] : [
                BoxShadow(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRead
                        ? Colors.grey.withOpacity(0.12)
                        : _getNotificationColor(notificationType).withOpacity(0.2),
                      border: isRead ? null : Border.all(
                        color: _getNotificationColor(notificationType).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isRead ? Icons.check_circle_outline : _getNotificationIcon(notificationType),
                      color: isRead ? Colors.grey : _getNotificationColor(notificationType),
                      size: 20,
                    ),
                  ),
                ],
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                  color: isRead ? Colors.black87 : Colors.black,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 10,
                        color: isRead ? Colors.grey : const Color(0xFFE53935),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatTimeAgo(notification.createdAt),
                        style: TextStyle(
                          color: isRead ? Colors.grey : const Color(0xFFE53935),
                          fontSize: 11,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'YENİ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    color: isRead ? Colors.grey : const Color(0xFFE53935),
                    size: 16,
                  ),
                ],
              ),
              onTap: () {
                _openNotificationDetail(notification);
              },
            ),
          );
        },
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
          ...List.generate(4, (index) {
            return AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Positioned(
                  left: (index * 100.0) % MediaQuery.of(context).size.width,
                  top: 100 + (index * 150.0) % 400 + _floatingAnimation.value,
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

  void _updateNotificationReadState(int notificationId, {required bool isRead}) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: isRead);
      }

      final filteredIndex =
          _filteredNotifications.indexWhere((n) => n.id == notificationId);
      if (filteredIndex != -1) {
        _filteredNotifications[filteredIndex] =
            _filteredNotifications[filteredIndex].copyWith(read: isRead);
      }
    });
  }

  void _openNotificationDetail(PNotificationModel notification) async {
    var updatedNotification = notification;
    if (!notification.isRead) {
      updatedNotification = notification.copyWith(read: true);
      _updateNotificationReadState(notification.id, isRead: true);
      await _notificationRepository.markAsRead(notification.id);
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          notification: updatedNotification,
          onMarkAsRead: (notificationId) {
            _updateNotificationReadState(notificationId, isRead: true);
            _notificationRepository.markAsRead(notificationId);
          },
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.userCreated:
        return const Color(0xFFE53935);
      case NotificationType.contactRequest:
        return Colors.blue;
      case NotificationType.approval:
        return Colors.orange;
      case NotificationType.approved:
        return Colors.green;
      case NotificationType.message:
        return const Color(0xFF2196F3);
      case NotificationType.favorite:
        return const Color(0xFFE91E63);
      case NotificationType.report:
        return const Color(0xFF9C27B0);
      case NotificationType.system:
        return const Color(0xFF607D8B);
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.userCreated:
        return Icons.person_add;
      case NotificationType.contactRequest:
        return Icons.contact_mail;
      case NotificationType.approval:
        return Icons.pending_actions;
      case NotificationType.approved:
        return Icons.check_circle;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.favorite:
        return Icons.favorite;
      case NotificationType.report:
        return Icons.analytics;
      case NotificationType.system:
        return Icons.system_update;
    }
  }

  void _filterNotifications(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotifications = _notifications;
      } else {
        _filteredNotifications = _notifications
            .where((notification) =>
                notification.title.toLowerCase().contains(query.toLowerCase()) ||
                notification.content.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredNotifications = _notifications;
      }
    });
  }

  // API Methods
  Future<void> _loadNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _notifications.clear();
        _filteredNotifications.clear();
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final result = await _notificationRepository.getNotifications(
      page: _currentPage,
      limit: 20,
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(failure);
        });
      },
      (response) {
        setState(() {
          _isLoading = false;

          if (isRefresh || _currentPage == 1) {
            _notifications = response.notifications;
          } else {
            _notifications.addAll(response.notifications);
          }

          _filteredNotifications = _notifications;
          _errorMessage = null;
        });
      },
    );
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications(isRefresh: true);
  }

  String _getErrorMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'İnternet bağlantınızı kontrol edin';
    } else if (failure is AuthFailure) {
      return 'Yetkilendirme hatası. Lütfen tekrar deneyin';
    } else if (failure is ServerFailure) {
      return 'Sunucu hatası: ${failure.message}';
    } else {
      return 'Bir hata oluştu: ${failure.message}';
    }
  }

  String _formatTimeAgo(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Az önce';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} dakika önce';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} saat önce';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else {
        return DateFormat('dd.MM.yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Bilinmeyen';
    }
  }

  NotificationType _getNotificationTypeFromAction(String action) {
    switch (action) {
      case 'SALE_FORM':
        return NotificationType.approval;
      case 'CONTACT_CREATED':
        return NotificationType.userCreated;
      case 'redirect_to_link':
        return NotificationType.contactRequest;
      default:
        return NotificationType.system;
    }
  }
}

class NotificationDetailScreen extends StatefulWidget {
  final PNotificationModel notification;
  final Function(int)? onMarkAsRead;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
    this.onMarkAsRead,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late PNotificationModel _notification;
  final NotificationRepository _notificationRepository = NotificationRepository();

  @override
  void initState() {
    super.initState();
    _notification = widget.notification;
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Bildirim',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        ),
      body: Column(
        children: [
          // Time Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTimeAgo(_notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          // Message Bubble
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Bubble
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon and Title Row
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getNotificationColor(_getNotificationTypeFromAction(_notification.action)).withOpacity(0.1),
                              ),
                              child: Icon(
                                _getNotificationIcon(_getNotificationTypeFromAction(_notification.action)),
                                color: _getNotificationColor(_getNotificationTypeFromAction(_notification.action)),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _notification.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Message Content
                        Text(
                          _notification.content,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Bottom Action
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        _handleNotificationAction(context, _notification);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Göster',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.userCreated:
        return const Color(0xFFE53935);
      case NotificationType.contactRequest:
        return Colors.blue;
      case NotificationType.approval:
        return Colors.orange;
      case NotificationType.approved:
        return Colors.green;
      case NotificationType.message:
        return const Color(0xFF2196F3);
      case NotificationType.favorite:
        return const Color(0xFFE91E63);
      case NotificationType.report:
        return const Color(0xFF9C27B0);
      case NotificationType.system:
        return const Color(0xFF607D8B);
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.userCreated:
        return Icons.person_add;
      case NotificationType.contactRequest:
        return Icons.contact_mail;
      case NotificationType.approval:
        return Icons.pending_actions;
      case NotificationType.approved:
        return Icons.check_circle;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.favorite:
        return Icons.favorite;
      case NotificationType.report:
        return Icons.analytics;
      case NotificationType.system:
        return Icons.system_update;
    }
  }

  String _formatTimeAgo(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Az önce';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} dakika önce';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} saat önce';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else {
        return DateFormat('dd.MM.yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Bilinmeyen';
    }
  }

  NotificationType _getNotificationTypeFromAction(String action) {
    switch (action) {
      case 'SALE_FORM':
        return NotificationType.approval;
      case 'CONTACT_CREATED':
        return NotificationType.userCreated;
      case 'redirect_to_link':
        return NotificationType.contactRequest;
      default:
        return NotificationType.system;
    }
  }

  void _handleNotificationAction(BuildContext context, PNotificationModel notification) async {
    if (!notification.isRead) {
      setState(() {
        _notification = notification.copyWith(read: true);
      });
      if (widget.onMarkAsRead != null) {
        widget.onMarkAsRead!(notification.id);
      } else {
        await _notificationRepository.markAsRead(notification.id);
      }
    }
    
    // Action'a göre yönlendirme
    switch (notification.action) {
      case 'SALE_FORM':
        // Satış formu sayfasına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ListingsScreen(),
          ),
        );
        break;
      case 'CONTACT_CREATED':
        // Kişiler sayfasına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UsersScreen(),
          ),
        );
        break;
      case 'redirect_to_link':
        // Link'e yönlendir (web view veya external link)
        if (notification.data.link != null) {
          // TODO: Web view veya external link açma
          Navigator.of(context).pop();
        }
        break;
      default:
        // Varsayılan olarak ana sayfaya yönlendir
        Navigator.of(context).pop();
        break;
    }
  }
}

enum NotificationType {
  userCreated,
  contactRequest,
  approval,
  approved,
  message,
  favorite,
  report,
  system,
}
import '../../core/utils/image_utils.dart';

class ChatListModel {
  final List<ChatItem> chatList;
  final int totalCount;
  final int totalPages;
  final int page;

  ChatListModel({
    required this.chatList,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory ChatListModel.fromJson(Map<String, dynamic> json) {
    return ChatListModel(
      chatList: (json['chatList'] as List)
          .map((item) => ChatItem.fromJson(item))
          .toList(),
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      page: json['page'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatList': chatList.map((item) => item.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}

class ChatItem {
  final String chatId;
  final String name;
  final int contactNo;
  final String typeDescription;
  final String type;
  final String? picture;
  final String lastMessage;
  final String lastMessageDate;
  final String unseenCount;

  ChatItem({
    required this.chatId,
    required this.name,
    required this.contactNo,
    required this.typeDescription,
    required this.type,
    this.picture,
    required this.lastMessage,
    required this.lastMessageDate,
    required this.unseenCount,
  });

  factory ChatItem.fromJson(Map<String, dynamic> json) {
    return ChatItem(
      chatId: json['chat_id'] ?? '',
      name: json['name'] ?? '',
      contactNo: json['contact_no'] ?? 0,
      typeDescription: json['type_description'] ?? '',
      type: json['type'] ?? '',
      picture: json['picture'],
      lastMessage: json['last_message'] ?? '',
      lastMessageDate: json['last_message_date'] ?? '',
      unseenCount: json['unseen_count'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'name': name,
      'contact_no': contactNo,
      'type_description': typeDescription,
      'type': type,
      'picture': picture,
      'last_message': lastMessage,
      'last_message_date': lastMessageDate,
      'unseen_count': unseenCount,
    };
  }

  // Tarih formatını düzenle (örn: "17 gün önce", "3 ay önce")
  String get formattedTime {
    try {
      final date = DateTime.parse(lastMessageDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Bugün';
      } else if (difference.inDays == 1) {
        return 'Dün';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks hafta önce';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ay önce';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years yıl önce';
      }
    } catch (e) {
      return 'Bilinmeyen';
    }
  }

  // Okunmamış mesaj sayısını int olarak döndür
  int get unreadCount {
    try {
      return int.parse(unseenCount);
    } catch (e) {
      return 0;
    }
  }

  // Profil resmi URL'sini oluştur (S3'ten)
  String get profileImageUrl {
    return ImageUtils.getProfileImageUrl(picture);
  }

  // İsim baş harflerini döndür (avatar için)
  String get initials {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }
}

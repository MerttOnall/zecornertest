import 'package:intl/intl.dart';

class ChatMessagesModel {
  final List<ChatMessage> messages;
  final int totalCount;
  final int totalPages;
  final int page;

  ChatMessagesModel({
    required this.messages,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory ChatMessagesModel.fromJson(Map<String, dynamic> json) {
    return ChatMessagesModel(
      messages: (json['messages'] as List)
          .map((i) => ChatMessage.fromJson(i))
          .toList(),
      totalCount: json['totalCount'],
      totalPages: json['totalPages'],
      page: json['page'],
    );
  }
}

class ChatMessage {
  final int id;
  final int contact;
  final String chat;
  final String messageDate;
  final String message;

  ChatMessage({
    required this.id,
    required this.contact,
    required this.chat,
    required this.messageDate,
    required this.message,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      contact: json['contact'],
      chat: json['chat'],
      messageDate: json['message_date'],
      message: json['message'],
    );
  }

  /// Mesajın gönderen kişi tarafından gönderilip gönderilmediğini kontrol et
  /// contact: 61 = mevcut kullanıcı (kırmızı bubble)
  /// contact: 72 = diğer kişi (gri bubble)
  bool get isFromCurrentUser {
    // Bu değer kullanıcının ID'sine göre dinamik olarak belirlenmeli
    // Şimdilik 61'i current user olarak kabul ediyoruz
    return contact == 61;
  }

  /// Mesaj tarihini formatla
  String get formattedTime {
    try {
      final DateTime messageDateTime = DateTime.parse(messageDate).toLocal();
      final DateTime now = DateTime.now().toLocal();
      final Duration difference = now.difference(messageDateTime);

      // Aynı gün ise sadece saat göster
      if (difference.inDays == 0) {
        return DateFormat('HH:mm').format(messageDateTime);
      }
      // 1 gün önce ise "Dün" göster
      else if (difference.inDays == 1) {
        return 'Dün ${DateFormat('HH:mm').format(messageDateTime)}';
      }
      // 1 hafta içinde ise gün adı göster
      else if (difference.inDays < 7) {
        return DateFormat('EEEE HH:mm', 'tr_TR').format(messageDateTime);
      }
      // Daha eski ise tarih göster
      else {
        return DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(messageDateTime);
      }
    } catch (e) {
      return 'Bilinmeyen';
    }
  }

  /// Mesaj tarihini sadece tarih olarak formatla (grup başlıkları için)
  String get formattedDate {
    try {
      final DateTime messageDateTime = DateTime.parse(messageDate).toLocal();
      final DateTime now = DateTime.now().toLocal();
      final Duration difference = now.difference(messageDateTime);

      if (difference.inDays == 0) {
        return 'Bugün';
      } else if (difference.inDays == 1) {
        return 'Dün';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE', 'tr_TR').format(messageDateTime);
      } else {
        return DateFormat('dd.MM.yyyy', 'tr_TR').format(messageDateTime);
      }
    } catch (e) {
      return 'Bilinmeyen';
    }
  }
}

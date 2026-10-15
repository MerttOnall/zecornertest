class PropertyModel {
  final String id;
  final String title;
  final String location;
  final String price;
  final String type;
  final String consultantName;
  final String consultantTitle;
  final String consultantEmail;
  final String consultantPhone;
  final List<String>? images;
  final String? propertyDetails;
  final String? value;
  final double? numberValue;
  
  // Update/Delete işlemleri için ek alanlar
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  final String? deleteReason;

  PropertyModel({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.type,
    required this.consultantName,
    required this.consultantTitle,
    required this.consultantEmail,
    required this.consultantPhone,
    this.images,
    this.propertyDetails,
    this.value,
    this.numberValue,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.deleteReason,
  });

  // Factory constructor to create PropertyModel from Map (useful for API data)
  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      price: map['price'] ?? '',
      type: map['type'] ?? '',
      consultantName: map['consultantName'] ?? '',
      consultantTitle: map['consultantTitle'] ?? '',
      consultantEmail: map['consultantEmail'] ?? '',
      consultantPhone: map['consultantPhone'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      propertyDetails: map['propertyDetails'],
      value: map['value'],
      numberValue: map['numberValue'] != null ? double.tryParse(map['numberValue'].toString()) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      createdBy: map['created_by'],
      updatedBy: map['updated_by'],
      isDeleted: map['is_deleted'] ?? false,
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
      deletedBy: map['deleted_by'],
      deleteReason: map['delete_reason'],
    );
  }

  // Factory constructor to create PropertyModel from JSON (for API compatibility)
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel.fromMap(json);
  }

  // Convert PropertyModel to Map (useful for storing data)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'price': price,
      'type': type,
      'consultantName': consultantName,
      'consultantTitle': consultantTitle,
      'consultantEmail': consultantEmail,
      'consultantPhone': consultantPhone,
      'images': images,
      'propertyDetails': propertyDetails,
      'value': value,
      'numberValue': numberValue,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted_by': deletedBy,
      'delete_reason': deleteReason,
    };
  }

  // Convert PropertyModel to JSON (for API compatibility)
  Map<String, dynamic> toJson() {
    return toMap();
  }
} 
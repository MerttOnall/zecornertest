import 'package:zecorner/models/list/property_model.dart';

/// Request model for updating a listing
class ListingUpdateRequest {
  final String title;
  final String description;
  final int price;
  final String currency;
  final String type;
  final bool internal;
  final List<PropertyUpdateModel> properties;

  ListingUpdateRequest({
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.type,
    required this.internal,
    required this.properties,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'type': type,
      'internal': internal,
      'properties': properties.map((prop) => prop.toJson()).toList(),
    };
  }
}

/// Property update model for listing properties
class PropertyUpdateModel {
  final String code;
  final String? id;
  final dynamic value;
  final double? numberValue;
  final String? stringValue;

  PropertyUpdateModel({
    required this.code,
    this.id,
    this.value,
    this.numberValue,
    this.stringValue,
  });

  factory PropertyUpdateModel.fromPropertyModel(PropertyModel property) {
    return PropertyUpdateModel(
      code: property.code,
      id: property.valueId,
      value: property.value,
      numberValue: property.numberValue?.toDouble(),
      stringValue: property.stringValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'id': id,
      'value': value,
      'number_value': numberValue,
      'string_value': stringValue,
    };
  }
}

/// Request model for updating listing state
class ListingStateUpdateRequest {
  final String state;

  ListingStateUpdateRequest({
    required this.state,
  });

  Map<String, dynamic> toJson() {
    return {
      'state': state,
    };
  }
}

/// Response model for listing update
class ListingUpdateResponse {
  final bool success;
  final String message;
  final String? listingId;

  ListingUpdateResponse({
    required this.success,
    required this.message,
    this.listingId,
  });

  factory ListingUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ListingUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      listingId: json['listing_id'],
    );
  }
}

/// Model for listing states
class ListingState {
  final String id;
  final String name;
  final String code;
  final String description;

  ListingState({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
  });

  factory ListingState.fromJson(Map<String, dynamic> json) {
    return ListingState(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
    };
  }
}

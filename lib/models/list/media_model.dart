class MediaModel {
  final String type;
  final String? thumbnail;
  final String? standart;
  final String? hd;
  final bool isCover;

  MediaModel({
    required this.type,
    this.thumbnail,
    this.standart,
    this.hd,
    required this.isCover,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      type: json['type'] ?? '',
      thumbnail: json['thumbnail'],
      standart: json['standart'],
      hd: json['hd'],
      isCover: json['is_cover'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'thumbnail': thumbnail,
      'standart': standart,
      'hd': hd,
      'is_cover': isCover,
    };
  }

  List<Object?> get props => [type, thumbnail, standart, hd, isCover];
}

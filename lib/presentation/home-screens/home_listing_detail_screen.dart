import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zecorner/models/list/listing_model.dart';
import 'package:zecorner/models/list/property_model.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:html/parser.dart' as html_parser;

class HomeListingDetailScreen extends StatefulWidget {
  final ListingModel? listing;

  const HomeListingDetailScreen({super.key, this.listing});

  @override
  State<HomeListingDetailScreen> createState() => _HomeListingDetailScreenState();
}

class _HomeListingDetailScreenState extends State<HomeListingDetailScreen> {
  late List<String> images;
  int selectedIndex = 0;
  bool isLiked = false;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    final listingData = widget.listing ?? 
        (ModalRoute.of(context)?.settings.arguments as ListingModel?);
    if (listingData != null) {
      images = _buildImageList(listingData);
      _pageController = PageController();
    } else {
      images = [];
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  List<String> _buildImageList(ListingModel listing) {
    List<String> imageList = [];
    
    if (listing.medias.isNotEmpty) {
      final coverMedia = listing.medias.firstWhere(
        (media) => media.isCover && media.type == 'image',
        orElse: () => listing.medias.first,
      );
      
      if (ImageUtils.isValidS3Id(coverMedia.standart)) {
        imageList.add(ImageUtils.getS3FileUrl(coverMedia.standart!));
      } else if (ImageUtils.isValidS3Id(coverMedia.hd)) {
        imageList.add(ImageUtils.getS3FileUrl(coverMedia.hd!));
      } else if (ImageUtils.isValidS3Id(coverMedia.thumbnail)) {
        imageList.add(ImageUtils.getS3FileUrl(coverMedia.thumbnail!));
      }
      
      for (var media in listing.medias) {
        if (media.type == 'image' && !media.isCover && ImageUtils.isValidS3Id(media.standart)) {
          imageList.add(ImageUtils.getS3FileUrl(media.standart!));
        }
      }
    }
    
    if (imageList.isEmpty && ImageUtils.isValidS3Id(listing.coverPicture)) {
      imageList.add(ImageUtils.getS3FileUrl(listing.coverPicture));
    }
    
    if (imageList.isEmpty && ImageUtils.isValidS3Id(listing.picture)) {
      imageList.add(ImageUtils.getS3FileUrl(listing.picture!));
    }
    
    if (imageList.isEmpty) {
      imageList.add("assets/logo/ilan.png");
    }
    
    return imageList;
  }

  String _formatOdaSayisi(String? odaSayisi) {
    if (odaSayisi == null || 
        odaSayisi.isEmpty || 
        odaSayisi == '-' || 
        odaSayisi == 'oda-sayisi' ||
        odaSayisi.toLowerCase().contains('undefined') ||
        odaSayisi.toLowerCase().contains('null')) {
      return '-';
    }
    
    if (odaSayisi.contains('oda-sayisi-')) {
      final number = odaSayisi.replaceAll('oda-sayisi-', '');
      
      if (number.isEmpty || number == '0' || number == '00') {
        return '-';
      }
      
      if (number.length > 2) {
        return '-';
      }
      
      if (number.length == 2 && RegExp(r'^\d{2}$').hasMatch(number)) {
        final oda = number[0];
        final salon = number[1];
        
        final odaNum = int.tryParse(oda) ?? 0;
        final salonNum = int.tryParse(salon) ?? 0;
        
        if (odaNum > 6 || salonNum > 5) {
          return '-';
        }
        
        return '$oda+$salon';
      }
      
      if (number.length == 1 && RegExp(r'^\d$').hasMatch(number)) {
        final num = int.tryParse(number) ?? 0;
        if (num == 0 || num > 5) {
          return '-';
        }
        return '$number+1';
      }
      
      return '-';
    }
    
    if (odaSayisi.toLowerCase() == 'oda-sayisi') {
      return '-';
    }
    
    if (odaSayisi.contains('+')) {
      return odaSayisi;
    }
    
    if (RegExp(r'^\d+$').hasMatch(odaSayisi)) {
      if (odaSayisi == '0') {
        return '-';
      }
      return '$odaSayisi+1';
    }
    
    return odaSayisi;
  }

  String _formatKat(String? kat) {
    if (kat == null || 
        kat.isEmpty || 
        kat == '-' || 
        kat == 'bulundugu-kat' ||
        kat.toLowerCase().contains('undefined') ||
        kat.toLowerCase().contains('null')) {
      return '-';
    }
    
    if (kat.contains('bulundugu-kat-')) {
      final number = kat.replaceAll('bulundugu-kat-', '');
      
      if (number.isEmpty || number == '0') {
        return 'Zemin';
      }
      
      if (RegExp(r'^\d+$').hasMatch(number)) {
        return number;
      }
      
      return number;
    }
    
    if (kat.toLowerCase() == 'bulundugu-kat') {
      return '-';
    }
    
    if (kat.toLowerCase().contains('kat')) {
      final katRegex = RegExp(r'kat\s*(\d+)', caseSensitive: false);
      final match = katRegex.firstMatch(kat);
      if (match != null) {
        return match.group(1) ?? kat;
      }
      final cleaned = kat.replaceAll(RegExp(r'kat\s*', caseSensitive: false), '').trim();
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
      return kat;
    }
    
    if (RegExp(r'^\d+$').hasMatch(kat)) {
      if (kat == '0') {
        return 'Zemin';
      }
      return kat;
    }
    
    switch (kat.toLowerCase()) {
      case 'zemin':
      case '0':
        return 'Zemin';
      case 'bodrum':
      case '-1':
        return 'Bodrum';
      case 'çatı':
      case 'cati':
        return 'Çatı';
      default:
        if (kat.length > 8) {
          return kat.substring(0, 8);
        }
        return kat;
    }
  }

  String _formatBinaYasi(String? binaYasi) {
    if (binaYasi == null || binaYasi.isEmpty || binaYasi == '-') {
      return '-';
    }
    
    String cleanValue = binaYasi;
    if (binaYasi.contains('bina-yasi-')) {
      cleanValue = binaYasi.replaceAll('bina-yasi-', '').trim();
    }
    
    if (cleanValue.isEmpty || cleanValue.toLowerCase() == 'bina-yasi') {
      return '-';
    }
    
    if (cleanValue == '0') {
      return 'Sıfır';
    }
    
    if (cleanValue.contains('-arasi') || cleanValue.contains('-arası')) {
      final range = cleanValue.replaceAll('-arasi', '').replaceAll('-arası', '').trim();
      if (range.contains('-')) {
        return '$range Arası';
      }
    }
    
    if (RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return cleanValue;
    }
    
    if (RegExp(r'^\d+$').hasMatch(binaYasi)) {
      return binaYasi;
    }
    
    return cleanValue.split('-').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatIsitma(String? isitma) {
    if (isitma == null || isitma.isEmpty || isitma == '-') {
      return '-';
    }
    
    String cleanValue = isitma;
    if (isitma.contains('isitma-')) {
      cleanValue = isitma.replaceAll('isitma-', '').trim();
    }
    
    if (cleanValue.isEmpty || cleanValue.toLowerCase() == 'isitma') {
      return '-';
    }
    
    final isitmaMap = {
      'merkez': 'Merkezi Isıtma',
      'merkezi': 'Merkezi Isıtma',
      'central': 'Merkezi Isıtma',
      'dogalgaz': 'Doğalgaz',
      'dogalgaz-sobasi': 'Doğalgaz Sobası',
      'dogalgaz-sobası': 'Doğalgaz Sobası',
      'natural-gas': 'Doğalgaz',
      'kombi': 'Kombi',
      'boiler': 'Kombi',
      'soba': 'Soba',
      'stove': 'Soba',
      'kat-kaloriferi': 'Kat Kaloriferi',
      'elektrik': 'Elektrik',
      'electric': 'Elektrik',
      'klima': 'Klima',
      'air-conditioning': 'Klima',
      'ac': 'Klima',
      'yok': 'Yok',
      'none': 'Yok',
      'belirtilmemis': 'Belirtilmemiş',
      'not-specified': 'Belirtilmemiş',
    };
    
    final lowerValue = cleanValue.toLowerCase();
    
    if (isitmaMap.containsKey(lowerValue)) {
      return isitmaMap[lowerValue]!;
    }
    
    for (var key in isitmaMap.keys) {
      if (lowerValue.contains(key) || key.contains(lowerValue)) {
        return isitmaMap[key]!;
      }
    }
    
    return cleanValue.split('-').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatPropertyValue(PropertyModel property) {
    if (property.numberValue != null && property.numberValue! > 0) {
      if (property.code == 'aidat-tl' || property.code == 'depozito-tl') {
        return _formatPrice(property.numberValue!);
      }
      return property.numberValue.toString();
    }
    
    if (property.value.isNotEmpty && property.value != '-') {
      final code = property.code.toLowerCase();
      final value = property.value;
      
      if (code.contains('oda')) {
        return _formatOdaSayisi(value);
      } else if (code.contains('kat')) {
        return _formatKat(value);
      } else if (code.contains('bina') && code.contains('yasi')) {
        return _formatBinaYasi(value);
      } else if (code.contains('isitma')) {
        return _formatIsitma(value);
      } else if (code.contains('banyo-sayisi')) {
        if (value.contains('banyo-sayisi-')) {
          return value.replaceAll('banyo-sayisi-', '');
        }
        return value;
      } else if (code.contains('balkon')) {
        if (value == 'balkon-var') return 'Var';
        if (value == 'balkon-yok') return 'Yok';
        return value.replaceAll('balkon-', '');
      } else if (code.contains('asansor')) {
        if (value == 'asansor-var') return 'Var';
        if (value == 'asansor-yok') return 'Yok';
        return value.replaceAll('asansor-', '');
      } else if (code.contains('esyali')) {
        if (value == 'esyali-hayir') return 'Hayır';
        if (value == 'esyali-evet') return 'Evet';
        return value.replaceAll('esyali-', '');
      } else if (code.contains('otopark')) {
        final clean = value.replaceAll('otopark-', '');
        if (clean.contains('-')) {
          return clean.split('-').map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');
        }
        return clean[0].toUpperCase() + clean.substring(1);
      } else if (code.contains('cephe')) {
        final cepheMap = {
          'bati': 'Batı',
          'dogu': 'Doğu',
          'guney': 'Güney',
          'kuzey': 'Kuzey',
        };
        return cepheMap[value.toLowerCase()] ?? value;
      } else if (code.contains('imar-durumu')) {
        if (value.contains('imar-durumu-')) {
          final clean = value.replaceAll('imar-durumu-', '');
          if (clean.contains('-')) {
            return clean.split('-').map((word) {
              if (word.isEmpty) return '';
              return word[0].toUpperCase() + word.substring(1);
            }).join(' ');
          }
          return clean[0].toUpperCase() + clean.substring(1);
        }
        if (value.contains('-')) {
          return value.split('-').map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');
        }
        return value[0].toUpperCase() + value.substring(1);
      } else if (code.contains('tapu-durumu')) {
        if (value.contains('tapu-durumu-')) {
          final clean = value.replaceAll('tapu-durumu-', '');
          if (clean.contains('-')) {
            return clean.split('-').map((word) {
              if (word.isEmpty) return '';
              return word[0].toUpperCase() + word.substring(1);
            }).join(' ');
          }
          return clean[0].toUpperCase() + clean.substring(1);
        }
        if (value.contains('-')) {
          return value.split('-').map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');
        }
        return value[0].toUpperCase() + value.substring(1);
      } else if (code.contains('kaks-emsal')) {
        if (value.contains('kaks-emsal-')) {
          final clean = value.replaceAll('kaks-emsal-', '');
          if (clean == 'belirtilmemis') return 'Belirtilmemiş';
          return clean.split('-').map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');
        }
        return value;
      } else if (code.contains('gabari')) {
        if (value.contains('gabari-')) {
          final clean = value.replaceAll('gabari-', '');
          if (clean == 'belirtilmemis') return 'Belirtilmemiş';
          return clean.split('-').map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');
        }
        return value;
      } else if (code.contains('altyapi')) {
        if (value == 'su') return 'Su';
        if (value == 'yolu-acilmis') return 'Yolu Açılmış';
        if (value.contains('-')) {
          return value.split('-').map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');
        }
        return value[0].toUpperCase() + value.substring(1);
      } else if (code.contains('konum')) {
        if (value.contains('konum-')) {
          return value.replaceAll('konum-', '').split('-').map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');
        }
        // "ana-yola-yakin" gibi değerleri formatla
        if (value.contains('-')) {
          return value.split('-').map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');
        }
        return value[0].toUpperCase() + value.substring(1);
      } else if (code.contains('manzara')) {
        if (value == 'gol') return 'Göl';
        if (value.contains('-')) {
          return value.split('-').map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');
        }
        return value[0].toUpperCase() + value.substring(1);
      } else if (code.contains('ada-no')) {
        if (property.numberValue != null) return property.numberValue.toString();
        if (property.stringValue != null && property.stringValue!.isNotEmpty) return property.stringValue!;
        return value;
      } else if (code.contains('parsel-no')) {
        if (property.numberValue != null) return property.numberValue.toString();
        if (property.stringValue != null && property.stringValue!.isNotEmpty) return property.stringValue!;
        return value;
      } else if (code.contains('pafta-no')) {
        if (property.stringValue != null && property.stringValue!.trim().isNotEmpty) {
          return property.stringValue!.trim();
        }
        if (property.numberValue != null) return property.numberValue.toString();
        return value.isEmpty || value == 'pafta-no' ? '-' : value;
      } else if (code.contains('tasinmaz-numarasi')) {
        if (property.stringValue != null && property.stringValue!.isNotEmpty) return property.stringValue!;
        if (property.numberValue != null) return property.numberValue.toString();
        return value.isEmpty || value == 'tasinmaz-numarasi' ? '-' : value;
      } else if (code == 'm2' || (code.contains('m2') && !code.contains('m2-brut') && !code.contains('m2-net'))) {
        if (property.numberValue != null) return property.numberValue.toString();
        return value.isEmpty || value == 'm2' ? '-' : value;
      }
      
      // Genel olarak kebab-case değerleri formatla
      if (value.contains('-') && !value.startsWith('-')) {
        return value.split('-').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
      }
      
      // Tek kelime ise baş harfini büyük yap
      if (value.isNotEmpty && value.length > 1) {
        return value[0].toUpperCase() + value.substring(1);
      }
      
      return value;
    }
    
    if (property.stringValue != null && property.stringValue!.isNotEmpty && property.stringValue != '-') {
      final code = property.code.toLowerCase();
      final value = property.stringValue!;
      
      if (code.contains('bina') && code.contains('yasi')) {
        return _formatBinaYasi(value);
      } else if (code.contains('isitma')) {
        return _formatIsitma(value);
      }
      
      return value;
    }
    
    return '-';
  }

  String _getFormattedLocation(ListingModel listing) {
    final parts = <String>[];
    if (listing.provinceName.isNotEmpty) parts.add(listing.provinceName);
    if (listing.districtName.isNotEmpty) parts.add(listing.districtName);
    if (listing.quarterName.isNotEmpty) parts.add(listing.quarterName);
    
    if (parts.isNotEmpty) {
      return parts.join(' / ');
    }
    
    return 'Konum Belirtilmemiş';
  }

  List<Widget> _buildTopPropertyWidgets(ListingModel listing) {
    List<Widget> widgets = [];
    Map<String, dynamic> foundProperties = {};
    
    if (listing.properties.isNotEmpty) {
      for (var entry in listing.properties.entries) {
        final key = entry.key.toLowerCase();
        final property = entry.value;
        
        if ((key.contains('m2-brut') || key == 'm2-brut') && !foundProperties.containsKey('m2-brut')) {
          foundProperties['m2-brut'] = _formatPropertyValue(property);
        } else if ((key.contains('m2-net') || key == 'm2-net') && !foundProperties.containsKey('m2-net')) {
          foundProperties['m2-net'] = _formatPropertyValue(property);
        } else if ((key == 'm2' || key.contains('m2')) && !foundProperties.containsKey('m2') && !key.contains('m2-brut') && !key.contains('m2-net')) {
          foundProperties['m2'] = _formatPropertyValue(property);
        } else if (key.contains('oda') && !foundProperties.containsKey('oda')) {
          foundProperties['oda'] = _formatOdaSayisi(_formatPropertyValue(property));
        } else if (key.contains('bulundugu-kat') && !foundProperties.containsKey('kat')) {
          foundProperties['kat'] = _formatKat(_formatPropertyValue(property));
        } else if (key.contains('bina') && key.contains('yasi') && !foundProperties.containsKey('bina')) {
          foundProperties['bina'] = _formatPropertyValue(property);
        } else if (key.contains('kat-sayisi') && !foundProperties.containsKey('kat-sayisi')) {
          foundProperties['kat-sayisi'] = _formatPropertyValue(property);
        } else if (key.contains('isitma') && !foundProperties.containsKey('isitma')) {
          foundProperties['isitma'] = _formatPropertyValue(property);
        }
      }
    }
    
    if (foundProperties.isEmpty && listing.propertiesShortList.isNotEmpty) {
      for (var property in listing.propertiesShortList) {
        final code = property.code.toLowerCase();
        
        if ((code.contains('m2-brut') || code == 'm2-brut') && !foundProperties.containsKey('m2-brut')) {
          foundProperties['m2-brut'] = _formatPropertyValue(property);
        } else if ((code.contains('m2-net') || code == 'm2-net') && !foundProperties.containsKey('m2-net')) {
          foundProperties['m2-net'] = _formatPropertyValue(property);
        } else if ((code == 'm2' || code.contains('m2')) && !foundProperties.containsKey('m2') && !code.contains('m2-brut') && !code.contains('m2-net')) {
          foundProperties['m2'] = _formatPropertyValue(property);
        } else if (code.contains('oda') && !foundProperties.containsKey('oda')) {
          foundProperties['oda'] = _formatOdaSayisi(_formatPropertyValue(property));
        } else if (code.contains('bulundugu-kat') && !foundProperties.containsKey('kat')) {
          foundProperties['kat'] = _formatKat(_formatPropertyValue(property));
        } else if (code.contains('bina') && code.contains('yasi') && !foundProperties.containsKey('bina')) {
          foundProperties['bina'] = _formatPropertyValue(property);
        } else if (code.contains('kat-sayisi') && !foundProperties.containsKey('kat-sayisi')) {
          foundProperties['kat-sayisi'] = _formatPropertyValue(property);
        } else if (code.contains('isitma') && !foundProperties.containsKey('isitma')) {
          foundProperties['isitma'] = _formatPropertyValue(property);
        }
      }
    }
    
    if (foundProperties['m2-brut'] != null) {
      widgets.add(_DetailRow(
        icon: Icons.square_foot,
        label: "m² (Brüt)",
        value: foundProperties['m2-brut']!.toString()
      ));
    }
    
    if (foundProperties['m2-net'] != null) {
      widgets.add(_DetailRow(
        icon: Icons.square_foot,
        label: "m² (Net)",
        value: foundProperties['m2-net']!.toString()
      ));
    }
    
    if (foundProperties['m2'] != null && foundProperties['m2-brut'] == null && foundProperties['m2-net'] == null) {
      widgets.add(_DetailRow(
        icon: Icons.square_foot,
        label: "m²",
        value: foundProperties['m2']!.toString()
      ));
    }
    
    widgets.add(_DetailRow(
      icon: Icons.meeting_room,
      label: "Oda Sayısı",
      value: foundProperties['oda']?.toString() ?? '-'
    ));
    
    if (foundProperties['bina'] != null) {
      widgets.add(_DetailRow(
        icon: Icons.apartment,
        label: "Bina Yaşı",
        value: foundProperties['bina']!.toString()
      ));
    }
    
    widgets.add(_DetailRow(
      icon: Icons.layers,
      label: "Bulunduğu Kat",
      value: foundProperties['kat']?.toString() ?? '-'
    ));
    
    if (foundProperties['kat-sayisi'] != null) {
      widgets.add(_DetailRow(
        icon: Icons.layers,
        label: "Kat Sayısı",
        value: foundProperties['kat-sayisi']!.toString()
      ));
    }
    
    if (foundProperties['isitma'] != null) {
      widgets.add(_DetailRow(
        icon: Icons.fireplace,
        label: "Isıtma",
        value: foundProperties['isitma']!.toString()
      ));
    }
    
    return widgets;
  }


  IconData _getIconForProperty(String key) {
    switch (key.toLowerCase()) {
      case 'm2-brut':
      case 'm2-net':
      case 'metrekare':
        return Icons.square_foot;
      case 'oda-sayisi':
      case 'oda':
        return Icons.meeting_room;
      case 'bulundugu-kat':
      case 'kat':
        return Icons.layers;
      case 'bina-yasi':
      case 'yas':
        return Icons.apartment;
      case 'isitma':
        return Icons.fireplace;
      case 'banyo':
      case 'banyo-sayisi':
        return Icons.bathtub;
      case 'balkon':
        return Icons.balcony;
      case 'otopark':
        return Icons.local_parking;
      case 'aidat':
        return Icons.payments;
      case 'cephe':
        return Icons.camera_front;
      case 'asansor':
        return Icons.elevator;
      case 'esyali':
        return Icons.chair;
      case 'imar-durumu':
        return Icons.assignment;
      case 'tapu-durumu':
        return Icons.description;
      case 'ada-no':
      case 'parsel-no':
      case 'pafta-no':
        return Icons.numbers;
      case 'altyapi':
        return Icons.construction;
      case 'konum':
        return Icons.location_on;
      case 'manzara':
        return Icons.landscape;
      case 'm2':
        return Icons.square_foot;
      default:
        return Icons.info;
    }
  }

  String _getDisplayNameForProperty(String key) {
    switch (key.toLowerCase()) {
      case 'm2-brut':
        return 'm² (Brüt)';
      case 'm2-net':
        return 'm² (Net)';
      case 'oda-sayisi':
        return 'Oda Sayısı';
      case 'bulundugu-kat':
        return 'Bulunduğu Kat';
      case 'bina-yasi':
        return 'Bina Yaşı';
      case 'isitma':
        return 'Isıtma';
      case 'banyo-sayisi':
        return 'Banyo Sayısı';
      case 'balkon':
        return 'Balkon';
      case 'otopark':
        return 'Otopark';
      case 'aidat':
      case 'aidat-tl':
        return 'Aidat';
      case 'cephe':
        return 'Cephe';
      case 'kat-sayisi':
        return 'Kat Sayısı';
      case 'asansor':
        return 'Asansör';
      case 'esyali':
        return 'Eşyalı';
      case 'imar-durumu':
        return 'İmar Durumu';
      case 'tapu-durumu':
        return 'Tapu Durumu';
      case 'kaks-emsal':
        return 'Kaks (Emsal)';
      case 'gabari':
        return 'Gabari';
      case 'ada-no':
        return 'Ada No';
      case 'parsel-no':
        return 'Parsel No';
      case 'pafta-no':
        return 'Pafta No';
      case 'tasinmaz-numarasi':
        return 'Taşınmaz Numarası';
      case 'altyapi':
        return 'Altyapı';
      case 'konum':
        return 'Konum';
      case 'manzara':
        return 'Manzara';
      case 'm2':
        return 'm²';
      default:
        return key.split('-').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
        ).join(' ');
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _parseHtml(String? html) {
    if (html == null || html.isEmpty) return '';
    final document = html_parser.parse(html);
    return document.body?.text ?? '';
  }

  List<Widget> _buildGenelOzellikler(ListingModel listing) {
    List<Widget> widgets = [];
    final genelCodes = [
      'imar-durumu', 'm2', 'm2-brut', 'm2-net', 'ada-no', 'parsel-no', 'pafta-no',
      'kaks-emsal', 'gabari', 'tapu-durumu', 'tasinmaz-numarasi', 'konum', 'manzara'
    ];
    
    if (listing.properties.isNotEmpty) {
      for (var entry in listing.properties.entries) {
        final code = entry.key.toLowerCase();
        if (genelCodes.any((genelCode) => code.contains(genelCode) || code == genelCode)) {
          widgets.add(_OzellikSatiri(
            icon: _getIconForProperty(entry.key),
            label: _getDisplayNameForProperty(entry.key),
            value: _formatPropertyValue(entry.value)
          ));
        }
      }
    } else if (listing.propertiesShortList.isNotEmpty) {
      for (var property in listing.propertiesShortList) {
        final code = property.code.toLowerCase();
        if (genelCodes.any((genelCode) => code.contains(genelCode) || code == genelCode)) {
          widgets.add(_OzellikSatiri(
            icon: _getIconForProperty(property.code),
            label: _getDisplayNameForProperty(property.code),
            value: _formatPropertyValue(property)
          ));
        }
      }
    }
    
    return widgets;
  }

  List<Widget> _buildAltyapi(ListingModel listing) {
    List<Widget> widgets = [];
    
    if (listing.properties.isNotEmpty) {
      for (var entry in listing.properties.entries) {
        final code = entry.key.toLowerCase();
        if (code.contains('altyapi') || code == 'altyapi') {
          widgets.add(_OzellikSatiri(
            icon: _getIconForProperty(entry.key),
            label: _getDisplayNameForProperty(entry.key),
            value: _formatPropertyValue(entry.value)
          ));
        }
      }
    } else if (listing.propertiesShortList.isNotEmpty) {
      for (var property in listing.propertiesShortList) {
        final code = property.code.toLowerCase();
        if (code.contains('altyapi') || code == 'altyapi') {
          widgets.add(_OzellikSatiri(
            icon: _getIconForProperty(property.code),
            label: _getDisplayNameForProperty(property.code),
            value: _formatPropertyValue(property)
          ));
        }
      }
    }
    
    return widgets;
  }


  void openGallery(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        PageController controller = PageController(initialPage: initialIndex);
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                PageView.builder(
                  controller: controller,
                  itemCount: images.length,
                  itemBuilder: (context, i) => Center(
                    child: InteractiveViewer(
                      child: _buildGalleryImage(images[i]),
                    ),
                  ),
                  onPageChanged: (i) {
                    setState(() {
                      selectedIndex = i;
                    });
                  },
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
          ),
        ],
      ),
          ),
        );
      },
    );
  }

  Widget _buildGalleryImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[800],
            child: const Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 60,
            ),
          );
        },
      );
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[800],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[800],
          child: const Icon(
            Icons.broken_image,
            color: Colors.white,
            size: 60,
          ),
        );
      },
    );
  }

  Widget _buildMainImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
              width: double.infinity,
        height: 280,
              fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 280,
            color: Colors.grey[300],
            child: const Icon(
              Icons.home_outlined,
              size: 60,
              color: Colors.white,
            ),
          );
        },
      );
    }
    
    return Image.network(
      imageUrl,
              width: double.infinity,
      height: 280,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: 280,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 280,
          color: Colors.grey[300],
          child: const Icon(
            Icons.home_outlined,
            size: 60,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildThumbnailImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 70,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 70,
            height: 60,
                        decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
                        ),
            child: const Icon(
              Icons.image,
                            color: Colors.white,
            ),
          );
        },
      );
    }
    
    return Image.network(
      imageUrl,
      width: 70,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 70,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 70,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.image,
            color: Colors.white,
          ),
        );
      },
    );
  }

  void _shareProperty(ListingModel listing) {
    final title = listing.title.isNotEmpty ? listing.title : 'İlan Detayı';
    final price = listing.price > 0 
      ? '${_formatPrice(listing.price)} ${listing.currency}'
      : 'Fiyat Görüşülür';
    final location = _getFormattedLocation(listing);
    final listingNo = listing.listingNo > 0 ? listing.listingNo.toString() : 'Belirtilmemiş';
    final type = listing.type.isNotEmpty ? listing.type : 'emlak';
    
    final String shareText = '''
🏠 $title
💰 ₺$price
📍 $location

Detaylar için bizimle iletişime geçin!
Portföy No: $listingNo

#emlak #$type
    ''';
    
    Share.share(
      shareText,
      subject: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingData = widget.listing ?? 
        (ModalRoute.of(context)?.settings.arguments as ListingModel?);

    if (listingData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFE53935)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "İlan Detayı",
                    style: TextStyle(
              color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Text('İlan bulunamadı'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE53935)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "İlan Detayı",
                    style: TextStyle(
            color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFFE53935)),
            onPressed: () => _shareProperty(listingData),
          ),
        ],
      ),
      body: _buildPropertyContent(listingData),
    );
  }

  Widget _buildPropertyContent(ListingModel listing) {
    return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          // Büyük görsel
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => openGallery(index),
                  child: Stack(
                    children: [
                      _buildMainImage(images[index]),
                      if (images.length > 1)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${selectedIndex + 1}/${images.length}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
                );
              },
            ),
          ),

          // İçerik
          Padding(
            padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Thumbnail galerisi
                if (images.length > 1) ...[
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () {
                          _pageController?.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() {
                            selectedIndex = i;
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedIndex == i
                                    ? const Color(0xFFE53935)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _buildThumbnailImage(images[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Başlık ve fiyat
                Text(
                  listing.title.isNotEmpty ? listing.title : 'İlan Başlığı Yok',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  listing.price > 0 
                    ? '₺${_formatPrice(listing.price)}'
                    : 'Fiyat Belirtilmemiş',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _getFormattedLocation(listing),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  listing.listingNo > 0 
                    ? "Portföy No: ${listing.listingNo}"
                    : "Portföy No: Belirtilmemiş",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // Badge ve butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
            Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        listing.type.isNotEmpty ? listing.type.toUpperCase() : 'BELİRTİLMEMİŞ',
                        style: const TextStyle(
              color: Colors.white,
                      fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          icon: isLiked ? Icons.favorite : Icons.favorite_border,
                          label: "Beğen",
                          isActive: isLiked,
                          onTap: () {
                            setState(() {
                              isLiked = !isLiked;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.share,
                          label: "Paylaş",
                          isActive: false,
                          onTap: () => _shareProperty(listing),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Üst property widget'ları
            Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _buildTopPropertyWidgets(listing),
            ),
          ),

          // Açıklama
          if ((listing.description != null && listing.description!.isNotEmpty) || 
              (listing.realEstateDescription != null && listing.realEstateDescription!.isNotEmpty)) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
              color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "İlan Açıklaması",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _parseHtml(listing.description ?? listing.realEstateDescription),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Genel Özellikler
          if (_buildGenelOzellikler(listing).isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
              color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Genel Özellikler",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildGenelOzellikler(listing),
                ],
              ),
            ),
          ],

          // AltYapı
          if (_buildAltyapi(listing).isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
              color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AltYapı",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildAltyapi(listing),
                ],
              ),
            ),
          ],


          // Danışman kartı
            Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
                    children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  listing.contactTitle.isNotEmpty ? listing.contactTitle : 'Danışman Bilgisi Yok',
                  style: const TextStyle(
                              fontWeight: FontWeight.bold,
                    fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                  listing.contactTypeDescription.isNotEmpty ? listing.contactTypeDescription : 'Emlak Danışmanı',
                            style: TextStyle(
                    color: Colors.grey[600],
                              fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _ContactButton(
                  icon: Icons.email,
                  text: listing.contactEmail.isNotEmpty ? listing.contactEmail : "info@zecorner.com"
                ),
                const SizedBox(height: 8),
                _ContactButton(
                  icon: Icons.phone,
                  text: listing.contactNo > 0 ? "+90 ${listing.contactNo}" : "+90 555 123 45 67"
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFC62828)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/home-danisman',
                          arguments: {
                            'consultantId': listing.contactTitle.toLowerCase().replaceAll(' ', '_'),
                            'consultantName': listing.contactTitle.isNotEmpty ? listing.contactTitle : 'Danışman',
                            'consultantTitle': listing.contactTypeDescription.isNotEmpty ? listing.contactTypeDescription : 'Emlak Danışmanı',
                            'consultantEmail': listing.contactEmail.isNotEmpty ? listing.contactEmail : 'info@zecorner.com',
                            'consultantPhone': listing.contactNo > 0 ? '+90 ${listing.contactNo}' : '+90 555 123 45 67',
                            'consultantContactNo': listing.contactNo,
                          }
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.person_outline,
              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Danışmanı Ziyaret Et",
                    style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                    color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
          ),

          // Harita
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: listing.lat != null && listing.lon != null
              ? Image.network(
                  'https://maps.googleapis.com/maps/api/staticmap?center=${listing.lat},${listing.lon}&zoom=15&size=600x300&markers=color:red%7Clabel:C%7C${listing.lat},${listing.lon}&key=YOUR_API_KEY',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.map, size: 48, color: Colors.grey[400]),
                  ),
                )
              : Center(
                  child: Icon(Icons.map, size: 48, color: Colors.grey[400]),
                ),
          ),

          // Danışmanın Diğer İlanları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                  'Danışmanın Diğer İlanları',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            padding: const EdgeInsets.symmetric(vertical: 40),
                                        decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Danışmana ait başka ilan bulunamadı',
                                          style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                                          ),
                                        ),
                                      ),
                                  ),
                                ],
                              ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactButton({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _OzellikSatiri extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _OzellikSatiri({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
            label,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE53935) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFFE53935) : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
      children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : const Color(0xFFE53935),
                  size: 18,
                ),
                const SizedBox(width: 6),
        Text(
                  label,
          style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFFE53935),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
          ),
        ),
      ],
            ),
          ),
        ),
      ),
    );
  }
} 

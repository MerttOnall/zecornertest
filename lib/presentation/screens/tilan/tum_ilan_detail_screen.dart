import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/list/listing_model.dart';
import '../../../models/list/property_model.dart';
import '../../../infrastructure/list/listing_repository.dart';
import '../../../core/utils/image_utils.dart';
import '../../../router/app_router.dart';
import '../../../presentation/widgets/map_widget.dart';

class TumIlanDetailScreen extends StatefulWidget {
  final String propertyId;
  final ListingModel? listingFromList; // Liste sayfasından gelen listing objesi

  const TumIlanDetailScreen({
    super.key,
    required this.propertyId,
    this.listingFromList,
  });

  @override
  State<TumIlanDetailScreen> createState() => _TumIlanDetailScreenState();
}

class _TumIlanDetailScreenState extends State<TumIlanDetailScreen> {
  final ListingRepository _repository = ListingRepository();

  ListingModel? listing;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  bool isLiked = false; // Beğen durumu için state

  late List<String> images;
  int selectedIndex = 0;

  /// Ana fotoğraf carousel ve thumbnail listesi için controller'lar
  late PageController _pageController;
  final ScrollController _thumbScrollController = ScrollController();

  /// Danışmanın diğer ilanları (mevcut ilan hariç)
  List<ListingModel> consultantOtherListings = [];
  bool isLoadingOtherListings = false;

  /// Bize Ulaşın formu
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  bool _kvkkAccepted = false;
  bool _campaignsAccepted = false;
  bool _bizeUlasinSent = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadPropertyData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbScrollController.dispose();
    _contactPhoneController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPropertyData() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = null;
      });

      print('🔄 İlan detayı yükleniyor: ID ${widget.propertyId}');
      
      final result = await _repository.getListingDetail(widget.propertyId);
      
      result.fold(
        (failure) {
          print('❌ İlan detay hatası: ${failure.message}');
          setState(() {
            hasError = true;
            errorMessage = failure.message;
            isLoading = false;
          });
        },
        (loadedListing) {
          print('✅ İlan detayı yüklendi: ${loadedListing.title}');
          print('📊 İlan ID: ${loadedListing.id}');
          print('📊 İlan No: ${loadedListing.listingNo}');
          print('📊 Fiyat: ${loadedListing.price} ${loadedListing.currency}');
          print('📊 Tip: ${loadedListing.type}');
          print('📊 Konum: ${loadedListing.districtName}, ${loadedListing.provinceName}');
          print('📊 Properties sayısı: ${loadedListing.properties.length}');
          
          // Properties'leri listele
          if (loadedListing.properties.isNotEmpty) {
            print('🏠 === PROPERTIES LİSTESİ (${loadedListing.properties.length} adet) ===');
            loadedListing.properties.forEach((key, value) {
              print('🏠 $key: value="${value.value}", numberValue=${value.numberValue}, stringValue="${value.stringValue}"');
            });
            print('🏠 === PROPERTIES SON ===');
          } else {
            print('⚠️ HİÇ PROPERTY YOK!');
          }
          
          // Properties Short List'i de kontrol et
          if (loadedListing.propertiesShortList.isNotEmpty) {
            print('📋 === PROPERTIES SHORT LIST (${loadedListing.propertiesShortList.length} adet) ===');
            for (var prop in loadedListing.propertiesShortList) {
              print('📋 ${prop.code}: value="${prop.value}", numberValue=${prop.numberValue}');
            }
            print('📋 === SHORT LIST SON ===');
          } else {
            print('⚠️ HİÇ SHORT LIST YOK!');
          }
          
          // Temel bilgileri de göster
          print('🔍 === TEMEL BİLGİLER ===');
          print('🔍 Title: "${loadedListing.title}"');
          print('🔍 Price: ${loadedListing.price}');
          print('🔍 Currency: "${loadedListing.currency}"');
          print('🔍 Type: "${loadedListing.type}"');
          print('🔍 Real Estate Type: "${loadedListing.realEstateType}"');
          print('🔍 Slug: "${loadedListing.slug}"');
          print('🔍 Contact Title: "${loadedListing.contactTitle}"');
          print('🔍 Contact Email: "${loadedListing.contactEmail}"');
          print('🔍 Contact No: ${loadedListing.contactNo}');
          print('🔍 Contact Type Desc: "${loadedListing.contactTypeDescription}"');
          print('🔍 Medias Count: ${loadedListing.medias.length}');
          
          // Medias'ları listele
          if (loadedListing.medias.isNotEmpty) {
            print('🖼️ === MEDIAS LİSTESİ ===');
            for (var media in loadedListing.medias) {
              print('🖼️ Type: ${media.type}, Cover: ${media.isCover}, Standard: ${media.standart}');
            }
            print('🖼️ === MEDIAS SON ===');
          }
          
          print('🔍 === TEMEL BİLGİLER SON ===');
          
          setState(() {
            listing = loadedListing;
            images = _buildImageList(loadedListing);
            isLoading = false;
          });
          // Danışmanın diğer ilanlarını arka planda çek
          _loadConsultantOtherListings(loadedListing);
        },
      );
    } catch (e) {
      print('💥 İlan detay beklenmeyen hatası: $e');
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<String> _buildImageList(ListingModel listing) {
    List<String> imageList = [];
    
    // Önce medias listesinden resimler al
    if (listing.medias.isNotEmpty) {
      print('🖼️ Medias bulundu: ${listing.medias.length} adet');
      
      // Önce cover resmi bul
      final coverMedia = listing.medias.firstWhere(
        (media) => media.isCover && media.type == 'image',
        orElse: () => listing.medias.first,
      );
      
      // Cover resmi ekle
      if (ImageUtils.isValidS3Id(coverMedia.standart)) {
        imageList.add(ImageUtils.getCoverImageUrl(coverMedia.standart!));
        print('🖼️ Cover resim eklendi: ${coverMedia.standart}');
      }
      
      // Diğer resimleri ekle
      for (var media in listing.medias) {
        if (media.type == 'image' && !media.isCover && ImageUtils.isValidS3Id(media.standart)) {
          imageList.add(ImageUtils.getCoverImageUrl(media.standart!));
          print('🖼️ Resim eklendi: ${media.standart}');
        }
      }
    }
    
    // Fallback: Cover picture var mı?
    if (imageList.isEmpty && ImageUtils.isValidS3Id(listing.coverPicture)) {
      imageList.add(ImageUtils.getCoverImageUrl(listing.coverPicture));
      print('🖼️ Fallback cover resim kullanıldı');
    }
    
    // Fallback: Picture var mı? (API'de bazen picture, bazen cover_picure kullanılıyor)
    final pictureId = listing.picture ?? listing.coverPicture;
    if (imageList.isEmpty && ImageUtils.isValidS3Id(pictureId)) {
      imageList.add(ImageUtils.getCoverImageUrl(pictureId));
      print('🖼️ Fallback picture kullanıldı');
    }
    
    // Eğer hiç resim yoksa placeholder ekle
    if (imageList.isEmpty) {
      imageList.add("assets/logo/ilan.png");
      print('🖼️ Placeholder resim kullanıldı');
    }
    
    print('🖼️ Toplam ${imageList.length} resim hazırlandı');
    return imageList;
  }

  /// Oda sayısını formatla (örn: "2+1", "3+1", "1+0")
  String _formatOdaSayisi(String? odaSayisi) {
    // Null, boş veya geçersiz değerler için "-" döndür
    if (odaSayisi == null || 
        odaSayisi.isEmpty || 
        odaSayisi == '-' || 
        odaSayisi == 'oda-sayisi' ||
        odaSayisi.toLowerCase().contains('undefined') ||
        odaSayisi.toLowerCase().contains('null')) {
      return '-';
    }
    
    // API'den "oda-sayisi-21" formatında geliyorsa parse et
    if (odaSayisi.contains('oda-sayisi-')) {
      final number = odaSayisi.replaceAll('oda-sayisi-', '');
      
      // Eğer number boş ise veya geçersizse
      if (number.isEmpty || number == '0' || number == '00') {
        return '-';
      }
      
      // Sadece 1-2 haneli sayıları kabul et, diğerleri geçersiz
      if (number.length > 2) {
        return '-';
      }
      
      // İki haneli sayıyı oda+salon formatına çevir
      if (number.length == 2 && RegExp(r'^\d{2}$').hasMatch(number)) {
        final oda = number[0];
        final salon = number[1];
        
        // Mantıksız değerler (örn: 9+9) kontrolü
        final odaNum = int.tryParse(oda) ?? 0;
        final salonNum = int.tryParse(salon) ?? 0;
        
        if (odaNum > 6 || salonNum > 5) {
          return '-';
        }
        
        return '$oda+$salon';
      }
      
      // Tek haneli sayı ise +1 ekle (sadece 1-5 arası)
      if (number.length == 1 && RegExp(r'^\d$').hasMatch(number)) {
        final num = int.tryParse(number) ?? 0;
        if (num == 0 || num > 5) {
          return '-';
        }
        return '$number+1';
      }
      
      return '-';
    }
    
    // Eğer sadece "oda-sayisi" yazıyorsa boş demektir
    if (odaSayisi.toLowerCase() == 'oda-sayisi') {
      return '-';
    }
    
    // Eğer zaten formatlanmışsa (+ içeriyorsa) olduğu gibi döndür
    if (odaSayisi.contains('+')) {
      return odaSayisi;
    }
    
    // Eğer sadece sayı ise "+1" ekle (örn: "2" -> "2+1")
    if (RegExp(r'^\d+$').hasMatch(odaSayisi)) {
      // 0 ise boş göster
      if (odaSayisi == '0') {
        return '-';
      }
      return '$odaSayisi+1';
    }
    
    return odaSayisi;
  }

  /// Kat bilgisini formatla (örn: "11. Kat", "Giriş Katı Kot 2")
  String _formatKat(String? kat) {
    // Null, boş veya geçersiz değerler için "-" döndür
    if (kat == null || 
        kat.isEmpty || 
        kat == '-' || 
        kat == 'bulundugu-kat' ||
        kat.toLowerCase().contains('undefined') ||
        kat.toLowerCase().contains('null')) {
      return '-';
    }
    
    final katLower = kat.toLowerCase().trim();
    
    // "giris-alti-kot-2" veya "giriş-altı-kot-2" formatını parse et
    if (katLower.contains('giris') || katLower.contains('giriş')) {
      // "giris-alti-kot-2" veya "giriş-altı-kot-2" formatı
      final parts = kat.split('-');
      String kotValue = '';
      
      // Kot değerini bul
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].toLowerCase() == 'kot' && i + 1 < parts.length) {
          kotValue = parts[i + 1];
          break;
        }
      }
      
      if (kotValue.isNotEmpty) {
        return 'Giriş Katı Kot $kotValue';
      }
      return 'Giriş Katı';
    }
    
    // "bulundugu-kat-11" formatını parse et
    if (katLower.contains('bulundugu-kat-')) {
      final number = kat.replaceAll(RegExp(r'bulundugu-kat-', caseSensitive: false), '');
      
      if (number.isEmpty || number == '0') {
        return 'Zemin Kat';
      }
      
      // Sadece sayı ise "11. Kat" formatında döndür
      if (RegExp(r'^\d+$').hasMatch(number)) {
        return '$number. Kat';
      }
      
      return number;
    }
    
    // Eğer sadece "bulundugu-kat" yazıyorsa boş demektir
    if (katLower == 'bulundugu-kat') {
      return '-';
    }
    
    // "kat 11" veya "kat11" formatını parse et
    final katMatch = RegExp(r'kat\s*(\d+)', caseSensitive: false).firstMatch(kat);
    if (katMatch != null) {
      final number = katMatch.group(1)!;
      return '$number. Kat';
    }
    
    // Sadece sayı ise "11. Kat" formatında döndür
    if (RegExp(r'^\d+$').hasMatch(kat)) {
      if (kat == '0') {
        return 'Zemin Kat';
      }
      return '$kat. Kat';
    }
    
    // Özel durumlar
    switch (katLower) {
      case 'zemin':
      case '0':
        return 'Zemin Kat';
      case 'bodrum':
      case '-1':
        return 'Bodrum Kat';
      case 'çatı':
      case 'cati':
        return 'Çatı Katı';
      default:
        // Eğer içinde "kat" kelimesi varsa ve sayı varsa formatla
        final hasKat = katLower.contains('kat');
        final numberMatch = RegExp(r'\d+').firstMatch(kat);
        if (hasKat && numberMatch != null) {
          return '${numberMatch.group(0)}. Kat';
        }
        // Diğer durumlarda olduğu gibi döndür
        return kat;
    }
  }


  /// Property için uygun ikon getir
  IconData _getIconForProperty(String key) {
    switch (key.toLowerCase()) {
      case 'm2-brut':
      case 'm2-net':
      case 'm2':
      case 'metrekare':
      case 'acik-alan-m2':
        return Icons.square_foot;
      case 'oda-sayisi':
      case 'oda':
      case 'room':
      case 'bolum-oda-sayisi':
        return Icons.meeting_room;
      case 'bulundugu-kat':
      case 'kat':
      case 'floor':
        return Icons.layers;
      case 'bina-yasi':
      case 'binanin-yasi':
      case 'yas':
      case 'age':
        return Icons.apartment;
      case 'isitma':
      case 'heating':
        return Icons.fireplace;
      case 'banyo':
      case 'bathroom':
        return Icons.bathtub;
      case 'balkon':
      case 'balcony':
        return Icons.balcony;
      case 'otopark':
      case 'parking':
        return Icons.local_parking;
      case 'aidat-tl':
      case 'aidat':
      case 'dues':
        return Icons.payments;
      case 'cephe':
      case 'facade':
        return Icons.camera_front;
      case 'tapu-durumu':
      case 'tapu':
      case 'deed':
        return Icons.assignment;
      case 'asansor':
        return Icons.elevator;
      case 'esyali':
        return Icons.weekend;
      case 'tasinmaz-numarasi':
        return Icons.tag;
      case 'imar-durumu':
        return Icons.landscape;
      case 'ada-no':
      case 'parsel-no':
      case 'pafta-no':
        return Icons.numbers;
      case 'kaks-emsal':
      case 'gabari':
        return Icons.straighten;
      case 'altyapi':
        return Icons.bolt;
      case 'konum':
        return Icons.location_on;
      case 'manzara':
        return Icons.nature;
      case 'detay-bilgisi':
        return Icons.checklist;
      case 'ic-ozellikler':
        return Icons.home_repair_service;
      case 'dis-ozellikler':
        return Icons.shield;
      case 'muhit':
        return Icons.store;
      case 'ulasim':
        return Icons.directions_bus;
      case 'konut-tipi':
        return Icons.home_work;
      case 'engelliye-ve-yasliya-uygun':
        return Icons.accessible;
      case 'zemin-etudu':
        return Icons.engineering;
      default:
        return Icons.info;
    }
  }

  /// Property için görünen isim getir
  String _getDisplayNameForProperty(String key) {
    switch (key.toLowerCase()) {
      case 'm2-brut':
        return 'm² (Brüt)';
      case 'm2-net':
        return 'm² (Net)';
      case 'm2':
        return 'm²';
      case 'oda-sayisi':
        return 'Oda Sayısı';
      case 'bolum-oda-sayisi':
        return 'Bölüm Oda Sayısı';
      case 'bulundugu-kat':
        return 'Bulunduğu Kat';
      case 'bina-yasi':
        return 'Bina Yaşı';
      case 'binanin-yasi':
        return 'Binanın Yaşı';
      case 'isitma':
        return 'Isıtma';
      case 'banyo-sayisi':
        return 'Banyo Sayısı';
      case 'balkon':
        return 'Balkon';
      case 'otopark':
        return 'Otopark';
      case 'aidat-tl':
      case 'aidat':
        return 'Aidat (TL)';
      case 'cephe':
        return 'Cephe';
      case 'tapu-durumu':
        return 'Tapu Durumu';
      case 'krediye-uygun':
        return 'Krediye Uygun';
      case 'esyali':
        return 'Eşyalı';
      case 'kat-sayisi':
        return 'Kat Sayısı';
      case 'asansor':
        return 'Asansör';
      case 'tasinmaz-numarasi':
        return 'Taşınmaz No';
      case 'imar-durumu':
        return 'İmar Durumu';
      case 'ada-no':
        return 'Ada No';
      case 'parsel-no':
        return 'Parsel No';
      case 'pafta-no':
        return 'Pafta No';
      case 'kaks-emsal':
        return 'KAKS / Emsal';
      case 'gabari':
        return 'Gabari';
      case 'altyapi':
        return 'Altyapı';
      case 'konum':
        return 'Konum';
      case 'manzara':
        return 'Manzara';
      case 'detay-bilgisi':
        return 'Detay';
      case 'ic-ozellikler':
        return 'İç Özellikler';
      case 'dis-ozellikler':
        return 'Dış Özellikler';
      case 'muhit':
        return 'Muhit';
      case 'ulasim':
        return 'Ulaşım';
      case 'konut-tipi':
        return 'Konut Tipi';
      case 'engelliye-ve-yasliya-uygun':
        return 'Erişilebilirlik';
      case 'zemin-etudu':
        return 'Zemin Etüdü';
      case 'acik-alan-m2':
        return 'Açık Alan (m²)';
      default:
        return key.split('-').map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
        .join(' ');
    }
  }

  /// Property widget'larını oluştur
  List<Widget> _buildPropertyWidgets() {
    if (listing == null) return [const Text('Veri yok')];
    
    List<Widget> widgets = [];
    
    // Önce normal properties'leri dene
    if (listing!.properties.isNotEmpty) {
      print('🔨 Normal properties kullanılıyor: ${listing!.properties.length} adet');
      widgets.addAll(
        listing!.properties.entries.map((entry) => 
          _OzellikSatiri(
            icon: _getIconForProperty(entry.key),
            label: _getDisplayNameForProperty(entry.key),
            value: _formatPropertyValue(entry.value)
          )
        ).toList()
      );
    } 
    // Eğer normal properties yoksa short list'i kullan
    else if (listing!.propertiesShortList.isNotEmpty) {
      print('🔨 Properties short list kullanılıyor: ${listing!.propertiesShortList.length} adet');
      widgets.addAll(
        listing!.propertiesShortList.map((property) => 
          _OzellikSatiri(
            icon: _getIconForProperty(property.code),
            label: _getDisplayNameForProperty(property.code),
            value: _formatPropertyValue(property)
          )
        ).toList()
      );
    } 
    // Hiçbiri yoksa temel bilgileri göster
    else {
      print('🔨 Property yok, temel bilgiler gösteriliyor');
      widgets.addAll([
        _OzellikSatiri(
          icon: Icons.business,
          label: "Emlak Tipi",
          value: listing!.realEstateType.isNotEmpty ? listing!.realEstateType : '-'
        ),
        _OzellikSatiri(
          icon: Icons.contact_phone,
          label: "İletişim",
          value: listing!.contactTitle.isNotEmpty ? listing!.contactTitle : '-'
        ),
        _OzellikSatiri(
          icon: Icons.calendar_today,
          label: "Oluşturma Tarihi",
          value: listing!.createdAt.isNotEmpty ? listing!.createdAt.substring(0, 10) : '-'
        ),
        _OzellikSatiri(
          icon: Icons.visibility,
          label: "Görüntülenme",
          value: listing!.viewCount > 0 ? '${listing!.viewCount} defa' : '-'
        ),
      ]);
    }
    
    return widgets;
  }

  /// Property değerini formatla
  String _formatPropertyValue(PropertyModel property) {
    final code = property.code.toLowerCase();

    // Taşınmaz numarası: string_value kullan (örn: "7351991")
    if (code == 'tasinmaz-numarasi') {
      if (property.stringValue != null && property.stringValue!.isNotEmpty) {
        return property.stringValue!;
      }
      if (property.value.isNotEmpty && property.value != 'tasinmaz-numarasi' && RegExp(r'^\d+$').hasMatch(property.value)) {
        return property.value;
      }
      return '-';
    }

    // m² alanları: number_value öncelikli (API'de value "m2-brut" olup number_value 160 gelebilir)
    if ((code.contains('m2') || code == 'acik-alan-m2') && property.numberValue != null) {
      return property.numberValue!.toString();
    }

    // Aidat (TL): numberValue 0 dahil göster (0 TL)
    if (code == 'aidat-tl' || code == 'aidat') {
      if (property.numberValue != null) {
        return property.numberValue == 0 ? '0 TL' : '${property.numberValue} TL';
      }
      if (property.value.isNotEmpty && property.value != 'aidat-tl') {
        final num = int.tryParse(property.value);
        if (num != null) return num == 0 ? '0 TL' : '$num TL';
      }
      return '-';
    }

    // numberValue varsa (0 hariç, aidat yukarıda) kullan
    if (property.numberValue != null && property.numberValue! > 0) {
      if (code.contains('banyo')) return property.numberValue!.toString();
      if (code.contains('kat') && !code.contains('sayisi')) {
        return _formatKat(property.numberValue!.toString());
      }
      if (code == 'bulundugu-kat') return _formatKat(property.numberValue!.toString());
      return property.numberValue!.toString();
    }

    // value ile özel formatlamalar
    if (property.value.isNotEmpty && property.value != '-') {
      final value = property.value;
      if (code.contains('oda')) return _formatOdaSayisi(value);
      if (code.contains('kat') && !code.contains('sayisi')) return _formatKat(value);
      if (code.contains('kat') && code.contains('sayisi')) return _formatKatSayisi(value);
      if (code.contains('bina') && code.contains('yasi')) return _formatBinaYasi(value);
      if (code == 'binanin-yasi') return _formatBinaYasi(value);
      if (code.contains('isitma')) return _formatIsitma(value);
      if (code.contains('banyo')) return _formatBanyoSayisi(value);
      if (code == 'balkon') return _formatBalkon(value);
      if (code == 'asansor') return _formatAsansor(value);
      if (code == 'otopark') return _formatOtopark(value);
      if (code == 'esyali') return _formatEsyali(value);
      if (code == 'cephe') return _formatCephe(value);
      if (code == 'tapu-durumu') return _formatTapuDurumu(value);
      if (code == 'imar-durumu') return _formatImarDurumu(value);
      if (code == 'krediye-uygun') return _formatKrediyeUygun(value);
      return _formatGenericValue(value, code);
    }

    if (property.stringValue != null && property.stringValue!.isNotEmpty && property.stringValue != '-') {
      final value = property.stringValue!;
      if (code.contains('bina')) return _formatBinaYasi(value);
      if (code.contains('isitma')) return _formatIsitma(value);
      if (code.contains('banyo')) return _formatBanyoSayisi(value);
      if (code.contains('kat') && code.contains('sayisi')) return _formatKatSayisi(value);
      return _formatGenericValue(value, code);
    }

    return '-';
  }

  String _formatBalkon(String v) {
    final lower = v.toLowerCase();
    if (lower.contains('var')) return 'Var';
    if (lower.contains('yok')) return 'Yok';
    return _formatGenericValue(v, 'balkon');
  }

  String _formatAsansor(String v) {
    final lower = v.toLowerCase();
    if (lower.contains('var')) return 'Var';
    if (lower.contains('yok')) return 'Yok';
    return _formatGenericValue(v, 'asansor');
  }

  String _formatOtopark(String v) {
    final lower = v.toLowerCase().replaceAll('otopark-', '');
    if (lower == 'acik-otopark') return 'Açık Otopark';
    if (lower.contains('kapali') || lower == 'kapali-otopark') return 'Kapalı Otopark';
    if (lower.contains('acik')) return 'Açık Otopark';
    return v.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
  }

  String _formatEsyali(String v) {
    final lower = v.toLowerCase();
    if (lower.contains('evet')) return 'Evet';
    if (lower.contains('hayir') || lower.contains('hayır')) return 'Hayır';
    return _formatGenericValue(v, 'esyali');
  }

  String _formatCephe(String v) {
    final map = {'guney': 'Güney', 'güney': 'Güney', 'bati': 'Batı', 'batı': 'Batı', 'kuzey': 'Kuzey', 'dogu': 'Doğu', 'doğu': 'Doğu'};
    return map[v.toLowerCase()] ?? v.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
  }

  String _formatTapuDurumu(String v) {
    final normalized = v.replaceAll(RegExp(r'tapu\s*durumu\s*[-]?\s*', caseSensitive: false), '').trim();
    final lower = normalized.toLowerCase();
    if (lower.contains('mustakil') || lower.contains('müstakil')) return 'Müstakil Tapulu';
    if (lower.contains('hisseli')) return 'Hisseli Tapu';
    if (lower.contains('kat-irtti') || lower.contains('kat irtifakı')) return 'Kat İrtifakı';
    if (lower.contains('kat-mulkiyetli') || lower.contains('kat mülkiyetli') || lower.contains('mulkiyetli')) return 'Kat Mülkiyetli';
    if (normalized.isEmpty) return v.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
    return normalized.split(RegExp(r'[\s-]+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatKrediyeUygun(String v) {
    final lower = v.toLowerCase();
    if (lower.contains('evet')) return 'Evet';
    if (lower.contains('hayir') || lower.contains('hayır')) return 'Hayır';
    return _formatGenericValue(v, 'krediye-uygun');
  }

  String _formatImarDurumu(String v) {
    final lower = v.toLowerCase().replaceAll('imar-durumu-', '');
    if (lower == 'tarla') return 'Tarla';
    if (lower == 'villa') return 'Villa';
    if (lower == 'konut') return 'Konut';
    return v.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
  }
  
  /// Genel değer formatlama: "key-value" formatından okunabilir değer üret
  String _formatGenericValue(String value, String code) {
    if (value.contains('-')) {
      final parts = value.split('-');
      if (parts.isNotEmpty) {
        final lastPart = parts.last.toLowerCase();
        if (RegExp(r'^\d+$').hasMatch(lastPart)) return lastPart;
        // Okunabilir evet/hayır
        if (lastPart == 'evet') return 'Evet';
        if (lastPart == 'hayir' || lastPart == 'hayır') return 'Hayır';
        if (lastPart == 'var') return 'Var';
        if (lastPart == 'yok') return 'Yok';
      }
    }
    if (RegExp(r'^\d+$').hasMatch(value)) return value;
    // Kebab-case'i "Title Case"e çevir (örn: kat-mulkiyetli -> Kat Mülkiyetli)
    return value.split('-').map((w) {
      if (w.isEmpty) return w;
      final lower = w.toLowerCase();
      if (lower == 've') return 've';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
  
  /// Banyo sayısını formatla (örn: "banyo-sayisi-2" -> "2")
  String _formatBanyoSayisi(String? banyoSayisi) {
    if (banyoSayisi == null || banyoSayisi.isEmpty || banyoSayisi == '-') {
      return '-';
    }
    
    // "banyo-sayisi-2" formatından sadece sayıyı al
    if (banyoSayisi.contains('banyo-sayisi-')) {
      final number = banyoSayisi.replaceAll('banyo-sayisi-', '').trim();
      if (RegExp(r'^\d+$').hasMatch(number)) {
        return number;
      }
    }
    
    // Eğer sadece sayı ise direkt döndür
    if (RegExp(r'^\d+$').hasMatch(banyoSayisi)) {
      return banyoSayisi;
    }
    
    return banyoSayisi;
  }
  
  /// Kat sayısını formatla (örn: "kat-sayisi-3" -> "3")
  String _formatKatSayisi(String? katSayisi) {
    if (katSayisi == null || katSayisi.isEmpty || katSayisi == '-') {
      return '-';
    }
    
    // "kat-sayisi-3" veya "-sayisi-3" formatından sadece sayıyı al
    if (katSayisi.contains('sayisi-')) {
      final parts = katSayisi.split('sayisi-');
      if (parts.length > 1) {
        final number = parts.last.trim();
        if (RegExp(r'^\d+$').hasMatch(number)) {
          return number;
        }
      }
    }
    
    // Eğer sadece sayı ise direkt döndür
    if (RegExp(r'^\d+$').hasMatch(katSayisi)) {
      return katSayisi;
    }
    
    return katSayisi;
  }

  /// Bina yaşını formatla (örn: "bina-yasi-4" -> "4", "bina-yasi-5-10-arasi" -> "5-10 Arası")
  String _formatBinaYasi(String? binaYasi) {
    if (binaYasi == null || binaYasi.isEmpty || binaYasi == '-') {
      return '-';
    }
    
    // "bina-yasi-" prefix'ini kaldır
    String cleanValue = binaYasi;
    if (binaYasi.contains('bina-yasi-')) {
      cleanValue = binaYasi.replaceAll('bina-yasi-', '').trim();
    }
    
    // Eğer "bina-yasi" yazıyorsa boş demektir
    if (cleanValue.isEmpty || cleanValue.toLowerCase() == 'bina-yasi') {
      return '-';
    }
    
    // "0" ise "Sıfır" veya "Yeni" göster
    if (cleanValue == '0') {
      return 'Sıfır';
    }
    
    // Aralık formatı: "5-10-arasi" -> "5-10 Arası"
    if (cleanValue.contains('-arasi') || cleanValue.contains('-arası')) {
      final range = cleanValue.replaceAll('-arasi', '').replaceAll('-arası', '').trim();
      if (range.contains('-')) {
        return '$range Arası';
      }
    }
    
    // Tek sayı: "4" -> "4"
    if (RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return cleanValue;
    }
    
    // Eğer sadece sayı ise direkt döndür
    if (RegExp(r'^\d+$').hasMatch(binaYasi)) {
      return binaYasi;
    }
    
    // Diğer durumlar için kebab-case'i Title Case'e çevir
    return cleanValue.split('-').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Isıtma bilgisini formatla (örn: "isitma-merkez" -> "Merkezi Isıtma")
  String _formatIsitma(String? isitma) {
    if (isitma == null || isitma.isEmpty || isitma == '-') {
      return '-';
    }
    
    // "isitma-" prefix'ini kaldır
    String cleanValue = isitma;
    if (isitma.contains('isitma-')) {
      cleanValue = isitma.replaceAll('isitma-', '').trim();
    }
    
    // Eğer "isitma" yazıyorsa boş demektir
    if (cleanValue.isEmpty || cleanValue.toLowerCase() == 'isitma') {
      return '-';
    }
    
    // Türkçe açıklamalara çevir
    final isitmaMap = {
      'merkez': 'Merkezi Isıtma',
      'merkezi': 'Merkezi Isıtma',
      'merkezi-pay-olcer': 'Merkezi Pay Ölçer',
      'merkezi-pay-ölçer': 'Merkezi Pay Ölçer',
      'central': 'Merkezi Isıtma',
      'dogalgaz': 'Doğalgaz',
      'dogalgaz-sobasi': 'Doğalgaz Sobası',
      'dogalgaz-sobası': 'Doğalgaz Sobası',
      'dogalgaz-kombi': 'Doğalgaz Kombi',
      'isitma-dogalgaz-kombi': 'Doğalgaz Kombi',
      'kombi-dogalgaz': 'Kombi Doğalgaz',
      'isitma-kombi-dogalgaz': 'Kombi Doğalgaz',
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
    
    // Önce tam eşleşme kontrolü
    if (isitmaMap.containsKey(lowerValue)) {
      return isitmaMap[lowerValue]!;
    }
    
    // Kısmi eşleşme kontrolü (örn: "dogalgaz-sobasi" -> "Doğalgaz Sobası")
    for (var key in isitmaMap.keys) {
      if (lowerValue.contains(key) || key.contains(lowerValue)) {
        return isitmaMap[key]!;
      }
    }
    
    // Eğer map'te yoksa, kebab-case'i Title Case'e çevir
    return cleanValue.split('-').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Konum bilgisini formatla (detay sayfası formatı: "Mahalle, İlçe, İl")
  String _getFormattedLocation() {
    // Önce API'den gelen verileri kontrol et
    if (listing != null) {
      print('📍 API Konum Debug: quarterName="${listing!.quarterName}", districtName="${listing!.districtName}", provinceName="${listing!.provinceName}"');
      
      // Detay sayfası formatı: "Mahalle, İlçe, İl" veya "İlçe, İl" (mahalle yoksa)
      final parts = <String>[];
      
      if (listing!.quarterName.isNotEmpty) {
        parts.add(listing!.quarterName);
      }
      if (listing!.districtName.isNotEmpty) {
        parts.add(listing!.districtName);
      }
      if (listing!.provinceName.isNotEmpty) {
        parts.add(listing!.provinceName);
      }
      
      if (parts.isNotEmpty) {
        final location = parts.join(', ');
        print('✅ API\'den konum formatlandı: "$location"');
        return location;
      }
    }
    
    // Eğer API'den gelen verilerde konum bilgileri boşsa, liste sayfasından gelen bilgileri kullan
    if (widget.listingFromList != null) {
      print('📍 Liste sayfasından konum kullanılıyor: quarterName="${widget.listingFromList!.quarterName}", districtName="${widget.listingFromList!.districtName}", provinceName="${widget.listingFromList!.provinceName}"');
      
      final parts = <String>[];
      
      if (widget.listingFromList!.quarterName.isNotEmpty) {
        parts.add(widget.listingFromList!.quarterName);
      }
      if (widget.listingFromList!.districtName.isNotEmpty) {
        parts.add(widget.listingFromList!.districtName);
      }
      if (widget.listingFromList!.provinceName.isNotEmpty) {
        parts.add(widget.listingFromList!.provinceName);
      }
      
      if (parts.isNotEmpty) {
        final location = parts.join(', ');
        print('✅ Liste sayfasından konum formatlandı: "$location"');
        return location;
      }
    }
    
    print('⚠️ Hiç konum bilgisi yok - Konum Belirtilmemiş döndürülüyor');
    return 'Konum Belirtilmemiş';
  }

  /// Üst kısım için property widget'ları (kısa özet)
  List<Widget> _buildTopPropertyWidgets() {
    if (listing == null) return [const Text('Veri yok')];
    
    List<Widget> widgets = [];
    Map<String, dynamic> foundProperties = {};
    
    // Önce normal properties'lerden bul
    if (listing!.properties.isNotEmpty) {
      for (var entry in listing!.properties.entries) {
        final key = entry.key.toLowerCase();
        final property = entry.value;
        
        if (key.contains('m2') && !foundProperties.containsKey('m2')) {
          foundProperties['m2'] = _formatPropertyValue(property);
        } else if (key.contains('oda') && !foundProperties.containsKey('oda')) {
          foundProperties['oda'] = _formatOdaSayisi(_formatPropertyValue(property));
        } else if (key.contains('kat') && !foundProperties.containsKey('kat')) {
          foundProperties['kat'] = _formatKat(_formatPropertyValue(property));
        } else if (key.contains('bina') && !foundProperties.containsKey('bina')) {
          foundProperties['bina'] = _formatPropertyValue(property);
        } else if (key.contains('isitma') && !foundProperties.containsKey('isitma')) {
          foundProperties['isitma'] = _formatPropertyValue(property);
        }
      }
    }
    
    // Eğer bulunamazsa short list'ten bul
    if (foundProperties.isEmpty && listing!.propertiesShortList.isNotEmpty) {
      for (var property in listing!.propertiesShortList) {
        final code = property.code.toLowerCase();
        
        if (code.contains('m2') && !foundProperties.containsKey('m2')) {
          foundProperties['m2'] = _formatPropertyValue(property);
        } else if (code.contains('oda') && !foundProperties.containsKey('oda')) {
          foundProperties['oda'] = _formatOdaSayisi(_formatPropertyValue(property));
        } else if (code.contains('kat') && !foundProperties.containsKey('kat')) {
          foundProperties['kat'] = _formatKat(_formatPropertyValue(property));
        }
      }
    }
    
    // Widget'ları oluştur
    widgets.add(_DetailRow(
      icon: Icons.square_foot,
      label: "m²",
      value: foundProperties['m2'] ?? '-'
    ));
    
    widgets.add(_DetailRow(
      icon: Icons.meeting_room,
      label: "Oda Sayısı",
      value: foundProperties['oda'] ?? '-'
    ));
    
    widgets.add(_DetailRow(
      icon: Icons.layers,
      label: "Kat",
      value: foundProperties['kat'] ?? '-'
    ));
    
    if (foundProperties['bina'] != null) {
      widgets.add(_DetailRow(
        icon: Icons.apartment,
        label: "Bina Yaşı",
        value: foundProperties['bina']!
      ));
    }
    
    if (foundProperties['isitma'] != null) {
      widgets.add(_DetailRow(
        icon: Icons.fireplace,
        label: "Isıtma",
        value: foundProperties['isitma']!
      ));
    }
    
    // En az 3 widget olsun
    while (widgets.length < 3) {
      widgets.add(_DetailRow(
        icon: Icons.info,
        label: "Bilgi Yok",
        value: '-'
      ));
    }
    
    return widgets;
  }

  /// Gallery için resim widget'i
  Widget _buildGalleryImage(String imageUrl) {
    // Asset resimse
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
    
    // Network resimse
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

  /// Ana sayfa için resim widget'i
  Widget _buildMainImage(String imageUrl) {
    // Asset resimse
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 220,
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
    
    // Network resimse
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: 220,
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
          height: 220,
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

  /// Thumbnail için resim widget'i
  Widget _buildThumbnailImage(String imageUrl) {
    // Asset resimse
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
    
    // Network resimse
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
                  child: Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Haritada aç (Google Maps) - lat/lon varsa koordinat, yoksa adres sorgusu
  Future<void> _openInMaps() async {
    if (listing == null) return;
    String url;
    if (listing!.lat != null && listing!.lon != null) {
      url = 'https://www.google.com/maps?q=${listing!.lat},${listing!.lon}';
    } else {
      final query = Uri.encodeComponent(_getFormattedLocation());
      url = 'https://www.google.com/maps/search/?api=1&query=$query';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Bize Ulaşın formu - danışman kartının altında
  Widget _buildBizeUlasinForm() {
    if (_bizeUlasinSent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green[400], size: 56),
            const SizedBox(height: 16),
            Text(
              'Talebiniz Alındı',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'En kısa sürede size dönüş yapılacaktır.',
              style: TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bize Ulaşın!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contactPhoneController,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            decoration: InputDecoration(
              hintText: '5xx xxx xx xx',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              counterText: '',
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactNameController,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Ad Soyad',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZçÇğĞıİöÖşŞüÜ\s]')),
              LengthLimitingTextInputFormatter(80),
            ],
          ),
          const SizedBox(height: 14),
          Theme(
            data: Theme.of(context).copyWith(
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.red[600]!;
                  return Colors.transparent;
                }),
                checkColor: WidgetStateProperty.all(Colors.white),
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                splashRadius: 0,
              ),
            ),
            child: CheckboxListTile(
              value: _kvkkAccepted,
              onChanged: (v) => setState(() => _kvkkAccepted = v ?? false),
              title: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'KVKK Aydınlatma Metni',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white70,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushNamed(context, AppRouter.homeProfileKvkk);
                        },
                    ),
                    const TextSpan(text: "'ni okudum ve onaylıyorum."),
                  ],
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.red[600]!;
                  return Colors.transparent;
                }),
                checkColor: WidgetStateProperty.all(Colors.white),
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                splashRadius: 0,
              ),
            ),
            child: CheckboxListTile(
              value: _campaignsAccepted,
              onChanged: (v) => setState(() => _campaignsAccepted = v ?? false),
              title: Text(
                'Kampanyalardan haberdar olmak istiyorum.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onBizeUlasinSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Gönder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _onBizeUlasinSubmit() {
    FocusScope.of(context).unfocus();
    final phone = _contactPhoneController.text.replaceAll(RegExp(r'\D'), '');
    final name = _contactNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ad soyad giriniz.')),
      );
      return;
    }
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir telefon numarası giriniz (10 haneli).')),
      );
      return;
    }
    if (!_kvkkAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("KVKK Aydınlatma Metni'ni onaylamanız gerekiyor.")),
      );
      return;
    }
    _contactPhoneController.clear();
    _contactNameController.clear();
    setState(() {
      _kvkkAccepted = false;
      _campaignsAccepted = false;
      _bizeUlasinSent = true;
    });
  }

  /// Danışmanın diğer ilanları bölümü UI
  Widget _buildConsultantOtherListings() {
    if (isLoadingOtherListings) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red[700]!),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Diğer ilanlar yükleniyor...',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    if (consultantOtherListings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Danışmana ait başka ilan bulunamadı',
            style: TextStyle(color: Colors.grey[700], fontSize: 15),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: consultantOtherListings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final other = consultantOtherListings[index];
        final coverId = other.coverPicture.isNotEmpty
            ? other.coverPicture
            : (other.picture != null && other.picture!.isNotEmpty ? other.picture! : null);
        final imageUrl = (coverId != null && ImageUtils.isValidS3Id(coverId))
            ? ImageUtils.getCoverImageUrl(coverId)
            : null;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TumIlanDetailScreen(
                    propertyId: other.id,
                    listingFromList: other,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: 90,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _otherListingPlaceholder(),
                          )
                        : _otherListingPlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          other.title.isNotEmpty ? other.title : 'İlan',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          other.price > 0
                              ? '${other.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} ${other.currency}'
                              : 'Fiyat belirtilmemiş',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.red[700],
                          ),
                        ),
                        if (other.districtName.isNotEmpty || other.provinceName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              [other.quarterName, other.districtName, other.provinceName]
                                  .where((s) => s.isNotEmpty)
                                  .join(', '),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _otherListingPlaceholder() {
    return Container(
      width: 90,
      height: 70,
      color: Colors.grey[300],
      child: Icon(Icons.home_outlined, color: Colors.grey[500], size: 32),
    );
  }

  /// Danışman profil fotoğrafı yoksa gösterilen yuvarlak avatar (fotoğraf olmadığı anlaşılsın)
  Widget _danismanAvatarPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, size: 36, color: Colors.grey[600]),
    );
  }

  /// Thumbnail listesini seçili indekse kaydırır (ana görsel değişince seçili küçük resim görünür olsun)
  void _scrollThumbToIndex(int index) {
    if (!_thumbScrollController.hasClients) return;
    const double itemWidth = 70;
    const double separator = 8;
    final double offset = index * (itemWidth + separator);
    final double maxOffset = _thumbScrollController.position.maxScrollExtent;
    final double targetOffset = offset.clamp(0.0, maxOffset);
    _thumbScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Danışmanın diğer ilanlarını çek (contact_no ile aynı danışmana ait, mevcut ilan hariç)
  Future<void> _loadConsultantOtherListings(ListingModel currentListing) async {
    if (currentListing.contactNo <= 0) return;
    if (!mounted) return;
    setState(() => isLoadingOtherListings = true);
    final List<ListingModel> other = [];
    const int perPage = 20;
    const int maxPages = 4; // En fazla 4 sayfa = 80 ilan taranır
    bool stop = false;
    for (int page = 1; page <= maxPages && !stop; page++) {
      final result = await _repository.getListings(page: page, limit: perPage);
      result.fold(
        (_) => stop = true,
        (response) {
          for (var l in response.listings) {
            if (l.id != currentListing.id && l.contactNo == currentListing.contactNo) {
              other.add(l);
              if (other.length >= 10) {
                stop = true;
                return;
              }
            }
          }
        },
      );
    }
    if (!mounted) return;
    setState(() {
      consultantOtherListings = other;
      isLoadingOtherListings = false;
    });
  }

  // Paylaş fonksiyonu
  void _shareProperty() {
    if (listing != null) {
      final title = listing!.title.isNotEmpty ? listing!.title : 'İlan Detayı';
      final price = listing!.price > 0 
        ? '${listing!.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} ${listing!.currency}'
        : 'Fiyat Görüşülür';
      final location = _getFormattedLocation();
      final listingNo = listing!.listingNo > 0 ? listing!.listingNo.toString() : 'Belirtilmemiş';
      final type = listing!.type.isNotEmpty ? listing!.type : 'emlak';
      final realEstateType = listing!.realEstateType.isNotEmpty ? listing!.realEstateType : 'property';
      
      final String shareText = '''
🏠 $title
💰 $price
📍 $location

Detaylar için bizimle iletişime geçin!
İlan No: $listingNo

#emlak #$type #$realEstateType
      ''';
      
      Share.share(
        shareText,
        subject: title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("İlan Detayı",
            style:
                TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.red[700]),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'İlan yükleniyor...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : hasError
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
                        'Hata Oluştu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage ?? 'Bilinmeyen hata',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPropertyData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _buildPropertyContent(),
    );
  }

  Widget _buildPropertyContent() {
    if (listing == null) return const SizedBox();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Büyük görsel - Tam genişlik (kaydırılabilir carousel)
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => selectedIndex = index);
                // Thumbnail listesini seçili resme kaydır
                _scrollThumbToIndex(index);
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => openGallery(index),
                  child: _buildMainImage(images[index]),
                );
              },
            ),
          ),
          // Diğer içerik padding ile
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                // Küçük görseller galerisi (tıklanınca ana görsel değişir)
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    controller: _thumbScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final isSelected = selectedIndex == i;
                      return GestureDetector(
                        onTap: () {
                          if (selectedIndex == i) return;
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() => selectedIndex = i);
                          _scrollThumbToIndex(i);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.red : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _buildThumbnailImage(images[i]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 18),
                // Başlık ve fiyat
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing!.title.isNotEmpty ? listing!.title : 'İlan Başlığı Yok',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      listing!.price > 0 
                        ? '${listing!.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} ${listing!.currency}'
                        : 'Fiyat Belirtilmemiş',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.red[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _getFormattedLocation(),
                  style: TextStyle(color: Colors.grey[700], fontSize: 15)
                ),
                const SizedBox(height: 2),
                Text(
                  listing!.listingNo > 0 
                    ? "İlan No: ${listing!.listingNo}"
                    : "İlan No: Belirtilmemiş",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)
                ),
                SizedBox(height: 14),
                // Satılık etiketi ve öne çıkan bilgiler
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(
                        listing!.type.isNotEmpty ? listing!.type.toUpperCase() : 'BELİRTİLMEMİŞ',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                      backgroundColor: Colors.red[600],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Beğen Butonu
                        Container(
                          decoration: BoxDecoration(
                            color: isLiked ? Colors.red[600] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLiked ? Colors.red[600]! : Colors.grey[200]!, 
                              width: 1
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
                              onTap: () {
                                // Beğen butonuna basınca giriş yap sayfasına yönlendir
                                Navigator.pushNamed(context, AppRouter.login);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: isLiked ? Colors.white : Colors.red[600],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Beğen",
                                      style: TextStyle(
                                        color: isLiked ? Colors.white : Colors.red[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Paylaş Butonu
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!, width: 1),
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
                              onTap: _shareProperty,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.share,
                                      color: Colors.red[600],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Paylaş",
                                      style: TextStyle(
                                        color: Colors.red[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          // Bilgi tablosu - Tam genişlik
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              children: _buildTopPropertyWidgets(),
            ),
          ),
          // Devam eden içerik padding ile
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 18),
              ],
            ),
          ),
          // Genel Özellikler kutusu - Tam genişlik
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Genel Özellikler",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                        fontSize: 16)),
                SizedBox(height: 10),
                // API'den gelen property'leri dinamik olarak göster
                ..._buildPropertyWidgets(),
              ],
            ),
          ),
          SizedBox(height: 30),
          // Danışman kartı kutusu - Tam genişlik
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                ClipOval(
                  child: (listing!.contactPicture != null &&
                          listing!.contactPicture!.isNotEmpty &&
                          ImageUtils.isValidS3Id(listing!.contactPicture))
                      ? Image.network(
                          ImageUtils.getProfileImageUrl(listing!.contactPicture),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _danismanAvatarPlaceholder(),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return _danismanAvatarPlaceholder();
                          },
                        )
                      : _danismanAvatarPlaceholder(),
                ),
                SizedBox(height: 8),
                Text(
                  listing!.contactTitle.isNotEmpty ? listing!.contactTitle.trim() : 'Danışman Bilgisi Yok',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  textAlign: TextAlign.center,
                ),
                Text(
                  listing!.contactTypeDescription.isNotEmpty ? listing!.contactTypeDescription : 'Emlak Danışmanı',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                _ContactButton(
                  icon: Icons.email,
                  text: listing!.contactEmail.isNotEmpty ? listing!.contactEmail.trim() : 'İletişim için danışman sayfasına gidin',
                ),
                const SizedBox(height: 6),
                _ContactButton(
                  icon: Icons.phone,
                  text: (listing!.contactTel != null && listing!.contactTel!.trim().isNotEmpty)
                      ? listing!.contactTel!.trim()
                      : 'Danışman sayfasından ulaşın',
                ),
                SizedBox(height: 16),
                // Danışmanı Ziyaret Et Butonu
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.red[600]!, Colors.red[700]!],
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
                'consultantId': listing!.contactSlug.isNotEmpty ? listing!.contactSlug : listing!.contactTitle.toLowerCase().replaceAll(' ', '-'),
                'consultantName': listing!.contactTitle.isNotEmpty ? listing!.contactTitle : 'Danışman',
                'consultantTitle': listing!.contactTypeDescription.isNotEmpty ? listing!.contactTypeDescription : 'Emlak Danışmanı',
                'consultantEmail': listing!.contactEmail.isNotEmpty ? listing!.contactEmail : 'info@zecorner.com',
                'consultantPhone': listing!.contactTel != null && listing!.contactTel!.isNotEmpty ? listing!.contactTel! : '+90 555 123 45 67',
                'consultantPicture': listing!.contactPicture,
                'consultantContactNo': listing!.contactNo,
                'consultantOffice': listing!.connectedContactTitle.isNotEmpty ? listing!.connectedContactTitle : null,
                'consultantAbout': null,
              }
            );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Danışmanı Ziyaret Et",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                // Bize Ulaşın formu
                SizedBox(height: 24),
                _buildBizeUlasinForm(),
              ],
            ),
          ),
          SizedBox(height: 30),
          // Harita kutusu - Gömülü harita, konum bilgisi ve haritada aç
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Konum',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Gömülü harita (koordinat varsa)
                if (listing!.lat != null && listing!.lon != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: MapDisplayWidget(
                        position: LatLng(listing!.lat!, listing!.lon!),
                        address: _getFormattedLocation(),
                        onTap: _openInMaps,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  _getFormattedLocation(),
                  style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openInMaps,
                    icon: const Icon(Icons.map_outlined, size: 20),
                    label: const Text('Haritada Aç'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Danışmanın Diğer İlanları başlık ve liste
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30),
                Text(
                  'Danışmanın Diğer İlanları',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          // Danışmanın Diğer İlanları kartları
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _buildConsultantOtherListings(),
          ),
          SizedBox(height: 35)
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.red[700], size: 22),
          SizedBox(width: 10),
          Expanded(
              child:
                  Text(label, style: TextStyle(fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactButton({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.red[700], size: 20),
          SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

class _OzellikSatiri extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _OzellikSatiri(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.red[700], size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15))),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
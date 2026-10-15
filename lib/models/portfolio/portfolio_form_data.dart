import 'dart:io';

class PortfolioFormData {
  // Basic Info
  String? categoryId;
  String? listingType; // kiralik, satilik, etc.
  String? portfolioType;
  String? title;
  String? description;

  // Location
  String? provinceId;
  String? districtId;
  String? neighborhoodId;
  double? latitude;
  double? longitude;

  // Images
  List<File> images = [];

  // Properties - Numeric
  String? m2Brut;
  String? m2Net;
  String? acikAlanM2;
  String? kapaliAlanM2;
  String? araziM2;
  String? salonSayisi;
  String? binaAdedi;
  String? masaSayisi;
  String? derslikSayisi;
  String? pompaSayisi;
  String? aracKapasitesi;
  String? kisiKapasitesi;
  String? aidatTl;
  String? tasinmazNumarasi;

  // Properties - Select
  String? odaSayisi;
  String? binaYasi;
  String? bulunduguKat;
  String? katSayisi;
  String? isitma;
  String? yapiTipi;
  String? banyoSayisi;
  String? balkon;
  String? asansor;
  String? asansorSayisi;
  String? otopark;
  String? esyali;
  String? yapininDurumu;
  String? zeminEtudu;
  String? alkolRuhsati;
  String? ruhsatDurumu;
  String? binaTipi;
  String? turu;
  String? kiralamaSuresi;
  String? sekreter;
  String? kiracili;
  String? krediyeUygunluk;
  String? tapuDurumu;
  String? tipi;
  String? gayrimenkulSahibi;

  // Properties - Checkbox Groups (Konut)
  List<String> cephe = [];
  List<String> icOzellikler = [];
  List<String> disOzellikler = [];
  List<String> disCepheOzellikleri = [];
  List<String> muhit = [];
  List<String> ulasim = [];
  List<String> manzara = [];
  List<String> konutTipi = [];
  List<String> konutOzellikleri = [];
  List<String> cevreOzellikleri = [];
  List<String> icDekorasyon = [];
  List<String> engelliyeVeYasliyaUygun = [];
  
  // Properties - Checkbox Groups (Ticari)
  List<String> kullanimAmaci = [];
  List<String> genelOzellikler = [];
  List<String> yakinlik = [];
  List<String> altYapi = [];
  List<String> detayBilgisi = [];
  List<String> madenTipi = [];
  List<String> ozellikler = [];
  List<String> ekHizmet = [];
  List<String> binaOzellikleri = [];
  List<String> altyapi = [];
  List<String> ofisOzellikleri = [];
  List<String> hizmetler = [];

  PortfolioFormData();

  // Convert to API format
  Map<String, dynamic> toApiFormat() {
    Map<String, dynamic> properties = {};

    // Add numeric properties
    if (m2Brut != null) properties['m2-brut'] = m2Brut;
    if (m2Net != null) properties['m2-net'] = m2Net;
    if (acikAlanM2 != null) properties['acik-alan-m2'] = acikAlanM2;
    if (kapaliAlanM2 != null) properties['kapali-alan-m2'] = kapaliAlanM2;
    if (araziM2 != null) properties['arazi-m2'] = araziM2;
    if (salonSayisi != null) properties['salon-sayisi'] = salonSayisi;
    if (binaAdedi != null) properties['bina-adedi'] = binaAdedi;
    if (masaSayisi != null) properties['masa-sayisi'] = masaSayisi;
    if (derslikSayisi != null) properties['derslik-sayisi'] = derslikSayisi;
    if (pompaSayisi != null) properties['pompa-sayisi'] = pompaSayisi;
    if (aracKapasitesi != null) properties['arac-kapasitesi'] = aracKapasitesi;
    if (kisiKapasitesi != null) properties['kisi-kapasitesi'] = kisiKapasitesi;
    if (aidatTl != null) properties['aidat-tl'] = aidatTl;
    if (tasinmazNumarasi != null) properties['tasinmaz-numarasi'] = tasinmazNumarasi;

    // Add select properties
    if (odaSayisi != null) properties['oda-sayisi'] = odaSayisi;
    if (binaYasi != null) properties['bina-yasi'] = binaYasi;
    if (bulunduguKat != null) properties['bulundugu-kat'] = bulunduguKat;
    if (katSayisi != null) properties['kat-sayisi'] = katSayisi;
    if (isitma != null) properties['isitma'] = isitma;
    if (yapiTipi != null) properties['yapi-tipi'] = yapiTipi;
    if (banyoSayisi != null) properties['banyo-sayisi'] = banyoSayisi;
    if (balkon != null) properties['balkon'] = balkon;
    if (asansor != null) properties['asansor'] = asansor;
    if (asansorSayisi != null) properties['asansor-sayisi'] = asansorSayisi;
    if (otopark != null) properties['otopark'] = otopark;
    if (esyali != null) properties['esyali'] = esyali;
    if (yapininDurumu != null) properties['yapinin-durumu'] = yapininDurumu;
    if (zeminEtudu != null) properties['zemin-etudu'] = zeminEtudu;
    if (alkolRuhsati != null) properties['alkol-ruhsati'] = alkolRuhsati;
    if (ruhsatDurumu != null) properties['ruhsat-durumu'] = ruhsatDurumu;
    if (binaTipi != null) properties['bina-tipi'] = binaTipi;
    if (turu != null) properties['turu'] = turu;
    if (kiralamaSuresi != null) properties['kiralama-suresi'] = kiralamaSuresi;
    if (sekreter != null) properties['sekreter'] = sekreter;
    if (kiracili != null) properties['kiracili'] = kiracili;
    if (krediyeUygunluk != null) properties['krediye-uygunluk'] = krediyeUygunluk;
    if (tapuDurumu != null) properties['tapu-durumu'] = tapuDurumu;
    if (tipi != null) properties['tipi'] = tipi;
    if (gayrimenkulSahibi != null) {
      properties['gayrimenkul-sahibi'] = gayrimenkulSahibi;
    }

    // Add checkbox arrays (Konut)
    if (cephe.isNotEmpty) properties['cephe'] = cephe;
    if (icOzellikler.isNotEmpty) properties['ic-ozellikler'] = icOzellikler;
    if (disOzellikler.isNotEmpty) properties['dis-ozellikler'] = disOzellikler;
    if (disCepheOzellikleri.isNotEmpty) properties['dis-cephe-ozellikleri'] = disCepheOzellikleri;
    if (muhit.isNotEmpty) properties['muhit'] = muhit;
    if (ulasim.isNotEmpty) properties['ulasim'] = ulasim;
    if (manzara.isNotEmpty) properties['manzara'] = manzara;
    if (konutTipi.isNotEmpty) properties['konut-tipi'] = konutTipi;
    if (konutOzellikleri.isNotEmpty) properties['konut-ozellikleri'] = konutOzellikleri;
    if (cevreOzellikleri.isNotEmpty) properties['cevre-ozellikleri'] = cevreOzellikleri;
    if (icDekorasyon.isNotEmpty) properties['ic-dekorasyon'] = icDekorasyon;
    if (engelliyeVeYasliyaUygun.isNotEmpty) {
      properties['engelliye-ve-yasliya-uygun'] = engelliyeVeYasliyaUygun;
    }
    
    // Add checkbox arrays (Ticari)
    if (kullanimAmaci.isNotEmpty) properties['kullanim-amaci'] = kullanimAmaci;
    if (genelOzellikler.isNotEmpty) properties['genel-ozellikler'] = genelOzellikler;
    if (yakinlik.isNotEmpty) properties['yakinlik'] = yakinlik;
    if (altYapi.isNotEmpty) properties['alt-yapi'] = altYapi;
    if (detayBilgisi.isNotEmpty) properties['detay-bilgisi'] = detayBilgisi;
    if (madenTipi.isNotEmpty) properties['maden-tipi'] = madenTipi;
    if (ozellikler.isNotEmpty) properties['ozellikler'] = ozellikler;
    if (ekHizmet.isNotEmpty) properties['ek-hizmet'] = ekHizmet;
    if (binaOzellikleri.isNotEmpty) properties['bina-ozellikleri'] = binaOzellikleri;
    if (altyapi.isNotEmpty) properties['altyapi'] = altyapi;
    if (ofisOzellikleri.isNotEmpty) properties['ofis-ozellikleri'] = ofisOzellikleri;
    if (hizmetler.isNotEmpty) properties['hizmetler'] = hizmetler;

    return properties;
  }

  // Validation
  bool validate() {
    // Check required fields
    if (categoryId == null || categoryId!.isEmpty) return false;
    if (title == null || title!.isEmpty) return false;
    if (description == null || description!.isEmpty) return false;
    if (images.isEmpty) return false;

    // Check property-specific required fields
    if (m2Brut == null || m2Brut!.isEmpty) return false;
    if (m2Net == null || m2Net!.isEmpty) return false;

    // Validate m2-brut > m2-net
    try {
      final brut = double.parse(m2Brut!);
      final net = double.parse(m2Net!);
      if (brut <= net) return false;
    } catch (e) {
      return false;
    }

    return true;
  }

  List<String> getValidationErrors() {
    List<String> errors = [];

    if (categoryId == null || categoryId!.isEmpty) {
      errors.add('Portföy tipi seçilmelidir');
    }
    if (title == null || title!.isEmpty) {
      errors.add('Başlık girilmelidir');
    }
    if (description == null || description!.isEmpty) {
      errors.add('Açıklama girilmelidir');
    }
    if (images.isEmpty) {
      errors.add('En az 1 fotoğraf eklenmelidir');
    }
    if (m2Brut == null || m2Brut!.isEmpty) {
      errors.add('m² (Brüt) girilmelidir');
    }
    if (m2Net == null || m2Net!.isEmpty) {
      errors.add('m² (Net) girilmelidir');
    }

    // Validate m2-brut > m2-net
    if (m2Brut != null && m2Net != null) {
      try {
        final brut = double.parse(m2Brut!);
        final net = double.parse(m2Net!);
        if (brut <= net) {
          errors.add('m² (Brüt) değeri m² (Net) değerinden büyük olmalıdır');
        }
      } catch (e) {
        errors.add('m² değerleri geçerli sayılar olmalıdır');
      }
    }

    return errors;
  }
}


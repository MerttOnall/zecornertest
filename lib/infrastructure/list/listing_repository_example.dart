// Bu dosya listing repository'nin nasıl kullanılacağını gösterir
// Test amaçlı - gerçek uygulamada widget'lardan kullanın

import 'listing_repository.dart';

class ListingRepositoryExample {
  final ListingRepository _repository = ListingRepository();

  /// Temel kullanım örneği
  Future<void> basicExample() async {
    print('🚀 Temel ilan çekme örneği başlatılıyor...');
    
    final result = await _repository.getListings(page: 1, limit: 5);
    
    result.fold(
      (failure) {
        print('❌ Hata oluştu: ${failure.message}');
        if (failure.statusCode != null) {
          print('📊 Status Code: ${failure.statusCode}');
        }
      },
      (response) {
        print('✅ İlanlar başarıyla çekildi!');
        print('📊 Toplam ilan: ${response.totalCount}');
        print('📄 Toplam sayfa: ${response.totalPages}');
        print('📋 Mevcut sayfa: ${response.page}');
        print('🏠 Bu sayfadaki ilan sayısı: ${response.listings.length}');
        
        print('\n--- İLAN LİSTESİ ---');
        for (int i = 0; i < response.listings.length; i++) {
          final listing = response.listings[i];
          print('${i + 1}. ${listing.title}');
          print('   💰 ${listing.price} ${listing.currency}');
          print('   📍 ${listing.provinceName} / ${listing.districtName}');
          print('   🏷️ ${listing.type.toUpperCase()}');
          
          // Bazı özellikleri göster
          final m2Brut = listing.properties['m2-brut']?.numberValue;
          final odaSayisi = listing.properties['oda-sayisi']?.value;
          if (m2Brut != null) print('   📐 $m2Brut m² (brüt)');
          if (odaSayisi != null) print('   🚪 $odaSayisi');
          print('');
        }
      },
    );
  }

  /// Arama ve filtreleme örneği
  Future<void> searchExample() async {
    print('🔍 Arama ve filtreleme örneği başlatılıyor...');
    
    // Filters kullanarak arama yap
    final filters = {
      'search': 'daire',
      'listing_type': 'satilik',
      'price_min': 1000000,
      'price_max': 5000000,
    };
    
    final result = await _repository.getListings(
      page: 1,
      limit: 3,
      filters: filters,
    );
    
    result.fold(
      (failure) {
        print('❌ Arama hatası: ${failure.message}');
      },
      (response) {
        print('✅ Arama sonuçları:');
        print('🔍 Filtrelenmiş ilan sayısı: ${response.listings.length}');
        
        for (final listing in response.listings) {
          print('🏠 ${listing.title}');
          print('   💰 ${listing.price} ${listing.currency}');
          print('   📍 ${listing.provinceName}');
        }
      },
    );
  }

  /// Tek ilan detay örneği (repository'de bu metod yok - sadece getListings var)
  Future<void> detailExample(String listingId) async {
    print('📝 İlan detayı örneği...');
    print('🆔 İlan ID: $listingId');
    print('⚠️ Bu özellik henüz repository\'de yok - sadece listing listesi mevcut');
    
    // Tüm ilanları çek ve ID'ye göre filtrele
    final result = await _repository.getListings(page: 1, limit: 100);
    
    result.fold(
      (failure) {
        print('❌ Listeden detay arama hatası: ${failure.message}');
      },
      (response) {
        final foundListing = response.listings.where((listing) => listing.id == listingId).firstOrNull;
        if (foundListing != null) {
          print('✅ İlan listede bulundu:');
          print('🏷️ Başlık: ${foundListing.title}');
          print('💰 Fiyat: ${foundListing.price} ${foundListing.currency}');
          print('📍 Konum: ${foundListing.provinceName} / ${foundListing.districtName}');
        } else {
          print('❌ İlan bulunamadı');
        }
      },
    );
  }

  /// İstatistik örneği (repository'den manuel hesaplama)
  Future<void> statsExample() async {
    print('📊 İstatistik örneği başlatılıyor...');
    
    // İstatistikler için tüm ilanları çek
    final result = await _repository.getListings(page: 1, limit: 100);
    
    result.fold(
      (failure) {
        print('❌ İstatistik hesaplama hatası: ${failure.message}');
      },
      (response) {
        print('✅ İstatistikler hesaplandı:');
        print('📊 Toplam ilan: ${response.totalCount}');
        print('📄 Toplam sayfa: ${response.totalPages}');
        
        // Fiyat istatistikleri
        if (response.listings.isNotEmpty) {
          final prices = response.listings.map((l) => l.price).toList();
          final minPrice = prices.reduce((a, b) => a < b ? a : b);
          final maxPrice = prices.reduce((a, b) => a > b ? a : b);
          final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
          
          print('💰 Min fiyat: ${minPrice.toStringAsFixed(0)}');
          print('💰 Max fiyat: ${maxPrice.toStringAsFixed(0)}');
          print('💰 Ortalama: ${avgPrice.toStringAsFixed(0)}');
        }
      },
    );
  }

  /// Pagination örneği (sayfa sayfa gezinme)
  Future<void> paginationExample() async {
    print('📄 Pagination örneği başlatılıyor...');
    
    int currentPage = 1;
    const pageSize = 3;
    
    while (currentPage <= 3) { // İlk 3 sayfayı göster
      print('\n--- SAYFA $currentPage ---');
      
      final result = await _repository.getListings(
        page: currentPage,
        limit: pageSize,
      );
      
      await result.fold(
        (failure) async {
          print('❌ Sayfa $currentPage hatası: ${failure.message}');
          return;
        },
        (response) async {
          print('📄 Sayfa $currentPage/${response.totalPages}');
          print('📊 Bu sayfada ${response.listings.length} ilan');
          
          for (int i = 0; i < response.listings.length; i++) {
            final listing = response.listings[i];
            final globalIndex = (currentPage - 1) * pageSize + i + 1;
            print('$globalIndex. ${listing.title} - ${listing.price} ${listing.currency}');
          }
          
          // Son sayfaysa döngüyü kır
          if (currentPage >= response.totalPages) {
            print('\n✅ Son sayfaya ulaşıldı!');
            return;
          }
        },
      );
      
      currentPage++;
      
      // Sayfa arası kısa bekleme
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Tüm örnekleri çalıştır
  Future<void> runAllExamples() async {
    print('🎯 Tüm repository örnekleri başlatılıyor...\n');
    
    try {
      await basicExample();
      await Future.delayed(const Duration(seconds: 1));
      
      await searchExample();
      await Future.delayed(const Duration(seconds: 1));
      
      await statsExample();
      await Future.delayed(const Duration(seconds: 1));
      
      await paginationExample();
      
      print('\n🎉 Tüm örnekler tamamlandı!');
    } catch (e) {
      print('💥 Örnek çalıştırılırken hata: $e');
    }
  }
}

// Kullanım:
// final example = ListingRepositoryExample();
// await example.runAllExamples();

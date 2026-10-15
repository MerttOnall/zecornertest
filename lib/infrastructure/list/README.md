# Listing Repository

Bu repository gayrimenkul ilanlarının yönetimi için kullanılır. Token gerektirmez, direkt API key'ler ile çalışır ve pagination desteği sağlar.

## Özellikler

- ✅ Pagination desteği (sayfa sayfa veri çekme)
- ✅ Filtreleme ve arama
- ✅ Tek ilan detayı
- ✅ İstatistiksel veriler
- ✅ Error handling (Either pattern)
- ✅ Detaylı logging

## Kullanım Örnekleri

### 1. Temel İlan Listesi

```dart
final repository = ListingRepository();

// İlk sayfa, 10 ilan
final result = await repository.getListings();

result.fold(
  (failure) => print('Hata: ${failure.message}'),
  (response) {
    print('Toplam ilan: ${response.totalCount}');
    print('Toplam sayfa: ${response.totalPages}');
    
    for (final listing in response.listings) {
      print('${listing.title} - ${listing.price} ${listing.currency}');
    }
  },
);
```

### 2. Sayfalı Çekme

```dart
// 2. sayfa, 20 ilan
final result = await repository.getListings(
  page: 2,
  limit: 20,
);
```

### 3. Filtreleme ve Arama

```dart
// Belirli kriterlere göre arama
final result = await repository.searchListings(
  searchQuery: 'istanbul',
  page: 1,
  limit: 10,
  priceMin: 100000,
  priceMax: 500000,
  listingType: 'satilik',
  propertyType: 'konut-daire',
  province: 'İstanbul',
  district: 'Kadıköy',
);
```

### 4. Tek İlan Detayı

```dart
final result = await repository.getListingDetail('ilan-id');

result.fold(
  (failure) => print('Hata: ${failure.message}'),
  (detail) => print('İlan detayı: $detail'),
);
```

### 5. İstatistikler

```dart
final result = await repository.getListingStats();

result.fold(
  (failure) => print('Hata: ${failure.message}'),
  (stats) => print('İstatistikler: $stats'),
);
```

## Hata Yönetimi

Repository, `Either<Failure, T>` pattern'ini kullanır:

- **NetworkFailure**: Ağ bağlantı hataları
- **ServerFailure**: Sunucu hataları (4xx, 5xx)
- **UnknownFailure**: Bilinmeyen hatalar

## API Endpoints

- `GET /api/zecorner/listings` - İlan listesi (pagination + filter desteği)
- `GET /api/zecorner/listings/{id}` - İlan detayı
- `GET /api/zecorner/listings/stats` - İstatistikler

## Gerekli Environment Variables

```env
X_API_KEY=your-api-key
X_APP_ID=zecorner
```

## Query Parametreleri

### getListings()
- `page`: Sayfa numarası (varsayılan: 1)
- `limit`: Sayfa başına kayıt sayısı (varsayılan: 10)
- `filters`: Ek filtreler (Map)

### searchListings()
- `search`: Arama sorgusu
- `price_min`: Minimum fiyat
- `price_max`: Maksimum fiyat
- `property_type`: Emlak tipi
- `listing_type`: İlan tipi (satilik/kiralik)
- `province`: İl
- `district`: İlçe

# Gayrimenkul İlanları Modelleri

Bu dizinde gayrimenkul ilanları için gerekli Dart modelleri bulunmaktadır.

## Modeller

### PropertyModel
Gayrimenkul özelliklerini temsil eden model:
- `code`: Özellik kodu (örn: "m2-brut", "oda-sayisi")
- `numberValue`: Sayısal değer (nullable)
- `stringValue`: String değer (nullable)  
- `valueId`: Değer ID'si
- `value`: Değer

### ListingModel
Gayrimenkul ilanını temsil eden ana model:
- `id`: İlan benzersiz ID'si
- `listingNo`: İlan numarası
- `title`: İlan başlığı
- `price`: Fiyat
- `currency`: Para birimi
- `type`: İlan tipi (satilik/kiralik)
- `provinceCode`, `provinceName`: İl bilgileri
- `districtCode`, `districtName`: İlçe bilgileri
- `quarterCode`, `quarterName`: Mahalle bilgileri
- `propertiesShortList`: Kısa özellik listesi
- `properties`: Detaylı özellikler map'i
- Ve diğer iletişim, konum bilgileri...

### ListingsResponseModel
API response'unu temsil eden wrapper model:
- `listings`: İlan listesi
- `totalCount`: Toplam ilan sayısı
- `totalPages`: Toplam sayfa sayısı
- `page`: Mevcut sayfa

## Kullanım Örneği

```dart
// JSON'dan parse etme
final response = ListingsResponseModel.fromJson(jsonData);

// İlanları alıp kullanma
for (final listing in response.listings) {
  print('İlan: ${listing.title}');
  print('Fiyat: ${listing.price} ${listing.currency}');
  
  // Özelliklere erişim
  final m2Brut = listing.properties['m2-brut']?.numberValue;
  print('Brüt m²: $m2Brut');
}

// JSON'a çevirme
final jsonData = response.toJson();
```

import '../models/property_model.dart';

class PropertyService {
  static final PropertyService _instance = PropertyService._internal();
  factory PropertyService() => _instance;
  PropertyService._internal();

  // Simulated database/API data - Bu veriler API'den gelecek
  static final List<Map<String, dynamic>> _mockApiData = [
    // Original properties
    {
      'id': 'prop_001',
      'title': 'Deneme İlan',
      'location': 'İstanbul / Üsküdar / Selamiali',
      'price': '₺30.000',
      'type': 'Kiralık',
      'consultantName': 'Nisa Karabacak',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'nisa.karabacak@zecorner.com',
      'consultantPhone': '0532 123 45 67',
      'images': [
        'assets/logo/ilan.png',
        'assets/logo/ilan.png',
        'assets/logo/ilan.png',
      ],
      'propertyDetails': 'Modern daire, merkezi konumda.',
      'metaData': {
        'area': '102',
        'rooms': '3+1',
        'floor': '5',
        'age': '10',
        'heating': 'Merkezi'
      }
    },
    {
      'id': 'prop_002',
      'title': 'Ticaretin Merkezi Karaköy\'de Satılık Bina',
      'location': 'İstanbul / Ataşehir / Küçükbakkalköy',
      'price': '₺140.000.000',
      'type': 'Satılık',
      'consultantName': 'Erol Aydoğdu',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'erol.aydogdu@zecorner.com',
      'consultantPhone': '0532 987 65 43',
      'images': [
        'assets/logo/ilan.png',
        'assets/logo/ilan.png',
      ],
      'propertyDetails': 'Ticari bina, yatırım fırsatı.',
      'metaData': {
        'area': '2500',
        'floors': '8',
        'parking': 'var',
        'elevator': 'var'
      }
    },
    {
      'id': 'prop_003',
      'title': 'Maltepe Bağlarbaşı Mahallesi\'nde Satılık İşyeri',
      'location': 'Rize / Güneysu / Adacami',
      'price': '₺85.000',
      'type': 'Satılık',
      'consultantName': 'Kaan Yeldan',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'kaan.yeldan@zecorner.com',
      'consultantPhone': '0532 555 33 22',
      'images': [
        'assets/logo/ilan.png',
      ],
      'propertyDetails': 'İşyeri, uygun fiyat.',
      'metaData': {
        'area': '85',
        'type': 'Dükkan',
        'frontage': '4m'
      }
    },
    // Home Tum Ilan Screen properties - dinamik ID'lerle
    {
      'id': 'property_621847213',
      'title': '2+1 Site İçinde, Bahçeli',
      'location': 'Ataşehir, İstanbul',
      'price': '4.200.000 ₺',
      'type': 'Satılık',
      'consultantName': 'Ahmet Yılmaz',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'ahmet.yilmaz@zecorner.com',
      'consultantPhone': '0532 111 22 33',
      'images': [
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '110 m² genişliğinde 2+1 site içinde bahçeli daire. Ataşehir\'da merkezi konumda.',
      'metaData': {
        'area': '110',
        'rooms': '2+1',
        'floor': '1/8',
        'heating': 'Merkezi'
      }
    },
    {
      'id': 'property_347821564',
      'title': '1+1 Yatırımlık Daire',
      'location': 'Maltepe, İstanbul',
      'price': '2.100.000 ₺',
      'type': 'Satılık',
      'consultantName': 'Ayşe Demir',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'ayse.demir@zecorner.com',
      'consultantPhone': '0532 444 55 66',
      'images': [
        'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '65 m² genişliğinde 1+1 yatırımlık daire. Maltepe\'de merkezi konumda.',
      'metaData': {
        'area': '65',
        'rooms': '1+1',
        'floor': '5/10',
        'heating': 'Merkezi'
      }
    },
    {
      'id': 'property_891237456',
      'title': 'Fırsat!!! Devren Cafe & Bar -Komple Bina - Sanat Sokağına Yakın',
      'location': 'Urla, İzmir / Yeni Mah.',
      'price': '2.500.000 ₺',
      'type': 'Kiralık',
      'consultantName': 'Mehmet Kaya',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'mehmet.kaya@zecorner.com',
      'consultantPhone': '0532 777 88 99',
      'images': [
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '190 m² genişliğinde cafe & bar işyeri. Urla\'da sanat sokağına yakın.',
      'metaData': {
        'area': '190',
        'type': 'Cafe & Bar',
        'frontage': '8m'
      }
    },
    {
      'id': 'property_456789123',
      'title': 'Bayındır Lütuflar\'da 264 M2 Bahçe',
      'location': 'Bayındır, İzmir / Lütuflar Mh.',
      'price': '130.000 ₺',
      'type': 'Satılık',
      'consultantName': 'Fatma Öz',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'fatma.oz@zecorner.com',
      'consultantPhone': '0532 333 44 55',
      'images': [
        'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '264 m² genişliğinde bahçe arsası. Bayındır\'da yatırım fırsatı.',
      'metaData': {
        'area': '264',
        'type': 'Bahçe',
        'zoning': 'Konut'
      }
    },
    {
      'id': 'property_789456123',
      'title': '4+1 Lüks Villa, Havuzlu Site',
      'location': 'Çankaya, Ankara',
      'price': '12.500.000 ₺',
      'type': 'Satılık',
      'consultantName': 'Ali Yılmaz',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'ali.yilmaz@zecorner.com',
      'consultantPhone': '0532 666 77 88',
      'images': [
        'https://images.unsplash.com/photo-1507089947368-19c1da9775ae?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '250 m² genişliğinde 4+1 lüks villa. Çankaya\'da havuzlu site içinde.',
      'metaData': {
        'area': '250',
        'rooms': '4+1',
        'floor': '2/2',
        'pool': 'Var'
      }
    },
    {
      'id': 'property_123789456',
      'title': '3+1 Deniz Manzaralı Daire',
      'location': 'Moda, İstanbul',
      'price': '8.500.000 ₺',
      'type': 'Satılık',
      'consultantName': 'Zeynep Ak',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'zeynep.ak@zecorner.com',
      'consultantPhone': '0532 999 00 11',
      'images': [
        'https://images.unsplash.com/photo-1468436139062-f60a71c5c892?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '140 m² genişliğinde 3+1 deniz manzaralı daire. Moda\'da prestijli lokasyon.',
      'metaData': {
        'area': '140',
        'rooms': '3+1',
        'floor': '4/6',
        'view': 'Deniz'
      }
    },
    {
      'id': 'property_654321987',
      'title': '1+0 Stüdyo Daire, Merkezi',
      'location': 'Keçiören, Ankara',
      'price': '950.000 ₺',
      'type': 'Kiralık',
      'consultantName': 'Burak Özkan',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'burak.ozkan@zecorner.com',
      'consultantPhone': '0532 222 33 44',
      'images': [
        'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '40 m² genişliğinde 1+0 stüdyo daire. Keçiören\'de merkezi konumda.',
      'metaData': {
        'area': '40',
        'rooms': '1+0',
        'floor': '1/5',
        'heating': 'Kombi'
      }
    },
    {
      'id': 'property_987654321',
      'title': '3+1 Bahçeli Müstakil Ev',
      'location': 'Urla, İzmir / Yelaltı',
      'price': '3.200.000 ₺',
      'type': 'Satılık',
      'consultantName': 'Selin Yurt',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'selin.yurt@zecorner.com',
      'consultantPhone': '0532 555 66 77',
      'images': [
        'https://images.unsplash.com/photo-1467987506553-8f3916508521?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '120 m² genişliğinde 3+1 bahçeli müstakil ev. Urla\'da sakin bir lokasyonda.',
      'metaData': {
        'area': '120',
        'rooms': '3+1',
        'floor': '1/1',
        'garden': 'Var'
      }
    },
    {
      'id': 'property_147258369',
      'title': 'Ofis Katı, Plaza İçinde',
      'location': 'Ataşehir, İstanbul',
      'price': '6.000.000 ₺',
      'type': 'Satılık',
      'consultantName': 'Emre Kılıç',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'emre.kilic@zecorner.com',
      'consultantPhone': '0532 888 99 00',
      'images': [
        'https://images.unsplash.com/photo-1464852045489-a1823b8b9a6b?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '180 m² genişliğinde ofis katı. Ataşehir\'da plaza içinde prestijli lokasyon.',
      'metaData': {
        'area': '180',
        'type': 'Ofis',
        'floor': '7/15',
        'parking': 'Var'
      }
    },
    {
      'id': 'property_369258147',
      'title': '2+1 Kiralık Daire, Uygun Fiyatlı',
      'location': 'Kadıköy, İstanbul',
      'price': '18.000 ₺',
      'type': 'Kiralık',
      'consultantName': 'Deniz Arslan',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'deniz.arslan@zecorner.com',
      'consultantPhone': '0532 123 45 67',
      'images': [
        'https://images.unsplash.com/photo-1465101178521-c1a9136a3c8b?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '90 m² genişliğinde 2+1 kiralık daire. Kadıköy\'de uygun fiyatlı.',
      'metaData': {
        'area': '90',
        'rooms': '2+1',
        'floor': '2/6',
        'heating': 'Kombi'
      }
    },
    {
      'id': 'property_741852963',
      'title': 'Satılık Arsa, Yatırıma Uygun',
      'location': 'Maltepe, İstanbul',
      'price': '350.000 ₺',
      'type': 'Satılık',
      'consultantName': 'Kemal Doğan',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'kemal.dogan@zecorner.com',
      'consultantPhone': '0532 456 78 90',
      'images': [
        'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=800&q=80',
      ],
      'propertyDetails': '300 m² genişliğinde satılık arsa. Maltepe\'de yatırım fırsatı.',
      'metaData': {
        'area': '300',
        'type': 'Arsa',
        'zoning': 'Konut'
      }
    },
    // New properties matching listings IDs
    {
      'id': '1',
      'title': 'Deneme İlan',
      'location': 'İstanbul / Üsküdar / Selamiali Mah.',
      'price': '₺30.000',
      'type': 'Kiralık',
      'consultantName': 'Nisa Karabacak',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'nisa.karabacak@zecorner.com',
      'consultantPhone': '0532 123 45 67',
      'images': [
        'https://picsum.photos/800/400?random=1',
        'https://picsum.photos/800/400?random=1&orientation=portrait',
        'https://picsum.photos/800/400?random=1&grayscale',
      ],
      'propertyDetails': '102 m² genişliğinde, 3+1 oda düzeninde modern daire. Merkezi ısıtma sistemi, 5. katta, 10 yaşında bina. Selamiali Mahallesi\'nde konumlanmış.',
      'metaData': {
        'area': '102',
        'rooms': '3+1',
        'floor': '5',
        'age': '10',
        'heating': 'Merkezi'
      }
    },
    {
      'id': '2',
      'title': 'Ticaretin Merkezi Karaköy\'de Satılık Bina',
      'location': 'İstanbul / Ataşehir / Küçükbakkalköy Mah.',
      'price': '₺140.000.000',
      'type': 'Satılık',
      'consultantName': 'Erol Aydoğdu',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'erol.aydogdu@zecorner.com',
      'consultantPhone': '0532 987 65 43',
      'images': [
        'https://picsum.photos/800/400?random=2',
        'https://picsum.photos/800/400?random=2&orientation=portrait',
        'https://picsum.photos/800/400?random=2&grayscale',
      ],
      'propertyDetails': '2500 m² alana sahip 8 katlı ticari bina. Asansör, otopark mevcut. Karaköy\'ün ticaret merkezinde yatırım fırsatı.',
      'metaData': {
        'area': '2500',
        'floors': '8',
        'parking': 'Var',
        'elevator': 'Var'
      }
    },
    {
      'id': '3',
      'title': 'Maltepe Bağlarbaşı Mahallesi\'nde Satılık İşyeri',
      'location': 'Rize / Güneysu / Adacami Mah.',
      'price': '₺85.000',
      'type': 'Satılık',
      'consultantName': 'Kaan Yeldan',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'kaan.yeldan@zecorner.com',
      'consultantPhone': '0532 555 33 22',
      'images': [
        'https://picsum.photos/800/400?random=3',
        'https://picsum.photos/800/400?random=3&orientation=portrait',
      ],
      'propertyDetails': '85 m² alana sahip satılık işyeri. Dükkan tipi mülk, 4 metre cephe genişliği.',
      'metaData': {
        'area': '85',
        'type': 'Dükkan',
        'frontage': '4m'
      }
    },
    {
      'id': '4',
      'title': 'Şişli Merkez\'de Lüks Ofis',
      'location': 'İstanbul / Şişli / Nişantaşı Mah.',
      'price': '₺75.000',
      'type': 'Kiralık',
      'consultantName': 'Ayşe Demir',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'ayse.demir@zecorner.com',
      'consultantPhone': '0532 444 55 66',
      'images': [
        'https://picsum.photos/800/400?random=4',
        'https://picsum.photos/800/400?random=4&orientation=portrait',
        'https://picsum.photos/800/400?random=4&grayscale',
      ],
      'propertyDetails': '250 m² genişliğinde lüks ofis alanı. Nişantaşı\'nın merkezinde prestijli lokasyon.',
      'metaData': {
        'area': '250',
        'type': 'Ofis',
        'floor': '12',
        'parking': 'Var'
      }
    },
    {
      'id': '5',
      'title': 'Beşiktaş\'ta Deniz Manzaralı Daire',
      'location': 'İstanbul / Beşiktaş / Ortaköy Mah.',
      'price': '₺45.000',
      'type': 'Kiralık',
      'consultantName': 'Mehmet Kaya',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'mehmet.kaya@zecorner.com',
      'consultantPhone': '0532 777 88 99',
      'images': [
        'https://picsum.photos/800/400?random=5',
        'https://picsum.photos/800/400?random=5&orientation=portrait',
        'https://picsum.photos/800/400?random=5&grayscale',
      ],
      'propertyDetails': '180 m² genişliğinde 4+1 daire. Boğaz manzaralı, Ortaköy\'ün merkezi lokasyonunda.',
      'metaData': {
        'area': '180',
        'rooms': '4+1',
        'view': 'Deniz',
        'balcony': 'Var'
      }
    },
    {
      'id': '6',
      'title': 'Bursa Mudanya\'da Villa',
      'location': 'Bursa / Mudanya / Zeytinbağı Mah.',
      'price': '₺8.500.000',
      'type': 'Satılık',
      'consultantName': 'Fatma Öz',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'fatma.oz@zecorner.com',
      'consultantPhone': '0532 333 44 55',
      'images': [
        'https://picsum.photos/800/400?random=6',
        'https://picsum.photos/800/400?random=6&orientation=portrait',
      ],
      'propertyDetails': '400 m² genişliğinde 5+2 villa. Mudanya\'da sakin bir lokasyonda, geniş bahçe alanı.',
      'metaData': {
        'area': '400',
        'rooms': '5+2',
        'garden': 'Var',
        'pool': 'Yok'
      }
    },
    {
      'id': '7',
      'title': 'Kadıköy\'de Modern Residence',
      'location': 'İstanbul / Kadıköy / Fenerbahçe Mah.',
      'price': '₺25.000',
      'type': 'Kiralık',
      'consultantName': 'Ali Yılmaz',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'ali.yilmaz@zecorner.com',
      'consultantPhone': '0532 666 77 88',
      'images': [
        'https://picsum.photos/800/400?random=7',
        'https://picsum.photos/800/400?random=7&orientation=portrait',
      ],
      'propertyDetails': '140 m² genişliğinde 3+1 residence dairesi. Modern mimari, güvenlik hizmetleri mevcut.',
      'metaData': {
        'area': '140',
        'rooms': '3+1',
        'security': 'Var',
        'gym': 'Var'
      }
    },
    {
      'id': '8',
      'title': 'Antalya Merkez\'de Satılık İş Merkezi',
      'location': 'Antalya / Muratpaşa / Liman Mah.',
      'price': '₺55.000.000',
      'type': 'Satılık',
      'consultantName': 'Zeynep Ak',
      'consultantTitle': 'Gayrimenkul Danışmanı',
      'consultantEmail': 'zeynep.ak@zecorner.com',
      'consultantPhone': '0532 999 00 11',
      'images': [
        'https://picsum.photos/800/400?random=8',
        'https://picsum.photos/800/400?random=8&orientation=portrait',
        'https://picsum.photos/800/400?random=8&grayscale',
      ],
      'propertyDetails': '1200 m² alana sahip modern iş merkezi. Antalya\'nın merkezi lokasyonunda yatırım fırsatı.',
      'metaData': {
        'area': '1200',
        'type': 'İş Merkezi',
        'floors': '6',
        'parking': 'Var'
      }
    },
  ];

  // Helper method to generate property ID from title
  static String generatePropertyId(String title) {
    return 'property_${title.hashCode.abs()}';
  }

  // API simulation methods - Gerçek API'da bu metodlar HTTP istekleri yapacak

  /// Tüm favori ilanları getir
  Future<List<PropertyModel>> getFavoriteProperties({int? userId}) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate API response
    try {
      return _mockApiData.map((data) => PropertyModel.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Favori ilanlar yüklenirken hata oluştu: $e');
    }
  }

  /// Belirli bir ilanı getir
  Future<PropertyModel?> getPropertyById(String propertyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      final data = _mockApiData.firstWhere(
        (item) => item['id'] == propertyId,
        orElse: () => throw Exception('İlan bulunamadı'),
      );
      return PropertyModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  /// İlan favori durumunu güncelle
  Future<bool> updateFavoriteStatus(String propertyId, bool isFavorite) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      // API'da favoriler tablosuna kayıt/silme işlemi yapılacak
      // Şimdilik başarılı olduğunu varsayıyoruz
      return true;
    } catch (e) {
      throw Exception('Favori durumu güncellenirken hata oluştu: $e');
    }
  }

  /// Kullanıcının favori ilan ID'lerini getir
  Future<List<String>> getUserFavoriteIds({int? userId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      // API'dan kullanıcının favori ilan ID'leri gelecek
      return _mockApiData.map((item) => item['id'] as String).toList();
    } catch (e) {
      throw Exception('Favori listesi yüklenirken hata oluştu: $e');
    }
  }

  /// Danışmanın diğer ilanlarını getir
  Future<List<PropertyModel>> getConsultantProperties(String consultantEmail) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    try {
      final consultantProperties = _mockApiData
          .where((data) => data['consultantEmail'] == consultantEmail)
          .map((data) => PropertyModel.fromMap(data))
          .toList();
      
      return consultantProperties;
    } catch (e) {
      throw Exception('Danışman ilanları yüklenirken hata oluştu: $e');
    }
  }

  /// İlan ara/filtrele
  Future<List<PropertyModel>> searchProperties({
    String? query,
    String? type,
    String? location,
    double? minPrice,
    double? maxPrice,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    try {
      var results = _mockApiData.map((data) => PropertyModel.fromMap(data)).toList();
      
      if (query != null && query.isNotEmpty) {
        results = results.where((prop) => 
          prop.title.toLowerCase().contains(query.toLowerCase()) ||
          prop.location.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
      
      if (type != null) {
        results = results.where((prop) => prop.type == type).toList();
      }
      
      if (location != null) {
        results = results.where((prop) => 
          prop.location.toLowerCase().contains(location.toLowerCase())
        ).toList();
      }
      
      return results;
    } catch (e) {
      throw Exception('Arama sırasında hata oluştu: $e');
    }
  }

  // Cache management for offline support
  static List<PropertyModel>? _cachedProperties;
  
  void cacheProperties(List<PropertyModel> properties) {
    _cachedProperties = properties;
  }
  
  List<PropertyModel>? getCachedProperties() {
    return _cachedProperties;
  }
  
  void clearCache() {
    _cachedProperties = null;
  }
} 
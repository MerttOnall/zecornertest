import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/infrastructure/contact/contact_api_client.dart';
import 'package:zecorner/core/network/network_info_impl.dart';
import 'package:dartz/dartz.dart';

class ContactTypeRepository {
  // ignore: unused_field
  final ContactApiClient _client;
  // ignore: unused_field
  final NetworkInfoImpl _networkInfo;

  ContactTypeRepository({
    required ContactApiClient client,
    required NetworkInfoImpl networkInfo,
  })  : _client = client,
        _networkInfo = networkInfo;

  // GET - Contact type'ları getir (Sadece hardcode liste - en güncel)
  Future<Either<Failure, List<String>>> getContactTypes() async {
    // Tüm kişi türleri (Fotoğraflarda görünenler - eksiksiz liste)
    final allContactTypes = [
      'Super Admin',
      'Admin',
      'Broker',
      'Gayrimenkul Danışmanı',
      'Takım Lideri',
      'Franchise Satış ve Geliştirme Bölge Müdürü',
      'Ofis Asistanı',
      'Franchise Geliştime Uzmanı',
      'Franchise Satış Destek Uzmanı',
      'Franchise Satış Ve Geliştirme Direktörü',
      'Franchise Satış Yöneticisi',
      'Müdür',
      'Saha Satış Asistanı',
      'Saha Satış Uzmanı',
    ];

    try {
      print('✅ Toplam ${allContactTypes.length} kişi türü yüklendi');
      print('📋 Kişi Türleri: $allContactTypes');
      return Right(allContactTypes);
    } catch (e) {
      print('❌ Contact Types Error: $e');
      return Left(ServerFailure(message: 'Kişi türleri yüklenirken hata oluştu: $e'));
    }
  }
}


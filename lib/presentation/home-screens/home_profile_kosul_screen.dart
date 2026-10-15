import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';

class HomeProfileKosulScreen extends StatefulWidget {
  const HomeProfileKosulScreen({super.key});

  @override
  State<HomeProfileKosulScreen> createState() => _HomeProfileKosulScreenState();
}

class _HomeProfileKosulScreenState extends State<HomeProfileKosulScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(begin: 0.99, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kullanım Koşulları'),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromRGBO(238, 46, 36, 1),
        elevation: 1,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ZECORNER WEB SİTESİ VE MOBİL UYGULAMA KULLANIM ŞARTLARI",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(238, 46, 36, 1),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Lütfen sitemizi ve mobil uygulamamızı kullanmadan evvel bu 'kullanım şartları'nı dikkatlice okuyunuz. Zecorner ile ilgili siteyi ve mobil uygulamayı kullanan ve soru soran müşterilerimiz aşağıdaki şartları kabul etmiş varsayılmaktadır:",
                    style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle("1- Genel Hükümler"),
                  _sectionBody("HAUSBERRY GAYRİMENKUL VE BİLGİ TEKNOLOJİLERİ ANONİM ŞİRKETİ (\"Şirket\") tarafından işletilen \"www.zecorner.com\" adresindeki internet sitesi (\"İnternet Sitesi\") ve mobil uygulamasını (\"Mobil Uygulama\") ziyaret eden ve/veya herhangi bir şekilde kullanan kişiler (\"Kullanıcı\") tarafından, işbu Kullanım Sözleşmesi'nin İnternet Sitesi ve Mobil Uygulama kullanılmadan önce okunması gereklidir. Kullanım Sözleşmesi'nde düzenlenen koşulların Kullanıcı tarafından kabul edilmemesi halinde, web sitesi ve mobil uygulamanın kullanımı mümkün değildir. Kullanıcının İnternet Sitesi'ni veya Mobil Uygulamayı kullanması ve/veya kişisel bilgilerinin yer alacağı formu doldurması halinde işbu Sözleşme'mde yazılı şartları kabul edilmiş ve onaylanmış olacaktır."),
                  const SizedBox(height: 12),
                  _sectionBody("Sitemizdeki ve mobil uygulamamızdaki web sayfaları ve ona bağlı tüm sayfalar Barbaros Mah. Halk Cad. Cosmo Plex No: 1 İç Kapı No: 9 Ataşehir / İstanbul adresinde bulunan Hausberry Gayrimenkul Ve Bilgi Teknolojileri Anonim Şirketi A.Ş. (Şirket) malıdır ve onun tarafından işletilir. Sizler ('Kullanıcı') sitede ve mobil uygulamada sunulan tüm hizmetleri kullanırken aşağıdaki şartlara tabi olduğunuzu, sitedeki hizmetten yararlanmakla ve kullanmaya devam etmekle; bağlı olduğunuz yasalara göre sözleşme imzalama hakkına, yetkisine ve hukuki ehliyetine sahip ve 18 yaşın üzerinde olduğunuzu, bu sözleşmeyi okuduğunuzu, anladığınızı ve sözleşmede yazan şartlarla bağlı olduğunuzu kabul etmiş sayılırsınız."),
                  const SizedBox(height: 12),
                  _sectionBody("Şirket, İnternet Sitesi ve/veya Mobil Uygulamada mevcut her tür hizmet, soru, kullanma koşulları ile İnternet Sitesi ve/veya Mobil Uygulamada sunulan bilgileri önceden bir ihtara gerek olmaksızın değiştirme, yeniden organize etme, yayını durdurma hakkını saklı tutar. Değişiklikler İnternet Sitesi'nde ve/veya Mobil Uygulamada yayın tarihinde yürürlüğe girer. Şirket, Kullanıcılara İnternet Sitesi'ne ve/veya Mobil Uygulamaya her girişte yasal uyarı sayfasını ziyaret etmelerini tavsiye etmektedir. Bu koşullar link verilen diğer internet sayfaları için de geçerlidir."),
                  const SizedBox(height: 12),
                  _sectionBody("İşbu sözleşme taraflara sözleşme konusu site ve mobil uygulama ile ilgili hak ve yükümlülükler yükler ve taraflar işbu sözleşmeyi kabul ettiklerinde bahsi geçen hak ve yükümlülükleri eksiksiz, doğru, zamanında, işbu sözleşmede talep edilen şartlar dâhilinde yerine getireceklerini beyan ederler."),
                  const SizedBox(height: 20),
                  _sectionTitle("1. SORUMLULUKLAR"),
                  _sectionList([
                    "Şirket, fiyatlar ve sunulan hizmetler üzerinde değişiklik yapma hakkını her zaman saklı tutar.",
                    "Şirket, üyenin sözleşme konusu hizmetlerden, teknik arızalar ve mücbir sebepler dışında yararlandırılacağını kabul ve taahhüt eder.",
                    "Kullanıcı, sitenin/mobil uygulamanın kullanımında tersine mühendislik yapmayacağını ya da bunların kaynak kodunu bulmak veya elde etmek amacına yönelik herhangi bir başka işlemde bulunmayacağını aksi halde Zecorner ve diğer 3. Kişiler nezdinde doğacak zararlardan sorumlu olacağını, hakkında hukuki ve cezai işlem yapılacağını peşinen kabul eder.",
                    "Kullanıcı, site / mobil uygulama içindeki faaliyetlerinde, sitenin/ mobil uygulamanın herhangi bir bölümünde veya iletişimlerinde genel ahlaka ve adaba aykırı, kanuna aykırı, Zecorner ve 3. Kişilerin haklarını zedeleyen, yanıltıcı, saldırgan, müstehcen, pornografik, kişilik haklarını zedeleyen, telif haklarına aykırı, yasa dışı faaliyetleri teşvik eden içerikler üretmeyeceğini, paylaşmayacağını kabul ve taahhüt eder. Aksi halde Zecorner ve 3.kişiler aleyhine oluşacak zarardan tamamen kendisi sorumludur ve bu durumda şirket yetkilileri, bu tür hesapları askıya alabilir, sona erdirebilir. Şirket bunların yanında hukuki ve cezai yollara başvurma hakkına sahiptir. Bu sebeple yargı mercilerinden etkinlik veya kullanıcı hesapları ile ilgili bilgi talepleri gelirse bu bilgilerin gerekli merciiler ile paylaşılma yetkisi şirketin tekelindedir. Kullanıcı bu hususu işbu sözleşmeyi elektronik ortamda imza altına almakla gayrikabili rücu kabul ve taahhüt eder.",
                    "Sitenin üyelerinin birbirleri veya Şirket'in bağlantısı olmayan diğer üçüncü şahıslarla olan ilişkileri kendi sorumluluğundadır.",
                    "Kullanıcı, İnternet Sitesi ve/veya Mobil Uygulamayı kullanmaya başladığı andan itibaren bu Kullanım Sözleşmesi'nin tüm hükümlerini kabul etmiş sayılacağını ve sözleşmenin kendisi hakkında hüküm ifade edeceğini kabul eder. Kullanıcı işbu sözleşme ile üstlenmiş olduğu yükümlülüklere aykırı hareketi nedeniyle Şirket'in, Şirket ile franchise bağı olan İşletmelerin ve Şirket aracılığı ile hizmet veren diğer üçüncü kişilerin uğrayacağı her türlü zararı aynen tazmin etmeyi kabul ve taahhüt eder. Şirket, Kullanıcının sözleşmeye aykırı davranışları nedeniyle kamu kurumlarına ve/veya üçüncü şahıslara ödemek zorunda kalabileceği her türlü tazminat ve/veya idari/adli para cezaları için Kullanıcı'ya aynen rücu hakkına sahiptir. Şirket, aykırı kullanım sebebiyle Şirket veya Şirket ile ilintili üçüncü kişilerin uğramış oldukları zararın tazmini için hukuki yollara başvurma hakkına sahiptir. Kullanıcı işbu sözleşmeyi imza altına almakla birlikte bütün sorumluluklarını anladığını ve sorumlulukları kabul ettiğini taahhüt eder.",
                    "Kullanıcı, diğer Kullanıcıların İnternet Sitesi ve/veya Mobil uygulamayı kullanmasını önleyici veya zorlaştırıcı hareketlerde bulunamaz, sunucuları veya veri tabanlarını otomatik programlar yükleyip zorlayamaz/kilitleyemez, hile girişimlerinde bulunamaz. İşbu hükümde belirtilen fiillerde bulunması halinde Kullanıcının hesabının sonlandırılacağını ve durumdan doğabilecek her türlü hukuki ve cezai sorumluluğu kabul eder.",
                    "Kullanıcı tarafından, herhangi bir zaman İnternet Sitesi / mobil uygulama üzerinden hesap iptal edilebilir. Hesabını iptal eden Kullanıcı'nın İnternet Sitesi'ne ve Mobil Uygulamaya giriş yetkisi iptal edilecektir. Herhangi bir şekilde sonlandırılan Kullanıcı hesabına ait her türlü kaydı silip silmeme kararı Şirket'e aittir. Şirket KVKK ve diğer kanunlar gerektirdiği sürece ayrıca kendi yararına bu bilgileri saklayabilir. Kullanıcı bahsedilen kayıtlarla ilgili KVKK Aydınlatma Metni'nde belirtilenler dışında herhangi bir hak veya tazminat talebinde bulunamaz.",
                    "İnternet Sitesi ve Mobil Uygulama, Şirket'in kontrolü altında olmayan başka internet sitelerinde bağlantı veya referans içerebilir. Şirket, bu sitelerin içeriklere veya içerdikleri diğer bağlantılardan sorumlu değildir.",
                    "Internet Sitesi'nin ve Mobil Uygulamanın belirli yerlerinde o bölüme özel farklı kurallar ve yükümlülükler bölüm içeriğinde duyurulmak kaydı ile belirtilebilir. Bu bölümleri kullanan kişi ve kuruluşlar belirtilen bu kuralları peşinen kabul etmiş sayılır."
                  ]),
                  const SizedBox(height: 20),
                  _sectionTitle("2. FİKRİ MÜLKİYET HAKLARI"),
                  _sectionList([
                    "Şirket, İnternet Sitesi ve Mobil Uygulamanın genel görünüm ve tasarımı ile İnternet Sitesi ile Mobil Uygulamadaki tüm bilgi, resim, her türlü marka, İnternet Sitesi alan adı, logo, ikon, demonstratif, yazılı, elektronik, grafik veya makinede okunabilir şekilde sunulan teknik veriler, bilgisayar yazılımları, uygulanan satış sistemi, iş metodu ve iş modeli de dahil tüm materyallerin (\"Materyaller\") ve bunlara ilişkin fikri ve sınai mülkiyet haklarının sahibi veya lisans sahibidir ve Materyaller yasal koruma altındadır. İnternet Sitesi ve/veya Mobil Uygulamada bulunan hiçbir Materyal önceden izin alınmadan ve kaynak gösterilmeden, kod ve yazılım da dâhil olmak üzere değiştirilemez, kopyalanamaz, çoğaltılamaz, başka bir lisana çevrilemez, yeniden yayımlanamaz, başka bir bilgisayara yüklenemez, postalanamaz, iletilemez, sunulamaz veya dağıtılamaz. İnternet Sitesi ve/veya Mobil Uygulamanın bütünü veya bir kısmı başka bir internet sitesi veya mobil uygulamada izinsiz olarak kullanılamaz.",
                    "Kullanıcılara tanımlanan veya kendi belirledikleri kullanıcı adı, şifre gibi bilgilerin, kullanım haklarının, üçüncü kişi veya kuruluşlarla paylaşılmasından (bu bilgilerin Kullanıcı dışındaki kişiler tarafından kullanılmasından) kaynaklanacak her türlü zarardan doğrudan Kullanıcı sorumludur. Aynı şekilde Kullanıcı, internet ortamında bir başkasına ait IP adresi, elektronik posta adresi, kullanıcı adı gibi kişisel bilgileri kullanamayacağı gibi diğer Kullanıcıların özel bilgilerine de izinsiz olarak ulaşamaz veya bunları kullanamaz. Kullanıcı bu şekilde bir kullanımdan dolayı doğabilecek her türlü hukuki ve cezai yükümlülüğü kabul etmiş sayılmaktadır.",
                    "Şirket, İnternet Sitesi'nin veya Mobil Uygulamanın ve diğer veriler ile programların kullanılması sebebiyle, sözleşmenin ihlali, haksız fiil, ya da başkaca sebeplere binaen, doğabilecek doğrudan ya da dolaylı hiçbir zarardan sorumlu değildir. Şirket, Sözleşme'nin ihlali, haksız fiil, ihmal veya diğer sebepler neticesinde; işlemin kesintiye uğraması, hata, ihmal, kesinti, silinme, kayıp, işlemin veya iletişimin gecikmesi, bilgisayar virüsü, telekomünikasyon hatlarında meydana gelen arızalar, iletişim hatası, hırsızlık, imha veya izinsiz olarak kayıtlara girilmesi, değiştirilmesi veya kullanılması hususlarında herhangi bir sorumluluk kabul etmemektedir.",
                    "Kullanıcı tarafından İnternet Sitesi ve Mobil Uygulama üzerinden iletilen tüm içerik Şirket'e ait olup, işbu içerik pazarlama amacıyla kullanılabilir."
                  ]),
                  const SizedBox(height: 20),
                  _sectionTitle("3. GİZLİ BİLGİ"),
                  _sectionList([
                    "Şirket, site/mobil uygulama üzerinden kullanıcıların ilettiği kişisel bilgileri 3. Kişilere açıklamayacaktır. Bu kişisel bilgiler; kişi adı-soyadı, adresi, telefon numarası, cep telefonu, e-posta adresi gibi Kullanıcı'yı tanımlamaya yönelik her türlü diğer bilgiyi içermekte olup, kısaca 'Gizli Bilgiler' olarak anılacaktır.",
                    "İnternet Sitesi ve Mobil Uygulamada, Kullanıcılara daha iyi hizmet verebilmek amacıyla bazı kişisel bilgiler (isim, yaş, e-posta adresi, vb.) talep edilmektedir. İnternet Sitesi ve Mobil Uygulama ile toplanan bu veriler; kampanya çalışmaları veya Kullanıcı'nın hesabına yönelik özel promosyon faaliyetlerinin yapılabilmesi için İnternet Sitesi ve Mobil Uygulama bünyesinde kullanılmaktadır. Kişisel bilgiler haricinde; İnternet Sitesi veya Mobil Uygulama üzerinden yapılan işlemlere ait istatistiksel veriler analiz edilmekte ve saklanmaktadır.",
                    "Gizli Bilgiler, ancak resmi makamlarca bu bilgilerin talep edilmesi halinde ve yürürlükteki emredici mevzuat hükümleri gereğince resmi makamlara açıklama yapılmasının zorunlu olduğu durumlarda resmi makamlara açıklanabilecektir.",
                    "İnternet Sitesi ve Mobil uygulamayı kullanan Kullanıcıların yapmış oldukları işlemler (ziyaret süresi, zamanı, görüntülenen sayfalar) daha iyi hizmet sunmak amacı ile takip edilmektedir. Bu bilgiler, gizlilik şartlarına bağlı kalınarak İnternet Sitesi ve Mobil Uygulamanın Kullanıcılara sunulan deneyimi geliştirmek, içeriği genişletmek ve iyileştirmek amacı ile reklam vb. konularda işbirliği yapılan firmalarla paylaşılabilmektedir. Bu paylaşım gizli bilgilerin ve kişisel verilerin paylaşılması yasağı kapsamında sayılmamaktadır. Kullanıcı işbu sözleşmeyi imza altına alarak bu hususu anlamış ve kabul beyan ve taahhüt etmiştir.",
                    "Şirket, üyelik formları ile kendisine iletilen bilgileri, Kullanıcıların haberi veya aksi bir talimatı olmaksızın, üçüncü şahıslarla kesinlikle paylaşmamakta, faaliyet dışı hiçbir nedenle ticari amaçla kullanmamakta ve satmamaktadır. İşbu sözleşmede ve Üyelik Hizmet Sözleşmesi'nde bahsedilen diğer hususlar bu hükmün istisnalarını oluşturmaktadır.",
                    "Google dahil üçüncü taraf sağlayıcılar, İnternet Sitesi ve Mobil Uygulama reklamlarını internet üzerindeki yayıncı sitelerde yer verdikleri banner alanlarında gösterecektir. Ziyaretçilerin İnternet Sitesi'ne ve Mobil Uygulamaya geçmişte yaptığı ziyaretleri temel alarak reklamlarla ilgili bilgi toplamak, reklamları optimize etmek ve yayınlamak üzere İnternet Sitesi tarafından ve Google dâhil üçüncü taraf sağlayıcılarca birinci taraf çerezler ile üçüncü taraf çerezler birlikte kullanılmaktadır.",
                    "Ödeme sayfasında talep edilen Kullanıcı kredi kartı bilgileri, İnternet Sitesi ve/veya Mobil Uygulamadan hizmet talep eden Kullanıcıların güvenliğini en üst seviyede tutmak amacıyla hiçbir şekilde İnternet Sitesi ve Mobil Uygulama veya hizmet veren üçüncü şirketlerin sunucularında tutulmamaktadır. Bu şekilde ödemeye yönelik tüm işlemlerin İnternet Sitesi ve Mobil Uygulama ara yüzü üzerinden ilgili banka / ödeme sistemi kuruluşu ile Kullanıcının kullanmakta olduğu cihaz arasında gerçekleşmesi sağlanmaktadır.",
                    "Kullanıcı, işbu Kullanım Sözleşmesini onaylayarak, Şirket ile paylaşmış olduğu bilgilerin şahsına ait olduğunu ve bu bilgilerin, satış ve pazarlama faaliyetlerinin yürütülebilmesi amacıyla ve her türlü iletişim aracına uygun bildiriminin sağlanması için Şirketin iştiraki olan diğer tüzel kişiler ile de paylaşılabileceğine onay vermektedir."
                  ]),
                  const SizedBox(height: 20),
                  _sectionTitle("4. GARANTİ VERMEME"),
                  _sectionBody('İşbu sözleşme maddesi uygulanabilir kanunun izin verdiği azami ölçüde geçerli olacaktır. şirket tarafından sunulan hizmetler "olduğu gibi" ve "mümkün olduğu" temelde sunulmakta ve pazarlanabilirlik, belirli bir amaca uygunluk veya ihlal etmeme konusunda tüm zımni garantiler de dâhil olmak üzere hizmetler veya uygulama ile ilgili olarak (bunlarda yer alan tüm bilgiler dâhil) sarih veya zımni, kanuni veya başka bir nitelikte hiçbir garantide bulunmamaktadır.'),
                  const SizedBox(height: 20),
                  _sectionTitle("5. KAYIT VE GÜVENLİK"),
                  _sectionBody("Kullanıcı, doğru, eksiksiz ve güncel kayıt bilgilerini vermek zorundadır. Aksi halde bu Sözleşme ihlal edilmiş sayılacak ve Kullanıcı bilgilendirilmeksizin hesap kapatılabilecektir. Kullanıcının bu işlemleri sebebiyle oluşacak zararlardan kullanıcı şahsen sorumludur ve bu zararları derhal tazmin etme yükümlülüğü bulunduğunu işbu sözleşmeyi imza altına almakla kabul ve taahhüt eder. Kullanıcı, site, mobil uygulama ve üçüncü taraf sitelerdeki şifre ve hesap güvenliğinden kendisi sorumludur. Aksi halde oluşacak veri kayıplarından ve güvenlik ihlallerinden veya donanım ve cihazların zarar görmesinden Şirket sorumlu tutulamaz."),
                  const SizedBox(height: 20),
                  _sectionTitle("6. HİZMET SÜREKLİLİĞİ"),
                  _sectionList([
                    "Şirket taahhüt ettiği hizmetlerin sürekliliğini sağlamak için, işbu Sözleşme üzerinde ayrıca bildirimde bulunmaksızın tek taraflı olarak değişiklik yapabilir ve her zaman herhangi bir gerekçe göstermeksizin, tek taraflı olarak verdiği hizmeti sürekli veya geçici olarak durdurma, servisin içeriğini değiştirme veya iptal etme hakkına sahiptir. Şirket, herhangi bir değişiklik olması halinde güncel Kullanım Sözleşmesi'ni aynı link altında yeni tarih güncellemesi ile İnternet Sitesi'nde yayınlayacak, gerek görmesi halinde elektronik posta ile Kullanıcılara bildirilecektir. Güncel Kullanım Sözleşmesi, İnternet Sitesi'nde yayınlandığı andan itibaren geçerli olacak ve Internet Sitesi'nin ve/veya Mobil Uygulamanın kullanımı o andan itibaren yenilenmiş Kullanım Şartları'na tabi olacaktır.",
                    "Kullanıcı, kayıt formunu doldurup onayladığı veya bu sistemi kullanarak herhangi bir hizmet aldığı veya sipariş verdiği andan itibaren işbu Kullanım Sözleşmesi'ne uymayı taahhüt etmiş kabul edilir. Sözleşme, Kullanıcının hesabının kapatılması ile Kullanıcı'nın imza altına almış olduğu diğer sözleşmelerden ve işbu sözleşmeden kaynaklanan başkaca yükümlülüğü olmaması halinde kendiliğinden hükümsüz kalır."
                  ]),
                  const SizedBox(height: 20),
                  _sectionTitle("7. MÜCBİR SEBEP"),
                  _sectionBody('Tarafların kontrolünde olmayan; tabii afetler, yangın, patlamalar, iç savaşlar, savaşlar, ayaklanmalar, halk hareketleri, seferberlik ilanı, grev, lokavt ve salgın hastalıklar, altyapı ve internet arızaları, elektrik kesintisi gibi sebeplerden (sözleşme içeriğinde "Mücbir Sebep" olarak anılacaktır.) dolayı sözleşmeden doğan yükümlülükler taraflarca ifa edilemez hale gelirse, taraflar bundan sorumlu değildir. Bu sürede Tarafların işbu Sözleşmeden doğan hak ve yükümlülükleri askıya alınır.'),
                  const SizedBox(height: 20),
                  _sectionTitle("8. SÖZLEŞMENİN BÜTÜNLÜĞÜ VE UYGULANABİLİRLİK"),
                  _sectionBody("İşbu sözleşme şartlarından biri, kısmen veya tamamen geçersiz hale gelirse, sözleşmenin geri kalanı geçerliliğini korumaya devam eder."),
                  const SizedBox(height: 20),
                  _sectionTitle("9. SÖZLEŞMEDE YAPILACAK DEĞİŞİKLİKLER"),
                  _sectionBody("Şirket, dilediği zaman sitede sunulan hizmetleri ve işbu sözleşme şartlarını kısmen veya tamamen değiştirebilir. Değişiklikler sitede yayınlandığı tarihten itibaren geçerli olacaktır. Değişiklikleri takip etmek Kullanıcı'nın sorumluluğundadır. Kullanıcı, sunulan hizmetlerden yararlanmaya devam etmekle bu değişiklikleri de kabul etmiş sayılır."),
                  const SizedBox(height: 20),
                  _sectionTitle("10. TEBLİGAT"),
                  _sectionBody("İşbu Sözleşme ile ilgili taraflara gönderilecek olan tüm bildirimler, Şirketin bilinen e-posta adresi ve kullanıcının üyelik formunda belirttiği e-posta adresi vasıtasıyla yapılacaktır. Kullanıcı, üye olurken belirttiği adresin geçerli tebligat adresi olduğunu, değişmesi durumunda 7 gün içinde yazılı olarak diğer tarafa bildireceğini, aksi halde bu adrese yapılacak tebligatların geçerli sayılacağını kabul eder."),
                  const SizedBox(height: 20),
                  _sectionTitle("11. DELİL SÖZLEŞMESİ"),
                  _sectionBody("Taraflar arasında işbu sözleşme ile ilgili işlemler için çıkabilecek her türlü uyuşmazlıklarda Taraflar'ın defter, kayıt ve belgeleri ile ve bilgisayar kayıtları ve faks kayıtları 6100 sayılı Hukuk Muhakemeleri Kanunu uyarınca delil olarak kabul edilecek olup, kullanıcı bu kayıtlara itiraz etmeyeceğini kabul eder."),
                  const SizedBox(height: 20),
                  _sectionTitle("12. UYUŞMAZLIKLARIN ÇÖZÜMÜ"),
                  _sectionBody("İşbu Sözleşme'nin uygulanmasından veya yorumlanmasından doğacak her türlü uyuşmazlığın çözümünde İstanbul Anadolu Adliyesi Mahkemeleri ve İcra Daireleri yetkilidir."),
                  const SizedBox(height: 32),
                  const Text(
                    "ZECORNER HAUSBERRY GAYRİMENKUL VE BİLGİ TEKNOLOJİLERİ A.Ş.",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(238, 46, 36, 1)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(currentIndex: 4, onTap: (index) {}),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    ),
  );

  Widget _sectionBody(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
    ),
  );

  Widget _sectionList(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items.map((e) => Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 15, color: Colors.black87)),
          Expanded(child: Text(e, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6))),
        ],
      ),
    )).toList(),
  );
}

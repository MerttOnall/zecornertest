# API Örnekleri

Bu klasör, Flutter uygulamasının kullandığı backend API'ler için Next.js örnek dosyalarını içerir.

## update-contact.ts

**Kişi Düzenle** (myoffice_edit_screen, edit_person_screen) sayfasından güncelleme yapıldığında kullanılır.

### Flutter tarafı
- **Endpoint:** `POST http://3.77.159.125/api/zecorner/contact/{contactNo}?type=detail`
- **Headers:** X-SESSION, X-API-KEY, X-APP-ID, Content-Type, Accept
- **Body:** saveContact validation formatında (camelCase: name, surname, eMail, tel, detail, address, vb.)

### Next.js kurulumu
1. `update-contact.ts` dosyasını projenize kopyalayın
2. `pages/api/zecorner/contact/[no].ts` veya `app/api/zecorner/contact/[no]/route.ts` olarak yerleştirin
3. `saveContactValidation` ve `APIMiddleware` utility'lerinizin mevcut save contact API ile uyumlu olduğundan emin olun

### Not
Flutter uygulaması şu anda doğrudan `http://3.77.159.125` adresine istek atıyor. Eğer Next.js proxy kullanıyorsanız, Flutter'ın `.env` dosyasındaki base URL'i proxy adresinize yönlendirmeniz gerekir.

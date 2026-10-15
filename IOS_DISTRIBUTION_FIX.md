# iOS Distribution Sorunları Çözüm Rehberi

## Sorun 1: PLA Update Available

### Çözüm:
1. https://developer.apple.com/account adresine gidin
2. Apple Developer hesabınızla giriş yapın
3. Sol menüden **"Agreements, Tax, and Banking"** bölümüne gidin
4. Bekleyen anlaşmaları kontrol edin
5. Yeni Program License Agreement'i kabul edin
6. Gerekirse "Request Agreement" butonuna tıklayın

## Sorun 2: No signing certificate "iOS Distribution" found

### Çözüm Yöntem 1: Xcode ile Otomatik (Önerilen)

1. **Xcode'u açın** ve projenizi açın
2. Sol panelden **"Runner"** projesini seçin
3. **"Signing & Capabilities"** sekmesine gidin
4. **"Automatically manage signing"** işaretli olduğundan emin olun
5. **Team** dropdown'ından **"2FA3V6ZVMZ"** team'ini seçin
6. Eğer hata görüyorsanız:
   - Xcode menüsünden: **Xcode → Settings → Accounts**
   - Apple ID'nizi seçin
   - **"Download Manual Profiles"** butonuna tıklayın
   - Xcode'un sertifikaları indirmesini bekleyin

### Çözüm Yöntem 2: Manuel Sertifika Oluşturma

1. **Apple Developer Portal'a gidin:**
   - https://developer.apple.com/account/resources/certificates/list

2. **Yeni sertifika oluşturun:**
   - Sağ üstteki **"+"** butonuna tıklayın
   - **"iOS Distribution"** seçeneğini seçin
   - **"Continue"** butonuna tıklayın
   - Talimatları takip edin

3. **Sertifikayı indirin ve yükleyin:**
   - Oluşturulan sertifikayı indirin
   - İndirilen `.cer` dosyasına çift tıklayın
   - Keychain Access'e eklenecektir

4. **Provisioning Profile oluşturun:**
   - https://developer.apple.com/account/resources/profiles/list
   - **"+"** butonuna tıklayın
   - **"App Store"** seçeneğini seçin
   - Bundle ID'nizi seçin: `com.zeholding.zecorner.test`
   - Oluşturduğunuz Distribution sertifikasını seçin
   - Profile'ı indirin ve Xcode'a yükleyin

### Çözüm Yöntem 3: Keychain'deki Sertifikaları Kontrol Etme

1. **Keychain Access** uygulamasını açın (Applications → Utilities)
2. Sol panelden **"login"** keychain'ini seçin
3. **"My Certificates"** kategorisine gidin
4. **"iOS Distribution"** sertifikasının olup olmadığını kontrol edin
5. Eğer yoksa veya geçersizse, yukarıdaki yöntemlerden birini kullanın

## Genel Kontrol Listesi

- [ ] Apple Developer hesabında güncel PLA kabul edildi
- [ ] Xcode'da doğru Team seçili (2FA3V6ZVMZ)
- [ ] "Automatically manage signing" aktif
- [ ] iOS Distribution sertifikası mevcut ve geçerli
- [ ] Provisioning Profile mevcut ve geçerli
- [ ] Xcode yeniden başlatıldı

## Hala Sorun Yaşıyorsanız

1. **Xcode'u tamamen kapatın** ve yeniden açın
2. **Derived Data'yı temizleyin:**
   - Xcode → Settings → Locations
   - Derived Data yolunu açın ve klasörü silin
3. **Keychain'i temizleyin:**
   - Keychain Access → login keychain
   - Eski/geçersiz sertifikaları silin
4. **Xcode Command Line Tools'u güncelleyin:**
   ```bash
   xcode-select --install
   ```

## Notlar

- Team ID: **2FA3V6ZVMZ**
- Bundle ID: **com.zeholding.zecorner.test**
- Görünen ad: **Zecorner Test**
- Sürüm: **1.0.0 (1)**
- Minimum iOS Version: **15.0**

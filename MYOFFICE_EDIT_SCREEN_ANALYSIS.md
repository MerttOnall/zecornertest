# MyOffice Edit Screen - Detaylı Analiz Raporu

## 🔍 Tespit Edilen Sorunlar

### 1. ❌ MEVCUT BELGELERİN UI'DA GÖSTERİLMEMESİ

**Sorun:**
- `_existingDetailAttachments` listesi API'den yükleniyor ve file ID'leri (`_criminalRecordFileId`, `_diplomaFileId`, vb.) set ediliyor
- Ancak UI'da sadece yeni seçilen dosyalar (`_criminalRecordFile != null`) kontrol ediliyor
- Mevcut belgeler (`_criminalRecordFileId != null`) gösterilmiyor

**Etkilenen Alanlar:**
- Diploma (satır 3614-3699)
- Adli Sicil Kaydı (satır 3709-3816)
- Mesleki Yeterlilik Belgesi (satır 3838-3946)
- Taşınmaz Ticari Yetki Belgesi (satır 3965-4052)

**Kod Örneği:**
```dart
// Şu anki kod - sadece yeni dosya kontrolü
_criminalRecordFile != null
  ? Container(...) // Dosya gösteriliyor
  : InkWell(...)   // "Dosya seçiniz" gösteriliyor

// Olması gereken - mevcut dosya da kontrol edilmeli
(_criminalRecordFile != null || (_criminalRecordFileId != null && _criminalRecordFileId!.isNotEmpty))
  ? Container(...) // Dosya gösteriliyor
  : InkWell(...)   // "Dosya seçiniz" gösteriliyor
```

---

### 2. ❌ MEVCUT BELGELERİN SİLİNEMEMESİ

**Sorun:**
- `_removeDocument()` fonksiyonu sadece yeni seçilen dosyaları (`_criminalRecordFile`) siliyor
- Mevcut belgelerin ID'lerini (`_criminalRecordFileId`) temizlemiyor
- `_existingDetailAttachments` listesinden de kaldırmıyor

**Etkilenen Fonksiyon:**
- `_removeDocument()` (satır 1425-1448)

**Kod Örneği:**
```dart
// Şu anki kod
void _removeDocument(String documentType) {
  setState(() {
    switch (documentType) {
      case 'criminal_record':
        _criminalRecordFile = null; // Sadece yeni dosya siliniyor
        break;
      // ...
    }
  });
}

// Olması gereken
void _removeDocument(String documentType) {
  setState(() {
    switch (documentType) {
      case 'criminal_record':
        _criminalRecordFile = null;
        _criminalRecordFileId = null; // Mevcut dosya ID'si de silinmeli
        // _existingDetailAttachments'dan da kaldırılmalı
        break;
      // ...
    }
  });
}
```

---

### 3. ❌ BELGE GÖRÜNTÜLEME EKSİKLİĞİ

**Sorun:**
- Mevcut belgeler için URL oluşturulmuyor
- Sadece profil fotoğrafı için `ImageUtils.getProfileImageUrl()` kullanılıyor
- Belgeler için `ImageUtils.getS3FileUrl()` kullanılabilir ama kullanılmıyor

**Etkilenen Alanlar:**
- Tüm belge alanları (Diploma, Adli Sicil, Mesleki Yeterlilik, Taşınmaz Yetki)

**Çözüm:**
- Mevcut belgeler için URL oluşturulmalı ve gösterilmeli
- PDF görüntüleme için WebView veya PDF viewer kullanılmalı
- Veya en azından "Mevcut belge yüklü" mesajı gösterilmeli

---

### 4. ⚠️ VALIDATION İLE UI UYUMSUZLUĞU

**Sorun:**
- Validation mevcut belgeleri kontrol ediyor (satır 1317-1338)
- Ancak UI'da mevcut belgeler gösterilmiyor
- Kullanıcı belgeyi göremediği halde validation geçiyor

**Kod Örneği:**
```dart
// Validation (satır 1317-1326)
final hasCriminalRecord = _criminalRecordFile != null ||
    (_criminalRecordFileId != null && _criminalRecordFileId!.isNotEmpty) ||
    _existingDetailAttachments.any((a) =>
        (a['type'] ?? a['id'] ?? '').toString().toUpperCase().contains('CRIMINAL'));

// UI (satır 3709)
_criminalRecordFile != null // Sadece yeni dosya kontrol ediliyor!
```

---

### 5. ⚠️ FORM MODEL SENKRONİZASYONU

**Sorun:**
- Bazı alanlar controller'lara yazılıyor ama `_formModel`'e aktarılmıyor
- Örnek: `_selectedBirthPlace`, `_selectedMaritalStatus`, `_selectedBodySize` controller'lara yazılıyor ama form model'e aktarılmıyor

**Etkilenen Alanlar:**
- `_applyContactApiData()` (satır 234-325)
- `_applyOfficePersonApiData()` (satır 327-351)

---

### 6. ⚠️ İLÇE/MAHALLE YÜKLEME SORUNU

**Sorun:**
- `_loadDistrictsByProvince()` çağrılıyor ama `restoreAddress: true` durumunda mevcut seçimler restore edilmiyor
- İlçe seçildiğinde mahalleler yükleniyor ama mevcut mahalle seçimi restore edilmiyor

**Etkilenen Fonksiyon:**
- `_loadDistrictsByProvince()` (satır 519-574)

---

## ✅ ÖNERİLEN DÜZELTMELER

### 1. Mevcut Belgelerin UI'da Gösterilmesi

**Yapılacaklar:**
- Her belge alanında hem yeni dosya hem de mevcut dosya ID kontrolü yapılmalı
- Mevcut belgeler için "Mevcut belge yüklü" mesajı gösterilmeli
- Mevcut belgeler için görüntüleme/indirme butonu eklenmeli

**Örnek Kod:**
```dart
// Mevcut belge kontrolü için helper fonksiyon
bool _hasDocument(String documentType) {
  switch (documentType) {
    case 'criminal_record':
      return _criminalRecordFile != null || 
             (_criminalRecordFileId != null && _criminalRecordFileId!.isNotEmpty);
    case 'professional_certificate':
      return _professionalCertificateFile != null || 
             (_professionalCertificateFileId != null && _professionalCertificateFileId!.isNotEmpty);
    // ...
  }
}

// UI'da kullanım
_hasDocument('criminal_record')
  ? _buildDocumentDisplay('criminal_record')
  : _buildDocumentPicker('criminal_record')
```

---

### 2. Mevcut Belgelerin Silinmesi

**Yapılacaklar:**
- `_removeDocument()` fonksiyonu mevcut dosya ID'lerini de temizlemeli
- `_existingDetailAttachments` listesinden de kaldırmalı

**Örnek Kod:**
```dart
void _removeDocument(String documentType) {
  setState(() {
    switch (documentType) {
      case 'criminal_record':
        _criminalRecordFile = null;
        _criminalRecordFileId = null;
        _criminalRecordError = null;
        // _existingDetailAttachments'dan kaldır
        _existingDetailAttachments.removeWhere((a) =>
          (a['type'] ?? a['id'] ?? '').toString().toUpperCase().contains('CRIMINAL'));
        break;
      // ...
    }
  });
}
```

---

### 3. Belge Görüntüleme

**Yapılacaklar:**
- Mevcut belgeler için URL oluşturulmalı (`ImageUtils.getS3FileUrl()`)
- PDF görüntüleme için WebView veya PDF viewer kullanılmalı
- Veya en azından "Mevcut belge yüklü - Görüntüle" butonu eklenmeli

**Örnek Kod:**
```dart
Widget _buildExistingDocument(String documentType, String fileId) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Row(
      children: [
        Icon(Icons.description, color: Colors.green),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mevcut belge yüklü', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('Görüntülemek için tıklayın', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.visibility),
          onPressed: () {
            // PDF görüntüleme veya indirme
            final url = ImageUtils.getS3FileUrl(fileId);
            // WebView veya PDF viewer aç
          },
        ),
        IconButton(
          icon: Icon(Icons.close, color: Colors.red),
          onPressed: () => _removeDocument(documentType),
        ),
      ],
    ),
  );
}
```

---

### 4. Form Model Senkronizasyonu

**Yapılacaklar:**
- `_applyContactApiData()` ve `_applyOfficePersonApiData()` fonksiyonlarında form model'e de değerler aktarılmalı
- Özellikle `_selectedBirthPlace`, `_selectedMaritalStatus`, `_selectedBodySize` gibi alanlar

---

### 5. İlçe/Mahalle Yükleme

**Yapılacaklar:**
- `_loadDistrictsByProvince()` fonksiyonunda `restoreAddress: true` durumunda mevcut seçimler restore edilmeli
- İlçe seçildiğinde mevcut mahalle seçimi de restore edilmeli

---

## 📋 ÖNCELİK SIRASI

1. **YÜKSEK ÖNCELİK:**
   - Mevcut belgelerin UI'da gösterilmesi
   - Mevcut belgelerin silinmesi
   - Validation ile UI uyumsuzluğunun düzeltilmesi

2. **ORTA ÖNCELİK:**
   - Belge görüntüleme özelliği
   - Form model senkronizasyonu

3. **DÜŞÜK ÖNCELİK:**
   - İlçe/Mahalle yükleme iyileştirmesi

---

## 🔧 UYGULAMA ADIMLARI

1. Helper fonksiyonlar ekle (`_hasDocument()`, `_buildExistingDocument()`)
2. `_removeDocument()` fonksiyonunu güncelle
3. UI widget'larını güncelle (her belge alanında mevcut belge kontrolü)
4. Form model senkronizasyonunu düzelt
5. İlçe/Mahalle yükleme iyileştirmesi

---

## 📝 NOTLAR

- `ImageUtils.getS3FileUrl()` fonksiyonu mevcut ve belgeler için kullanılabilir
- `_existingDetailAttachments` listesi API'den geliyor ve doğru formatlanmış görünüyor
- Validation mantığı doğru ama UI ile uyumsuz

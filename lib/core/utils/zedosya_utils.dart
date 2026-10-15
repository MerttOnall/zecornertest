/// ZeDosya dosya türü ve kategori yardımcıları.
class ZeDosyaUtils {
  ZeDosyaUtils._();

  static const documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
  ];

  static const imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  static const allPickExtensions = [...documentExtensions, ...imageExtensions];

  static String extensionOf(String pathOrName) {
    final dot = pathOrName.lastIndexOf('.');
    if (dot <= 0 || dot >= pathOrName.length - 1) return '';
    return pathOrName.substring(dot + 1).toLowerCase();
  }

  /// API `sub_title` alanı (word, excel, png, pdf …).
  static String subTitleFromFileName(String fileName) {
    switch (extensionOf(fileName)) {
      case 'doc':
      case 'docx':
        return 'word';
      case 'xls':
      case 'xlsx':
        return 'excel';
      case 'png':
        return 'png';
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'pdf':
        return 'pdf';
      case 'ppt':
      case 'pptx':
        return 'powerpoint';
      default:
        return extensionOf(fileName).isEmpty ? 'other' : extensionOf(fileName);
    }
  }

  /// Liste filtresi kategori adı → API category id.
  static int filterCategoryToId(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'word':
        return 1;
      case 'excel':
        return 2;
      case 'png':
        return 5;
      default:
        return 0;
    }
  }

  /// Form kategorisi → API category id.
  static int formCategoryToId(String? categoryName) {
    switch (categoryName) {
      case 'Sözleşme':
        return 1;
      case 'Form':
        return 2;
      case 'Rapor':
        return 3;
      case 'Diğer':
        return 4;
      default:
        return 0;
    }
  }

  static String? formCategoryFromId(int categoryId) {
    switch (categoryId) {
      case 1:
        return 'Sözleşme';
      case 2:
        return 'Form';
      case 3:
        return 'Rapor';
      case 4:
        return 'Diğer';
      default:
        return null;
    }
  }
}

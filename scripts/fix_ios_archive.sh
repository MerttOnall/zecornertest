#!/bin/bash
# Xcode "Could not build module" (CoreFoundation, Darwin, UIKit, unistd/gethostuuid.pcm vb.)
# ve "file too small to contain AST file magic" hatalarını giderir.
# Bozuk önbellek (ModuleCache .pcm) silinip pod'lar yeniden kurulur.
# Kullanım: ./scripts/fix_ios_archive.sh

set -e
cd "$(dirname "$0")/.."
echo "=== Zecorner iOS Archive Düzeltme ==="
echo ""

# Xcode açıksa dosyalar kilitli kalır; temizlik işe yaramaz.
if pgrep -x Xcode >/dev/null 2>&1; then
  echo "HATA: Xcode şu an açık. Script'i çalıştırmak için:"
  echo "  1. Xcode'u tamamen KAPATIN (Xcode → Quit Xcode)."
  echo "  2. Bu script'i tekrar çalıştırın: ./scripts/fix_ios_archive.sh"
  echo ""
  exit 1
fi

echo "Not: 'No space left on device' alıyorsanız diskte en az 10-15 GB boş alan açın."
echo ""

DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
MODULE_CACHE="$DERIVED/ModuleCache.noindex"

echo "1. Xcode önbelleği siliniyor (bozuk .pcm / ModuleCache dahil)..."
rm -rf "$DERIVED"/*
# Bozuk gethostuuid-*.pcm ve diğer modül önbelleği bu dizinde
[ -d "$MODULE_CACHE" ] && rm -rf "$MODULE_CACHE"
echo "   Tamamlandı."

echo ""
echo "2. Flutter temizleniyor..."
flutter clean
flutter pub get
echo "   Tamamlandı."

echo ""
echo "3. iOS Pods kaldırılıp yeniden kuruluyor..."
cd ios
rm -rf Pods Podfile.lock .symlinks build
if command -v pod &>/dev/null; then
  pod install --repo-update
else
  echo "   UYARI: 'pod' bulunamadı. CocoaPods yüklü olmalı: sudo gem install cocoapods"
  exit 1
fi
cd ..
echo "   Tamamlandı."

echo ""
echo "=== Bitti. Şimdi: ==="
echo "  • Xcode'u KAPATIP yeniden açın."
echo "  • Projeyi ios/Runner.xcworkspace dosyasından açın (.xcodeproj DEĞİL)."
echo "  • Product → Clean Build Folder (Shift+Cmd+K)."
echo "  • Product → Archive ile archive alın."
echo ""
echo "Xcode'dan archive alırken: Üstteki cihaz seçiciden 'Any iOS Device' seçili olmalı (My Mac DEĞİL)."
echo ""
echo "Terminalden archive almak için (hedef iOS, provisioning hatası önlenir):"
echo "  cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -destination 'generic/platform=iOS' -archivePath build/Runner.xcarchive archive"
echo ""

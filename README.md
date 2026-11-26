# Namaz Vakti

iPhone, ana ekran ve kilit ekranı widget'ları, canlı etkinlik (Dynamic Island) ve Apple Watch için namaz vakti uygulaması.
Vakitler cihazda, Diyanet (Türkiye) yöntemiyle hesaplanır ([Adhan](https://github.com/batoulapps/adhan-swift) kütüphanesi). Uygulama Türkçe, İngilizce ve Almanca destekler.

## Projeyi Mac'te açmak

1. Xcode 16 veya üstünü App Store'dan kur.
2. Terminal'de XcodeGen'i kur: `brew install xcodegen` (Homebrew yoksa: https://brew.sh)
3. Proje klasöründe: `xcodegen generate`
4. Oluşan `NamazVakti.xcodeproj` dosyasını çift tıklayarak Xcode'da aç.

## Kendi iPhone'unda denemek

1. Xcode › Settings › Accounts bölümünde Apple ID'nle giriş yap.
2. Sol üstte **NamazVakti** projesini seç. Dört hedefin (NamazVakti, NamazVaktiWidgets, NamazVaktiWatch, NamazVaktiWatchWidgets) her birinde **Signing & Capabilities › Team** alanından ekibini seç.
   Kalıcı olsun istersen `project.yml` içindeki `DEVELOPMENT_TEAM` satırına Team ID'ni yaz ve `xcodegen generate` komutunu tekrar çalıştır.
3. iPhone'u kabloyla bağla, üstteki cihaz listesinden seç ve ▶︎ (Run) tuşuna bas.
4. İlk seferde iPhone'da Ayarlar › Genel › VPN ve Cihaz Yönetimi'nden geliştirici sertifikana güven.

## App Store'da yayınlamak

1. **App Store Connect › Uygulamalar › +** ile yeni uygulama oluştur. Paket kimliği: `com.kadiratilgan.namazvakti`, ana dil: Türkçe.
2. Xcode'da üstten **Any iOS Device (arm64)** seç, sonra **Product › Archive**.
3. Arşiv penceresinde **Distribute App › App Store Connect › Upload**.
4. App Store Connect'te derlemeyi önce **TestFlight** ile kendi cihazlarında dene, sonra sürüm sayfasında seçip incelemeye gönder.

Yayın öncesi kontrol listesi `YAYIN.md` dosyasında.

## Yapı

| Klasör | İçerik |
| --- | --- |
| `Shared/` | Vakit hesaplama, ortak depolama, dil, tema, günün içeriği, widget zaman çizelgesi, çeviri kataloğu |
| `App/` | iPhone uygulaması: ekranlar, bildirimler, konum, canlı etkinlik, Siri kısayolları |
| `Widgets/` | Ana ekran ve kilit ekranı widget'ları, canlı etkinlik görünümü |
| `Watch/`, `WatchWidgets/` | Apple Watch uygulaması ve saat yüzü komplikasyonları |
| `project.yml` | XcodeGen proje tanımı |

## Ezan sesi

Bildirimlerde ezan sesi için `ezan.caf` (en fazla 30 sn) ve `ezan_kisa.caf` dosyalarını `App/` klasörüne ekle. Ses dosyalarının kullanım hakkına sahip olmalısın. Dosyalar yoksa iPhone'un standart bildirim sesi çalar.

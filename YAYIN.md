# App Store yayın kontrol listesi

## 1. Bir kez yapılacaklar (Apple Developer hesabı)

- [ ] Apple Developer Program üyeliği aktif (yıllık 99 USD).
- [ ] App Store Connect › Business: **Free Apps** sözleşmesi kabul edilmiş (ücretsiz uygulama için ayrıca ödeme sözleşmesi gerekmez).
- [ ] App Store Connect › Business › **Digital Services Act**: Uygulamadan gelir yoksa "Ticari satıcı değilim" seçilebilir. Bunun sana uyup uymadığını kendin değerlendirmelisin.
- [ ] Xcode › Settings › Accounts: Apple ID eklendi, ekip (team) görünüyor.

## 2. Proje ayarları

- [ ] `project.yml` içinde `DEVELOPMENT_TEAM` alanına Team ID yazıldı ve `xcodegen generate` çalıştırıldı
      (ya da Xcode'da dört hedefin her birinde Signing & Capabilities › Team seçildi).
- [ ] İlk derlemede Xcode, **App Group** (`group.com.kadiratilgan.namazvakti`) ve **Time Sensitive Notifications** yeteneklerini otomatik oluşturur. Hata verirse developer.apple.com › Identifiers bölümünden App Group'u elle ekle.
- [ ] `App/Views/AyarlarView.swift` içindeki `LegalInfo` alanları (ad soyad, adres, e-posta) gerçek bilgilerle dolduruldu. Almanya'dan yayında Künye (Impressum) zorunludur.
- [ ] İstenirse ezan sesleri (`ezan.caf`, `ezan_kisa.caf`) `App/` klasörüne eklendi (kullanım hakkı sende olmalı).

## 3. App Store Connect'te uygulama kaydı

- [ ] Uygulamalar › + › Yeni Uygulama: platform iOS, ad "Namaz Vakti" (alınmışsa ör. "Namaz Vakti – Ezan & Kıble"), ana dil Türkçe, paket kimliği `com.kadiratilgan.namazvakti`, SKU `namazvakti-001`.
- [ ] Kategori: **Yaşam Tarzı** (Lifestyle), ikinci kategori: Başvuru (Reference).
- [ ] Yaş sınırı anketi: tüm sorulara "Hayır" → 4+.
- [ ] Fiyat: Ücretsiz. Uygun ülkeler: tümü.
- [ ] **Gizlilik politikası URL'si** girildi (zorunlu). Uygulamadaki gizlilik metni bir web sayfasına konmalı (ör. GitHub Pages ya da kendi siten).
- [ ] **App Gizliliği** (App Privacy): "Veri toplanmıyor" (Data Not Collected). Konum yalnızca cihazda kullanılıyor ve sunucuya gönderilmiyor.

## 4. Mağaza sayfası (Türkçe, İngilizce, Almanca)

- [ ] Ekran görüntüleri: 6,9" iPhone (1320 × 2868) en az 3 adet. Apple Watch için de en az 1 adet.
- [ ] Açıklama, anahtar kelimeler, destek URL'si.
- [ ] Taslak metinler aşağıda.

**Alt başlık (TR):** Vakitler, kıble, zikir ve Ramazan
**Anahtar kelimeler (TR):** ezan,namaz,vakit,kıble,imsakiye,ramazan,zikirmatik,tesbih,diyanet,cami,iftar,sahur

**Açıklama (TR):**
Namaz Vakti, bulunduğun yere göre Diyanet yöntemiyle hesaplanan namaz vakitlerini sade ve şık bir tasarımla sunar.
• Sıradaki vakte canlı geri sayım, kilit ekranında ve Dynamic Island'da
• Ana ekran ve kilit ekranı widget'ları, Apple Watch komplikasyonları
• Her vakit için ayrı bildirim, hatırlatma ve "vakit çıkmadan" uyarısı
• Namaz takibi, seri ve kaza sayacı
• Ramazan modu: imsakiye, sahur ve iftar geri sayımı, oruç takibi
• Kıble pusulası, yakındaki camiler, zikirmatik ve tesbihat rehberi
• Günün ayeti, hadisi ve duası
• Türkçe, İngilizce ve Almanca; açık ve koyu tema
Konumun cihazından çıkmaz, reklam ve takip yoktur.

## 5. Derleme ve gönderme

- [ ] `project.yml` içinde `MARKETING_VERSION` (ör. 1.0.0) ve her yüklemede artan `CURRENT_PROJECT_VERSION`.
- [ ] Xcode: hedef cihaz **Any iOS Device (arm64)** → Product › **Archive** → Distribute App › **App Store Connect** › Upload.
- [ ] TestFlight'ta iç test: bildirimler, widget'lar, canlı etkinlik, saat uygulaması, üç dil.
- [ ] Sürüm sayfasında derlemeyi seç → **İncelemeye Gönder**.

**İnceleme notu (App Review Information › Notes) için öneri:**
> The app calculates prayer times on-device (Diyanet method, Adhan library). Location is used only on device for prayer times, Qibla and travel mode; no data is collected or sent to a server. "Always" location permission is optional and only requested if the user enables background travel mode. Live Activity shows the countdown to the next prayer. No login required.

## 6. Bilinen sınırlar (sonraki sürümler için)

- Ramazan ve kandil tarihleri Ümmü'l-Kurâ takvimiyle hesaplanır; Diyanet'in ilan ettiği tarihlerden bir gün farklı olabilir.
- Canlı etkinlik, uygulama açıldığında ve arka plan yenilemesinde güncellenir (sunucu tabanlı push bildirimi yok).
- Apple Watch kendi konumunu ve kayıtlarını kullanır; iPhone ile kayıt eşitlemesi sonraki sürüme bırakıldı.
- Günün içeriği şimdilik 7 ayet, 7 hadis ve 7 dua ile döner; yayından önce metinleri bir din görevlisine kontrol ettir ve listeyi genişlet.

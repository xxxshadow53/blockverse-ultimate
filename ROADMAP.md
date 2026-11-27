# BLOCKVERSE – Yol Haritası

Bu belge, demo sürümde **gerçekten bulunan** ile **planlanan** özellikleri açıkça ayırır.
Doğrulanmadan tamamlandığı iddia edilen hiçbir özellik burada listelenmez.

## Demo sürümde doğrulanan (v1.0.0-demo)

- 40 blok türü, 12 biyom tanımı ve seed'li prosedürel dünya üretimi.
- 16×16 chunk, 256 blok yükseklik,WorkerThreadPool ile arka plan üretimi, greedy meshing.
- 6 seçilebilir karakter, `Skeleton3D` tabanlı prosedürel rig ve 11 animasyon durumu.
- Gerçek CharacterBody3D fiziği, 1./3. şahıs kamera, voksel DDA ışın izleme ile kırma/koyma.
- 4 aktif düşman (zombi, iskelet, kurt, golem), AI, mesafe saldırısı, hasar ve drop.
- Envanter, üretim (crafting), kayıt/yükleme, görev sayacı.
- Çoklu dokunmalı mobil kontroller (yuvarlak analog joystick + aksiyon tuşları).
- Türkçe menüler: ana menü, karakter seçimi, dünya seçimi, ayarlar, oyun içi menüler.
- Grafik profilleri (Düşük/Orta/Yüksek-Ultra/Otomatik), ses ve kontrol ayarları.
- Başsız smoke test: 14/14 kontrol geçiyor (bkz. `tests/smoke_test.gd`).
- Gerçek çalışan oyundan alınmış ekran görüntüleri: `screenshots/`.
- `BlockVerse-Ultimate-Demo.apk` hem yerel hem GitHub Actions CI'da derlenip `apksigner` ile doğrulandı:
  ARM64 (`arm64-v8a`) native kütüphane, `com.blockverse.ultimate`, sürüm `1.0.0-demo`,
  yalnızca `VIBRATE` izni (INTERNET izni yok), v2/v3 imza şemaları geçerli.
  CI çalıştırması başarılı (`success`) ve artifact indirilerek aynı APK doğrulandı.

## Planlanan (henüz yapılmadı)

| Özellik | Durum | Not |
| --- | --- | --- |
| 12 biyomun tamamı için özgün yapı/props seti | Kısmi | 12 biyom üretiliyor; yapı çeşitleri (köy, tapınak, kale, köprü vs.) temel geometriyle sınırlı. |
| Kalan 6 düşman (ateş yaratığı, ejderha, köylü, hayvan, patron, örümcek) | Tanımlı, spawn edilmiyor | `EnemyDefs.TYPES` içinde `demo: false`. |
| Hayvan evcilleştirme, köylü ticareti, boss savaşı | Yok | Yol haritası maddesi. |
| Çok oyunculu / sunucu | Yok | Ücretsiz, çevrimdışı odak korunacak. |
| Gerçek cihazda FPS/termal ölçümü | Yapılmadı | Yalnızca masaüstü headless doğrulama yapıldı; performans iddiası yok. |
| Google Play release imzalı AAB | Yapılmadı | Demo yalnızca debug imzalı APK. |
| Müzik/varlık paketi | Yok | Tüm ses/doku çalışma zamanında prosedürel üretiliyor. |

## Bilinen kısıtlar

- Yerel APK derlemesi Godot export şablonları, JDK 17 ve Android SDK gerektirir; GitHub Actions iş akışı bunları CI'da kurar.
- Debug keystore yalnızca CI sırasında `keytool` ile üretilir; depoda gizli anahtar/keystore bulunmaz.
- Oyun çevrimdışıdır; internet izni kapalıdır, zorunlu API/abonelik yoktur.
- ObjectDB sızıntısı uyarısı yalnızca headless test sürecinin kapanışında görünür; oyun oturumunu etkilemez.

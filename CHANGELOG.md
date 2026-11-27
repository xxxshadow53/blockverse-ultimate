# Değişiklik Günlüğü

## 1.0.0-demo

- İlk oynanabilir vertical slice: prosedürel 3D voxel dünya, 6 karakter, 4 aktif düşman.
- Chunk üretiminde `WorkerThreadPool` sonuçlarının doğru şekilde toplanması düzeltildi.
- Greedy meshing, tüm 256 blok yüksekliğini kapsayacak ve yüzey normal/çarpışma yönleri doğru olacak şekilde düzeltildi.
- Spawn, spawn chunk'ı yüklenene kadar bekleyecek şekilde düzeltildi; oyuncu artık yüzeyde spawn oluyor.
- `spawn_pickup` çağrısında sahne ağacı dışı `global_position` hatası giderildi.
- Gerçek oyun oturumu smoke testi eklendi: dünya, spawn, kırma/koyma, savaş, üretim, kayıt ve menüler (14 kontrol).
- Gerçek çalışan oyundan 4 ekran görüntüsü alındı (`screenshots/`).
- Android ARM64 debug APK export preset'i ve GitHub Actions iş akışı eklendi.
- Android export için ETC2/ASTC doku sıkıştırması etkinleştirildi; ARM64 debug APK yerel olarak derlenip `apksigner` ile doğrulandı.
- GitHub Actions ARM64 APK iş akışı düzeltildi (SDK yolu, temiz checkout için Godot import); başarılı CI çalıştırmasından `BlockVerse-Ultimate-Demo.apk` artifact'ı indirilip doğrulandı.
- Mobil kasma düzeltmeleri: kır/koyma dokunuşu artık chunk rebuild'ini kuyruğa alıyor; görünür chunk sayısı 97→37, fizik 60→30 Hz, gölge/bloom varsayılan kapalı, ışık/HUD/minimap güncellemeleri seyreltildi, doku atlası tek seferde ham bayt yazımıyla üretiliyor.
- Samsung SM-S200 / SM-X200 / SM-T200 ve benzer zayıf tabletler için otomatik olarak en hafif profil zorlanıyor: 9 chunk, 24 FPS, 0.60 ölçek, sis/bulut/parçacık/normal harita kapalı, 1 düşman; ses sentezi de kısaltıldı.
- Spawn chunk köşesinden chunk içindeki güvenli bir noktaya taşındı; kayıtlı konum blok içindeyse otomatik kurtarma yapılıyor. Kamera blok içine girerse ışın oyuncu gözünden başlıyor; duraklatma menüsüne "Güvenli Noktaya Dön" eklendi.


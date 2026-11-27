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


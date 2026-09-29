# 🌍 Akıllı Seyahat Ajandası ve Rota Planlayıcı (Smart Travel Planner)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-State%20Management-blue?style=for-the-badge)
![Hive](https://img.shields.io/badge/Hive-NoSQL%20Database-orange?style=for-the-badge)

Geleneksel harita uygulamalarının ötesine geçerek, elektrikli araç (EV) sahipleri ve seyahat tutkunları için **Clean Architecture** prensipleriyle geliştirilmiş akıllı navigasyon ve oyunlaştırma asistanı.


## ✨ Temel Özellikler (Features)

*   🔋 **Esnek EV (Elektrikli Araç) Modu:** Araç verilerine (Batarya kapasitesi, ortalama tüketim) ve anlık şarj durumuna göre dinamik menzil hesaplaması. Şarjın yetersiz olduğu durumlarda rota üzerindeki en uygun istasyonları haritaya yansıtma ve rotayı yeniden hesaplama.
*   🏆 **Zaman Kapsülü ve Oyunlaştırma (Geofencing):** Ziyaret edilen konumlara yaklaşıldığında GPS üzerinden (Geolocator) açılan kilitli şehir rozetleri. Açılan rozetlerin içine `ImagePicker` ile cihaz galerisinden fotoğraf ve anı ekleme imkanı.
*   🧭 **Dinamik Kamera Takibi (Observer Pattern):** Kullanıcı hareket ettikçe `Riverpod` üzerinden dinlenen konum verisiyle Google Maps kamerasının rotayı 3D perspektifte otomatik takip etmesi.
*   ⏳ **Akıllı ETA (Tahmini Varış Süresi):** Sadece harita mesafesi değil, seçilen seyahat moduna (Sürüş/Yürüyüş) göre güncellenen dinamik varış süresi hesaplaması.

## 🏗️ Mimari ve Teknolojiler (Tech Stack)

Proje, sürdürülebilirliği sağlamak ve kod karmaşasını önlemek adına **Modüler Klasör Yapısı** ile inşa edilmiştir. UI (Arayüz), Business Logic (İş Mantığı) ve Data (Veri) katmanları birbirinden izole edilmiştir.

*   **Çerçeve (Framework):** Flutter
*   **Durum Yönetimi (State Management):** Riverpod (Provider, StateNotifier)
*   **Yerel Veritabanı:** Hive (NoSQL, TypeAdapters, HiveList ilişkisel veri yapısı)
*   **Harita ve Konum Servisleri:** Google Maps Flutter API, Geolocator
*   **Donanım İzinleri:** Image Picker (Kamera/Galeri), Permission Handler

## 📂 Proje Klasör Yapısı

```text
lib/
 ├── core/           # Tema, sabitler (constants), hata yönetimi ve utils
 ├── features/       # Uygulamanın ana modülleri (Feature-First Architecture)
 │    ├── map/       # Google Maps entegrasyonu, kamera takibi
 │    ├── ev_mode/   # Menzil hesaplama algoritmaları
 │    └── capsule/   # Rozet sistemi ve resim ekleme mantığı
 ├── shared/         # Ortak widget'lar (CustomBottomNavBar vb.)
 └── main.dart       # ProviderScope ve uygulama başlangıcı

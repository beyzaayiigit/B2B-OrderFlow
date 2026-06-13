# Uygulama Yol Haritası — TextileFlow

Bu dosya, projenin uçtan uca uygulama kontrol listesidir. İşaretler mevcut durumu yansıtır
(`[x]` tamamlandı, `[ ]` açık/opsiyonel).

## 1) Proje Kurulumu

- [x] Üst klasör yapısı: `frontend/`, `backend/`, `database/`, `prodocs/`
- [x] Flutter projesi (`frontend`) oluşturuldu
- [x] Android emülatörde çalıştırma
- [ ] iOS simülatörde çalıştırma (macOS ortamı gerekir; demo kapsamı dışında)
- [x] Temel bağımlılıklar: `flutter_riverpod`, `go_router`, `supabase_flutter`, `flutter_dotenv`, `firebase_messaging`, `excel_community`

## 2) Mühendislik Standartları

- [x] Sıkı lint (`flutter_lints`) etkin
- [x] Özellik-öncelikli klasör yapısı (`presentation` / `application` / `domain` / `data`)
- [x] Supabase anahtarları için `.env` stratejisi
- [ ] CI iş akışı (analyze + test + build) — opsiyonel

## 3) Önce Tasarım Sistemi

- [x] Renk token'ları (Palet 2 — `AppColors`)
- [x] Tipografi, boşluk ve radius ölçeği
- [x] Yeniden kullanılabilir bileşenler: butonlar (anlamsal), giriş alanı, kart, durum rozeti, zaman çizelgesi
- [x] Tasarım sistemi dokümanı (`DesignSystem.md`)

## 4) Backend

- [x] Migration'lar (`001..012`) + RLS politikaları
- [x] Enum'lar: `order_status`, `production_stage`, `update_entry_kind`
- [x] Edge Functions: `send-push`, `generate-order-excel`
- [x] Sipariş kodu dizisi (`SPRS-…`)
- [ ] (Demo kurulumu) Supabase projesinde migration + policy + seed çalıştır
- [ ] (Demo kurulumu) Auth kullanıcılarını oluştur ve seed UID'lerini yaz

## 5) Özellik Teslim Sırası

### Faz A: Kimlik + Navigasyon
- [x] Giriş sayfası
- [x] Oturum geri yükleme
- [x] Role göre route guard

### Faz B: Katalog
- [x] Katalog listesi + arama/filtre
- [x] Model detay
- [x] Görsel yoksa kategori/renk bazlı placeholder

### Faz C: Sipariş Oluşturma
- [x] Matris widget + toplam hesaplama
- [x] Not + termin tarihi alanları
- [x] Sipariş gönderme
- [x] AI ile sipariş notu düzenleme

### Faz D: Sipariş Yönetimi
- [x] Alıcı sipariş listesi/detayı
- [x] Üretici sipariş listesi/detayı
- [x] Durum güncellemeleri
- [x] Güncelleme talebi + onay/geri bildirim akışı
- [x] Durum zaman çizelgesi / olay logu
- [x] AI ile talep metni düzenleme

### Faz E: Dışa Aktarım + Bildirim + Cilalama
- [x] Excel dışa aktarım (detaydan)
- [x] Push bildirimleri (FCM)
- [x] Boş/yükleniyor/hata durumları
- [x] Form doğrulama ve UX cilalama

## 6) Tamamlanma Tanımı (MVP)

- [x] Android (APK) build alınır
- [ ] Web build deploy edilir
- [x] Role göre yetkiler doğrulandı
- [x] Matris hesapları doğru
- [x] Talep akışı uçtan uca test edildi
- [x] Excel üretimi gerçek siparişlerde çalışıyor
- [x] Geçmiş siparişler kalıcı olarak görünür

## 7) Teslim (Bootcamp)

- [ ] Ekran görüntülü `README`
- [ ] GitHub push (`frontend`, `backend`, `prodocs`)
- [ ] Web deploy + APK
- [ ] Demo video

## 8) Notlar

- Bu depo canlı müşteri uygulamasından tamamen ayrıdır; markalama nötrdür (TextileFlow + Demo Alıcı / Demo Üretici).
- Hassas anahtarlar `.env` üzerinden yönetilir ve repoya girmez.

# Ürün Gereksinim Dokümanı (PRD) — TextileFlow

## 1) Ürün Özeti

TextileFlow, tekstil sektöründe iki firma arasındaki sipariş akışını dijitalleştiren bir B2B mobil/web uygulamasıdır:
- **Alıcı** (demo: "Demo Alıcı") — sipariş veren taraf.
- **Üretici** (demo: "Demo Üretici") — siparişi üreten taraf.

Uygulama, dağınık (ör. WhatsApp/Excel üzerinden) sipariş iletişimini standartlaştırır ve şu süreçleri tek yerde toplar:
- Model kataloğu
- Renk/beden matrisi ile sipariş oluşturma
- Sipariş durumu takibi
- Güncelleme talebi (revizyon) akışı
- Excel dışa aktarımı

Tek bir Flutter kod tabanı Android ve web üzerinde çalışır.

> Not: Bu depo, canlı müşteri uygulamasından tamamen ayrılmış bir **demo/eğitim** sürümüdür. Markalama nötrdür (TextileFlow + Demo Alıcı / Demo Üretici).

---

## 2) Hedef Kitle

TextileFlow, tekstil B2B tedarik zincirinde **alıcı marka** ile **üretici atölye/fabrika** arasındaki sipariş iletişimini dijitalleştirir. Demo sürümünde roller nötr isimlerle temsil edilir (Demo Alıcı / Demo Üretici).

### Alıcı tarafı (marka / tedarik operasyonu)
- **Kim:** Alıcı firmada sipariş oluşturan, takip eden operasyon sorumlusu veya satın alma/tedarik koordinatörü.
- **Bağlam:** Sezonluk veya tekrarlayan model siparişleri; renk-beden kırılımı ve termin kritik.
- **Teknoloji alışkanlığı:** WhatsApp, Excel, e-posta ile dağınık iletişim; mobilde hızlı aksiyon beklentisi.

### Üretici tarafı (atölye / fabrika)
- **Kim:** Üretici firmada gelen siparişleri onaylayan, üretime alan ve sevk eden üretim/planlama sorumlusu.
- **Bağlam:** Aynı anda birden fazla alıcı siparişi; net matris ve durum bilgisi olmadan planlama zorlaşır.
- **Teknoloji alışkanlığı:** Excel şablonları, telefon mesajları; katalog ve sipariş geçmişine tek yerden erişim ihtiyacı.

---

## 3) Pain & Gain

### Pain (mevcut sorunlar)
| Pain | Etkilenen | Sonuç |
|---|---|---|
| Siparişler WhatsApp/Excel ile dağınık iletiliyor | Alıcı + üretici | Yanlış anlaşılma, eksik beden/adet, geri dönüş maliyeti |
| Sipariş durumu tek kaynakta görünmüyor | Alıcı | "Üretimde mi, sevk oldu mu?" için sürekli mesaj/arama |
| Güncelleme talepleri kayıt dışı kalıyor | Alıcı + üretici | Kim ne istedi, onaylandı mı belirsiz; sevk öncesi çakışma |
| Serbest metin notlar üreticide net okunmuyor | Üretici | Üretim hatası veya gecikme riski |
| Geçmiş siparişlere güvenilir erişim yok | Her iki taraf | Tekrar sipariş veya denetimde sürtünme |

### Gain (TextileFlow ile kazanım)
| Gain | Nasıl sağlanır |
|---|---|
| Standart matris sipariş | Renk × beden formu, anlık toplam, `SPRS-` kodlu kayıt |
| Tek ekrandan takip | Durum zaman çizelgesi, kalıcı geçmiş, rol bazlı listeler |
| Kayıtlı talep akışı | `buyer_request` → `producer_approval` / `producer_feedback`; açık talep varken sevk engeli |
| Net iletişim metni | Gemini destekli not/talep düzenleme (API üzerinden) |
| Operasyonel bildirim | Push: yeni sipariş, durum değişimi, talep/yanıt |
| Paylaşılabilir çıktı | Sipariş özeti Excel dışa aktarımı |

---

## 4) Platform ve Teknoloji Kararları

- **İstemci:** Flutter (Dart) — Android + Web
- **Durum yönetimi:** Riverpod, navigasyon: `go_router`
- **Backend:** Supabase
  - PostgreSQL + Row Level Security (RLS)
  - Auth (e-posta/şifre)
  - Storage (katalog görselleri)
  - Edge Functions (push gönderimi, Excel üretimi)
- **Bildirim:** Firebase Cloud Messaging (FCM)
- **AI yardımcısı:** FastAPI + Google Gemini (sipariş notu / talep metni düzenleme)

Önemli kapsam notları:
- **Sipariş geçmişi kalıcıdır.** Süre bazlı (7 gün) otomatik temizlik kapsam dışıdır.
- Dışa aktarım **Excel** formatındadır (PDF değil).
- Push bildirimleri uygulamada **etkindir**.

Ayrıntılı sürümler için bkz. `tech-stack.md`.

---

## 5) Kullanıcı Rolleri ve Yetkiler

### 5.1 Alıcı
Yapabilir:
- Kataloğu görüntüleme
- Matris sipariş oluşturma ve gönderme
- Kendi siparişlerini ve durumlarını izleme
- Sipariş Excel'ini indirme
- Güncelleme talebi açma ve üretici yanıtlarına bakma

Yapamaz:
- Katalog kayıtlarını düzenleme
- Başka firmanın siparişlerine erişme

### 5.2 Üretici
Yapabilir:
- Gönderilen siparişleri görme
- Durum güncelleme (onayla → üretime al → sevke hazır → sevk et)
- Güncelleme talebine onay / geri bildirim verme
- Katalog yönetimi (ürün oluştur/düzenle/sil)

Yapamaz:
- Yetki kapsamı dışındaki verilere erişme

---

## 6) Çekirdek Özellikler

### 6.1 Model Kataloğu
- Liste/galeri: model kodu, ad, görsel, kategori çipi.
- Detay: görseller, ölçü/teknik bilgi, üretim notları.
- Model koduna/adına göre arama-filtreleme.
- Görsel yoksa kategori/renk bazlı yerel placeholder görseli.

### 6.2 Matris Sipariş Formu
- Satırlar: renkler. Sütunlar: bedenler (S, M, L, XL, XXL, …).
- Hücre başına adet girişi; satır ve genel toplam anlık hesaplanır.
- Ek alanlar: termin tarihi, sipariş notu.
- **AI ile düzenle:** dağınık sipariş notunu üreticinin net anlayacağı bir metne dönüştürür.
- Aksiyonlar: sipariş gönderme.

### 6.3 Sipariş Yaşam Döngüsü
Durumlar (DB `order_status` enum):
- `submitted` (gönderildi)
- `approved` (onaylandı)
- `in_production` (üretimde)
- `shipped` (sevk edildi)

Üretim aşamaları (`production_stage`): `cutting`, `sewing`, `packing`, `logistics`.

Kurallar:
- Gönderilen sipariş üreticinin kuyruğuna düşer.
- Tüm durum değişiklikleri zaman damgalı ve denetlenebilir (`order_status_events`).
- Sipariş kodları `SPRS-0000001` biçiminde üretilir.

### 6.4 Güncelleme Talebi (Revizyon) Akışı
- Alıcı, sipariş bazlı talep açar (`buyer_request`).
- Üretici onaylar (`producer_approval`) veya geri bildirim verir (`producer_feedback`).
- Açık talep akışı kapanmadan sipariş **sevk edilemez**.
- Talep/geri bildirim metinleri için **AI ile düzenle** yardımcısı.
- Talep geçmişi zaman çizelgesinde korunur.

### 6.5 Excel Dışa Aktarımı
- Sipariş detayından üretilir (Edge Function: `generate-order-excel`).
- İçerik: firma bilgisi, model kodu/adı, matris tablosu, toplamlar, notlar, güncel durum.

### 6.6 Bildirimler (Push)
- Yeni sipariş → üreticiye.
- Durum değişikliği → alıcıya.
- Talep/onay/geri bildirim → karşı tarafa.
- Edge Function `send-push` + FCM ile gönderilir.

### 6.7 Kalıcı Sipariş Geçmişi
- Kullanıcı yetkili olduğu tüm geçmiş siparişlere erişir; zaman bazlı otomatik silme yoktur.

---

## 7) Kapsam (Demo)

Dahil:
- Kimlik doğrulama ve role göre yönlendirme
- Katalog listesi + detay
- Matris sipariş oluşturma/gönderme
- Sipariş listesi/detay/durum zaman çizelgesi
- Güncelleme talebi akışı
- Excel dışa aktarımı
- Push bildirimleri
- AI ile not/talep düzenleme (opsiyonel; backend yapılandırılırsa)

Ertelenen / kapsam dışı:
- Gelişmiş analitik/raporlama
- Offline-first senkronizasyon
- Çok kiracılı self-servis kurulum

---

## 8) UX İlkeleri

- Temiz, profesyonel B2B görsel dili
- Matris form için hızlı veri girişi
- Yaygın görevlerde minimum dokunuş
- Yoğun ama okunabilir bilgi hiyerarşisi
- Token tabanlı tasarım sistemi (renk, tipografi, boşluk, radius, yükselti) — bkz. `DesignSystem.md`

---

## 9) Fonksiyonel Olmayan Gereksinimler

- Orta seviye cihazlarda akıcı çalışma
- Farklı ekran boyutlarına duyarlı yerleşim
- Kararlı form durumu (veri kaybı olmadan)
- Temel erişilebilirlik: semantik, dokunma hedefleri, kontrast

---

## 10) Kabul Kriterleri

- Alıcı yalnızca yetkili veriyi görür; sipariş oluşturup gönderebilir.
- Üretici durumları güncelleyebilir ve talebe doğru yanıt verebilir.
- Matris toplamları tüm akışlarda matematiksel olarak doğrudur.
- Sipariş Excel'i detaydan üretilebilir.
- Açık talep akışı varken sevk engellenir.
- Geçmiş siparişler erişilebilir kalır, otomatik silinmez.
- Android (APK) ve web build'leri başarıyla alınır.

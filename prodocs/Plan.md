# Geliştirme Planı — TextileFlow

> Bu doküman, geliştirmeye başlamadan önce kurgulanan yol haritasıdır: hedefler, **kullanıcı
> hikayeleri**, mimari kararlar, fazlara/sprintlere bölünmüş teslimat planı, veri modeli,
> güvenlik, kalite ve riskler.

---

## 1) Hedefler

Tek Flutter kod tabanı ve Supabase backend ile, tekstil sektörüne yönelik bir B2B sipariş
yönetim uygulaması (Android + Web).

Birincil çıktılar:
- Hızlı MVP teslimi
- Sürdürülebilir, özellik-öncelikli (feature-first) mimari
- Role/firmaya göre ölçeklenebilir veri modeli + RLS
- Kalıcı sipariş geçmişi
- Dağınık (WhatsApp/Excel) sipariş iletişiminin matris yapı ve durum akışıyla standartlaştırılması

Hedef kitle ve pain/gain tanımı için bkz. `PRD.md` §2–3.

---

## 2) Kullanıcı Hikayeleri

`PRD.md` §2–3 (hedef kitle, pain/gain) üzerinden türetilmiştir. Klasik *"Alıcı olarak … istiyorum
ki …"* formatı yerine **hedef kitlenin talebi** kullanılmıştır; her hikaye kabul kriteri, sprint
ve teknik adımla eşlenir.

### Sprint özeti

| Sprint | Hedef kitlenin talebi |
|---|---|
| **0** | Tutarlı, profesyonel bir arayüz ve hızlı giriş deneyimi; marka kimliği net olsun. |
| **1** | Güvenli giriş; rolüme göre doğru panele düşeyim, başka firmanın verisini görmeyeyim. |
| **2** | Güncel ürün kataloğuna tek yerden bakabileyim; model kodu/adıyla arayıp detay görebileyim. |
| **3** | Renk-beden kırılımını Excel/WhatsApp yerine standart matrisle iletebileyim; notumu netleştirebileyim. |
| **4** | Siparişimin hangi aşamada olduğunu görebileyim; değişiklik talebimi kayıt altına alıp üretici yanıtını takip edebileyim. |
| **5** | Durum/talep değişince haberdar olayım; sipariş özetini Excel olarak paylaşabileyim. |
| **6** | Demo ve canlı ortamda akışlar güvenilir çalışsın; teslim için dokümantasyon hazır olsun. |

### Hikayeler

#### Kimlik ve erişim

**KH-01 — Güvenli giriş ve rol yönlendirme**
- **Rol:** Alıcı ve üretici operasyon kullanıcısı
- **Talep:** E-posta/şifre ile giriş yapıp yalnızca kendi firmamın paneline yönlendirilmek; başka firmanın verisine erişmemek.
- **Kabul kriteri:** Oturum kalıcı; çıkış sonrası korumalı sayfalar açılmaz; alıcı/üretici menüleri ayrıdır.
- **Sprint:** 1 · **Teknik:** Supabase Auth, `profiles`, `go_router` guard, `login_page`

---

#### Katalog

**KH-02 — Alıcının katalogda model araması**
- **Rol:** Alıcı operasyon sorumlusu
- **Talep:** Yayındaki modelleri listeleyip kod/ad ile arayarak teknik detay ve görsellere ulaşmak; dağınık dosya paylaşımına bağımlı kalmamak.
- **Kabul kriteri:** Yalnızca yayında ürünler listelenir; arama anında filtreler; görsel yoksa placeholder gösterilir.
- **Sprint:** 2 · **Teknik:** `catalog_page`, `supabase_catalog_repository`, `catalogPlaceholderAsset`

**KH-03 — Üreticinin katalog yönetimi**
- **Rol:** Üretici planlama / katalog sorumlusu
- **Talep:** Ürün oluşturup düzenleyebilmek, görselleri yükleyebilmek; alıcının güncel katalog üzerinden sipariş vermesini sağlamak.
- **Kabul kriteri:** CRUD çalışır; Storage kotası görünür; silme onaylı ve geri alınamaz.
- **Sprint:** 2 · **Teknik:** `producer_catalog_admin_page`, Storage `catalog-images`, RLS

---

#### Sipariş oluşturma

**KH-04 — Matris sipariş girişi**
- **Rol:** Alıcı operasyon sorumlusu
- **Talep:** Seçilen model için renk × beden adetlerini tek ekranda girip satır ve genel toplamı anında görmek; hatalı manuel Excel gönderiminden kaçınmak.
- **Kabul kriteri:** Toplamlar doğru; termin tarihi seçilir; gönderimde `SPRS-` kodlu sipariş oluşur.
- **Sprint:** 3 · **Teknik:** `create_order_page`, matris widget, `supabase_orders_repository`

**KH-05 — Sipariş notunu netleştirme (AI)**
- **Rol:** Alıcı operasyon sorumlusu
- **Talep:** Dağınık sipariş notunu üreticinin anlayacağı kısa, profesyonel bir üretim notuna dönüştürmek.
- **Kabul kriteri:** "AI ile düzenle" metni API üzerinden döner; kullanıcı onaylamadan kayıt oluşmaz; servis kapalıysa çekirdek akış etkilenmez.
- **Sprint:** 3, 5 · **Teknik:** `backend/api` `/assist/order-note`, `AssistApi`, Gemini

---

#### Sipariş takibi ve üretim

**KH-06 — Alıcının sipariş durumunu izlemesi**
- **Rol:** Alıcı operasyon sorumlusu
- **Talep:** Gönderdiğim siparişlerin hangi aşamada olduğunu (gönderildi → onay → üretim → sevk) zaman damgalı görmek; geçmişe erişmek.
- **Kabul kriteri:** Takip listesi ve detay; durum zaman çizelgesi; kalıcı geçmiş (otomatik silme yok).
- **Sprint:** 4 · **Teknik:** `tracking_page`, `order_status_timeline_card`, `order_status_events`

**KH-07 — Üreticinin sipariş yaşam döngüsü yönetimi**
- **Rol:** Üretici üretim sorumlusu
- **Talep:** Gelen siparişi onaylayıp üretime almak, sevke hazır işaretlemek ve sevk etmek; her adım alıcıya yansısın.
- **Kabul kriteri:** Durum geçişleri sıralı; `order_status_events` loglanır; açık talep varken sevk engellenir.
- **Sprint:** 4 · **Teknik:** `producer_order_detail_page`, `producer_production_page`, durum enum + guard

---

#### Güncelleme talebi

**KH-08 — Alıcının güncelleme talebi açması**
- **Rol:** Alıcı operasyon sorumlusu
- **Talep:** Üretim/sevk öncesi değişiklik ihtiyacımı siparişe bağlı, kayıt altına alınmış bir talep olarak iletmek; WhatsApp’ta kaybolan mesajlar yerine izlenebilir süreç.
- **Kabul kriteri:** `buyer_request` kaydı oluşur; sevk edilmiş siparişte yeni talep açılamaz; talep geçmişi görünür.
- **Sprint:** 4 · **Teknik:** `order_update_threads`, `addBuyerRequest`, `request_thread_detail_page`

**KH-09 — Üreticinin talebe yanıt vermesi**
- **Rol:** Üretici üretim sorumlusu
- **Talep:** Gelen talebi onaylamak veya geri bildirimle netleştirmek; süreç kapanmadan sevk yapmamak.
- **Kabul kriteri:** `producer_approval` / `producer_feedback`; açık talep varken `shipped` reddedilir.
- **Sprint:** 4 · **Teknik:** `producer_requests_page`, `update_entry_kind` enum, sevk guard

**KH-10 — Güncelleme talebi metnini netleştirme (AI)**
- **Rol:** Alıcı operasyon sorumlusu
- **Talep:** Dağınık güncelleme metnini kibar, net ve uygulanabilir tek bir talep cümlesine dönüştürmek (hangi sipariş, ne değişecek).
- **Kabul kriteri:** `/assist/update-request` çalışır; sipariş kodu bağlamda kullanılır.
- **Sprint:** 5 · **Teknik:** `tracking_order_list_card` dialog, `AssistApi.updateRequest`

---

#### Bildirim ve dışa aktarım

**KH-11 — Kritik olaylarda push bildirimi**
- **Rol:** Alıcı ve üretici
- **Talep:** Yeni sipariş, durum değişimi ve talep/yanıt olduğunda anında haberdar olmak; uygulamayı sürekli kontrol etmek zorunda kalmamak.
- **Kabul kriteri:** FCM token kaydı; Edge Function `send-push`; bildirimden ilgili detaya yönlendirme.
- **Sprint:** 5 · **Teknik:** `fcm_service`, `010_push_update_requests.sql`, `push_navigation`

**KH-12 — Sipariş özetini Excel olarak paylaşma**
- **Rol:** Alıcı ve üretici
- **Talep:** Sipariş detayından matris, toplam ve notları içeren Excel indirip paylaşmak; mevcut Excel iş akışıyla uyumlu çıktı.
- **Kabul kriteri:** Edge Function `generate-order-excel` yetkili kullanıcıya dosya üretir.
- **Sprint:** 5 · **Teknik:** `generate-order-excel`, `producer_order_excel` / indirme UI

---

## 3) Yaklaşım ve Mimari Kararlar

**İstemci (Flutter)**
- Durum yönetimi: **Riverpod** — neden: test edilebilir, sade, derleme zamanı güvenli sağlayıcılar.
- Navigasyon: **`go_router`** — neden: rol bazlı route guard ve derin bağlantı (push) desteği.
- Veri katmanı: **Supabase SDK + repository deseni** — UI'ı backend detayından ayırır.
- Klasör: özellik-öncelikli (`presentation` / `application` / `domain` / `data`).
- Ortam: `flutter_dotenv` (`.env`); anahtarlar repoya girmez.

**Backend (Supabase)**
- Postgres şeması + enum'lar + kısıtlar; her rol/firma için RLS.
- Auth: e-posta/şifre; rol/firma `profiles` tablosunda eşlenir.
- Storage: katalog görselleri.
- Edge Functions (Deno/TS): `send-push`, `generate-order-excel`.

**Bildirim & AI**
- Push: Firebase Cloud Messaging (FCM) + `send-push` Edge Function.
- AI yardımcı: ayrı bir **FastAPI** servisi (Gemini `gemini-2.5-flash`); frontend'den **opsiyonel** çağrılır. Çekirdek akışı bloklamaz.

---

## 4) Depo Yapısı

```text
TextileFlow/
  frontend/                 # Flutter uygulaması (lib/app, core, features, shared)
  backend/
    functions/              # Supabase Edge Functions (send-push, generate-order-excel)
    api/                    # FastAPI + Gemini AI servisi
  database/
    migrations/             # 001..012 sıralı SQL
    policies/               # RLS politikaları
    seeds/                  # dev_seed / dev_seed_minimal
  prodocs/                  # planlama ve tasarım dokümanları
```

Frontend, backend ve veritabanı varlıkları ayrı üst klasörlerde; özellik modülleri bileşen
bazında geliştirilir (tek dosyalık monolit değil).

---

## 5) Sprint Planı (MVP odaklı)

Her sprint, çalışır bir dikey dilim teslim eder; tasarım token'ları en baştan kurulur.

### Sprint 0 — Kurulum ve Temeller
- Flutter projesi, ortamlar (`.env`), lint/format standartları.
- Tema token'ları (`AppColors`, boşluk, radius, tipografi) ve navigasyon kabuğu.
- **Çıktı:** Android/Web'de çalışan uygulama kabuğu, tema ve yönlendirme iskeleti.

### Sprint 1 — Kimlik ve Rol Yönlendirme
- Supabase projesi, e-posta/şifre auth, `profiles` (rol/firma) eşlemesi.
- Role göre yönlendirme (alıcı / üretici) ve korumalı route'lar.
- **Çıktı:** Giriş/çıkış, oturum kalıcılığı, rol bazlı route guard.

### Sprint 2 — Katalog ve Model Detayı
- Arama/filtreli katalog listesi, model detay ekranı.
- Görsel yoksa kategori/renk bazlı yerel placeholder.
- **Çıktı:** Uçtan uca gezilebilir katalog akışı.

### Sprint 3 — Matris Sipariş Oluşturma
- Dinamik renk/beden matris widget'ı, satır + genel toplam hesaplama ve doğrulama.
- Termin tarihi + sipariş notu alanları; sipariş gönderme.
- **Çıktı:** Alıcı gerçekçi siparişler oluşturup gönderebilir.

### Sprint 4 — Sipariş Yönetimi ve Talep Akışı
- Alıcı ve üretici için sipariş liste/detay; durum güncelleme aksiyonları.
- Durum zaman çizelgesi / olay logu (`order_status_events`).
- Güncelleme talebi akışı: alıcı talebi → üretici onay/geri bildirim; açık talep varken sevk engeli.
- **Çıktı:** Gönderimden sevke tam yaşam döngüsü.

### Sprint 5 — Dışa Aktarım, Bildirim ve AI
- Excel dışa aktarımı (Edge Function `generate-order-excel`).
- Push bildirimleri (FCM + `send-push`): yeni sipariş, durum değişimi, talep/yanıt.
- AI yardımcı (opsiyonel): sipariş notu ve güncelleme talebi metnini düzenleme.
- **Çıktı:** Operasyonel bildirim + paylaşılabilir Excel + yazım yardımcısı.

### Sprint 6 — Sertleştirme, QA ve Teslim
- Boş/yükleniyor/hata durumları, form doğrulama, performans ve erişilebilirlik gözden geçirme.
- Markalama/temizlik, demo verisi, APK + Web build, demo senaryosu.
- **Çıktı:** MVP yayın adayı + bootcamp teslim paketi.

---

## 6) Veri Modeli (Özet)

### Tablolar
- `companies`, `profiles` (rol/firma)
- `catalog_models`, `catalog_variants` (renk/beden, `image_url`)
- `orders` (alıcı/üretici firma, model, durum, aşama, toplam adet, termin, notlar, sipariş no'ları)
- `order_lines` (renk/beden/adet)
- `order_status_events` (durum geçişleri / timeline)
- `order_update_threads` / `order_update_entries` (talep akışı)
- push kuyruğu tabloları

### Enum'lar
- `order_status`: `submitted`, `approved`, `in_production`, `shipped`
- `production_stage`: `cutting`, `sewing`, `packing`, `logistics`
- `update_entry_kind`: `buyer_request`, `producer_approval`, `producer_feedback`

Sipariş kodları `SPRS-0000001` biçiminde dizi fonksiyonuyla üretilir (`011_order_code_sequence.sql`).

---

## 7) Güvenlik ve Erişim Kontrolü

- Tüm iş tablolarında RLS etkin.
- Alıcı yalnızca kendi firmasının siparişlerini okur/yazar; üretici yalnızca yetkili olduğu gönderilmiş siparişleri görür.
- Durum geçişi aksiyonları role göre sınırlandırılır.
- Storage okuma: giriş yapmış kullanıcılar; yazma: üretici (katalog, kendi şirket prefix'i).

---

## 8) Kalite Stratejisi

- **Birim:** matris toplam hesapları, durum geçiş kuralları, repository eşlemeleri.
- **Widget:** sipariş formu girişi, doğrulama, rozet/timeline render.
- **Entegrasyon:** giriş → sipariş oluştur → gönder → durum güncelle; talep aç → yanıtla; Excel dışa aktarım.
- Statik analiz: `flutter analyze` (flutter_lints) her sprint sonunda temiz.

---

## 9) Riskler ve Önlemler

- **Matris form karmaşıklığı** → izole, yeniden kullanılabilir widget olarak Sprint 3'te geliştir.
- **Rol/firma görünürlük hataları** → RLS testleri ve politika gözden geçirme (özellik dondurmadan önce).
- **UI tutarsızlığı** → token-öncelikli tasarım sistemi ve bileşen envanteri (bkz. `DesignSystem.md`).
- **AI servisi bağımlılığı** → AI opsiyonel; `API_BASE_URL` yoksa özellik gizlenir, çekirdek akış etkilenmez.
- **Bildirim/Edge Function gizli anahtarları** → yalnızca Supabase secrets/ortam değişkenleriyle; kodda gömülü değil.

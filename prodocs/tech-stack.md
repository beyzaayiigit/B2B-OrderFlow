# Teknoloji Yığını — TextileFlow

Bu doküman, TextileFlow demo uygulamasının kullandığı teknolojileri, kütüphaneleri ve sürümleri özetler. Kaynaklar: `frontend/pubspec.yaml`, `backend/api/pyproject.toml`, `database/`, `backend/functions/`.

---

## 1) İstemci — Flutter (Android + Web)

- **Dil/SDK:** Dart, Flutter (Dart SDK `^3.11.5`)
- **Durum yönetimi:** `flutter_riverpod` `^3.3.1`
- **Navigasyon:** `go_router` `^17.2.3`
- **Backend SDK:** `supabase_flutter` `^2.12.4`
- **Bildirim:** `firebase_core` `^3.13.0`, `firebase_messaging` `^15.2.4`
- **Ortam değişkenleri:** `flutter_dotenv` `^5.2.1` (`.env`)
- **HTTP:** `http` (AI servisi çağrıları)
- **Excel:** `excel_community` `^1.1.4`
- **Dosya/paylaşım:** `share_plus`, `path_provider`, `file_saver`
- **Görsel:** `flutter_svg`, `cached_network_image`, `image_picker`
- **Diğer:** `intl`, `collection`, `shared_preferences`, `url_launcher` (WhatsApp)
- **Yerel araçlar (dev):** `flutter_lints` `^6.0.0`, `flutter_launcher_icons` `^0.14.3`

Mimari: özellik-öncelikli (feature-first) — `presentation / application / domain / data`. Tasarım token'ları `lib/app/theme/` altında (bkz. `DesignSystem.md`).

---

## 2) Backend — Supabase

- **Veritabanı:** PostgreSQL
- **Güvenlik:** Row Level Security (RLS) — tüm iş tablolarında
- **Kimlik:** Supabase Auth (e-posta/şifre)
- **Depolama:** Supabase Storage (katalog görselleri)
- **Şema:** `database/migrations/001..012` (sıralı SQL), `database/policies/` (RLS), `database/seeds/` (demo verisi)
- **Enum'lar:** `order_status`, `production_stage`, `update_entry_kind`

### Edge Functions (Deno / TypeScript)
- `send-push` — FCM ile push gönderimi (HTTP v1, servis hesabı JWT)
- `generate-order-excel` — sipariş özetinden Excel üretimi

Gizli anahtarlar Supabase secrets / ortam değişkenleri üzerinden okunur (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`).

---

## 3) Bildirim — Firebase Cloud Messaging (FCM)

- Android istemci yapılandırması: `frontend/android/app/google-services.json` (demo projesi `textilwflow-demo`; repoda yok, yerel/Firebase Console’dan alınır)
- Sunucu tarafı gönderim: `send-push` Edge Function + FCM HTTP v1 API

---

## 4) AI Yardımcı Servisi — FastAPI + Gemini

- **Çalışma zamanı:** Python `>=3.11`, paket yöneticisi **`uv`**
- **Web framework:** `fastapi` `>=0.115.0`, sunucu `uvicorn[standard]` `>=0.30.0`
- **LLM:** `google-genai` `>=0.3.0` — model **`gemini-2.5-flash`**
- **Doğrulama:** `pydantic` `>=2.7.0`
- **Ortam:** `python-dotenv` (`GEMINI_API_KEY`, `GEMINI_MODEL`, `ALLOWED_ORIGINS`)

### Uç noktalar
- `GET /health` — sağlık kontrolü
- `POST /assist/order-note` — dağınık sipariş notunu üretim notuna dönüştürür
- `POST /assist/update-request` — güncelleme talebini net bir talep metnine dönüştürür

Frontend bu servisi `API_BASE_URL` tanımlıysa çağırır; tanımlı değilse "AI ile düzenle" özelliği gizlenir ve çekirdek akış etkilenmez.

---

## 5) Ortam Değişkenleri (özet)

### Frontend (`frontend/.env`)
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- `API_BASE_URL` (opsiyonel; AI servisi — Android emülatörde `http://10.0.2.2:8000`)

### AI servisi (`backend/api/.env`)
- `GEMINI_API_KEY`, `GEMINI_MODEL`, `ALLOWED_ORIGINS`

> `.env` dosyaları repoya **girmez**; her dizinde `.env.example` şablonu bulunur.

---

## 6) Araçlar

- Statik analiz: `flutter analyze` (flutter_lints)
- İkon üretimi: `flutter_launcher_icons`
- Görsel işleme (logo/ikon/ürün placeholder üretimi): Python (Pillow/NumPy) yardımcı script'leri

---

## 7) Geliştirme Sürecinde Yapay Zeka Kullanımı

Brief’in istediği “geliştirme sürecinde AI’ın nasıl kullanıldığı” özeti. İki katman vardır: **ürün içi LLM** (çalışma zamanı) ve **geliştirme asistanı** (Cursor / kod ve dokümantasyon).

### 7.1 Ürün içi LLM (çalışma zamanı)

| Konu | Seçim | Gerekçe |
|---|---|---|
| Sağlayıcı | Google **Gemini 2.5 Flash** | Düşük gecikme, Türkçe metin düzenleme için yeterli kalite, düşük maliyet |
| Entegrasyon | **FastAPI** (`backend/api`) üzerinden HTTP API | Frontend/Backend ayrımı; anahtarlar istemciye gitmez; ileride başka istemciler de aynı API’yi kullanabilir |
| Kapsam | Sipariş notu + güncelleme talebi metni düzenleme | Çekirdek B2B akışına doğrudan değer: dağınık iletişimi netleştirir |
| Sınır | Sipariş durumu, RLS, matris hesabı LLM’e devredilmez | Deterministik iş kuralları kod/DB’de kalır; halüsinasyon riski operasyonel veriye taşınmaz |

### 7.2 Geliştirme asistanı (Cursor + LLM ajanı)

Proje boyunca AI destekli geliştirme aracı olarak **Cursor** kullanıldı. Örnek kullanım alanları:

- **Planlama ve dokümantasyon:** `PRD.md`, `Plan.md`, `DesignSystem.md`, `tech-stack.md` taslağı; brief kriterlerine göre Türkçeleştirme ve güncelleme.
- **LLM özelliği:** FastAPI iskeleti, Gemini istemcisi, frontend `AssistApi` ve “AI ile düzenle” UI entegrasyonu.
- **Hata ayıklama:** Token kesilmesi (thinking budget), Android emülatör depolama, eksik dialog butonları gibi sorunlarda kök neden analizi.
- **Tasarım:** Palet 2, anlamsal buton renkleri, placeholder ürün görselleri.

### 7.3 AI ile alınan örnek kararlar

- **Ayrı FastAPI servisi** yerine LLM’i doğrudan Flutter’a gömmemek → API anahtarı güvenliği ve brief’teki “backend ayrı API” şartı.
- **Enum yeniden adlandırma** (`madmext_talep` → `buyer_request`) → hem kod okunabilirliği hem hoca incelemesi için nötr demo.
- **AI opsiyonel kalabilir** (`API_BASE_URL` yoksa buton gizli) → demo ortamında çekirdek akış Supabase ile çalışmaya devam eder; canlı teslimde AI açık tutulur.

### 7.4 Sınırlar ve insan kontrolü

- Üretilen metinler kullanıcı tarafından onaylanmadan kaydedilmez (düzenleme butonu → metin alanına yazar, kullanıcı gönderir).
- Gerçek API anahtarları (Supabase, Gemini, Firebase) repoya girmez; yalnızca `.env.example` şablonları commit edilir.
- Migration ve RLS değişiklikleri SQL dosyalarında tutulur; AI önerileri manuel doğrulama ile uygulanır.

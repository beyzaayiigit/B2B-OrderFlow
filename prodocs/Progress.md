# B2B Proje İlerleme Notları

> ## Otomatik Güncelleme Kuralı (Kalıcı Prompt)
> Bu dosya canlı ilerleme kaydıdır. Bu doküman etiketlendiğinde veya güncelleme istendiğinde:
> 1. Mevcut içerik silinmez, üzerine yazılmaz.
> 2. Yeni yapılan işler dosyanın sonuna tarih/saat bağlamı ile **eklenir**.
> 3. “Yapılanlar / Sorunlar / Çözümler / Durum / Sonraki adımlar” formatı korunur.
> 4. Teknik detaylarda ilgili dosya yolları ve önemli karar değişiklikleri belirtilir.
> 5. Geçmiş kayıtlar korunur; sadece yeni kayıt append edilir.

Bu doküman, proje başlangıcından bu ana kadar yapılan tüm teknik adımları, alınan kararları, karşılaşılan sorunları ve çözümleri özetler.

### Proje bağlamı

Bu uygulama başlangıçta bir **freelance B2B tekstil sipariş projesi** olarak geliştirildi. **Future Talent bootcamp** süresince derslerle **paralel** ilerletildi; kayıtların büyük bölümü o dönemdeki geliştirme oturumlarını yansıtır. Bootcamp bitirme teslimi için proje, canlı müşteri ortamından ayrılarak **TextileFlow** demo sürümüne dönüştürüldü (nötr markalama, ayrı Supabase/Firebase, güncellenmiş `prodocs`). Eski kayıtlar tarihsel süreç olarak korunmuştur; güncel demo durumu dosyanın sonundaki bootcamp bölümünde (§40) özetlenir.

---

## 1) Proje ve Doküman Analizi

Başlangıçta repoda uygulama kodu yoktu, sadece dokümanlar vardı:

- `documents_flutter/PRD_FLUTTER.md`
- `documents_flutter/DEVELOPMENT_PLAN_FLUTTER.md`
- `documents_flutter/EXECUTION_ROADMAP_FLUTTER.md`
- `stitch_application_design_framework/DESIGN.md`
- `stitch_application_design_framework/textile_ledger_design_system_documentation.md`

Analiz sonucu netleşenler:

- Uygulama Flutter ile Android + iOS hedefli.
- Roller: `Alıcı (alıcı)` ve `Üretici (üretici)`.
- Ana akışlar: katalog, matris sipariş, sipariş lifecycle, revizyon, PDF.
- Sipariş geçmişi kalıcı (7 günlük otomatik silme kapsam dışı).
- Profesyonel UI hedefi: responsive, taşmasız, token tabanlı tasarım.

## 2) Plan ve Kapsam Kararları

Plan aşamasında aşağıdaki kararlar alındı:

- Frontend geliştirmesi backend’den bağımsız ilerleyecek (mock/repository yaklaşımı).
- Türkçe dil kullanılacak; Türkçe karakterler korunacak.
- Responsive davranış, taşma önleme, erişilebilirlik kalite kriteri olarak eklendi.
- Header’da aktif şirket bağlamı gösterilecek (`Alıcı` / `Üretici` + panel tipi).
- 7 günlük temizlik/sayaç yaklaşımı kaldırıldı, kalıcı geçmiş yaklaşımı benimsendi.

## 3) Doküman Güncellemeleri

### 3.1 7 gün temizleme kuralı güncellemesi

`stitch_application_design_framework/textile_ledger_design_system_documentation.md` içinde:

- Eski “7 gün sayaç / otomatik temizlik” ifadeleri kaldırıldı.
- Sipariş takip bölümü kalıcı geçmiş + durum timeline yaklaşımına çekildi.
- Tasarım ilkelerinde ilgili eski ifade güncellendi.

### 3.2 Plan dokümanına kalite/yerelleştirme ekleri

Plan dosyasına şu maddeler net şekilde eklendi:

- Responsive ve taşmasız UI kriterleri
- Türkçe dil/karakter standardı
- Geliştirme boyunca profesyonel frontend prensipleri

## 4) Ortam Kurulumu ve Teknik Süreç

## 4.1 Flutter kurulumu

İlk durumda `flutter` komutu sistemde yoktu.

Yapılanlar:

- Flutter SDK manuel kuruldu.
- Çalışan SDK yolu:
  - `C:\Users\beyza\development\flutter_stable\flutter`
- `flutter --version` ve `flutter doctor` doğrulandı.

## 4.2 Android SDK/Emulator taşıma ve disk problemi

Çok düşük C diski boş alanı nedeniyle build süreçleri ve cache bozulmaları yaşandı.

Yapılanlar:

- Android SDK yolu D diske alındı:
  - `D:\Android\Sdk`
- AVD yolu D diske alındı:
  - `D:\Android\Avd`
- `ANDROID_AVD_HOME` değişkeni tanımlandı.
- Bozuk AVD temizlenip yeni cihaz oluşturuldu (`Pixel 7 (2)`).
- Flutter cihaz/emülatör algısı düzeltildi (`flutter devices`, `flutter emulators`).

## 4.3 Yaşanan build hataları ve çözümler

Karşılaşılan ana problemler:

- Gradle/Kotlin cache metadata bozulmaları
- C diski yetersizliği
- SDK/AVD path geçişinden kaynaklı kararsızlık
- Terminal oturumlarında PATH kaybı

Uygulanan çözümler:

- Gradle/Pub/Flutter cache temizliği
- SDK ve AVD’nin D sürücüsüne taşınması
- Ortam değişkenlerinin güncellenmesi
- Emulator yeniden oluşturma

Not: Süreçte birden fazla başarısız arka plan komutu oldu, fakat son durumda build alınıp APK cihaza başarıyla yüklendi.

## 5) Flutter Projesinin Oluşturulması

Yeni Flutter proje klasörü oluşturuldu:

- `frontend/`

Temel bağımlılıklar eklendi:

- `flutter_riverpod`
- `go_router`
- `supabase_flutter`
- `intl`
- `collection`
- `pdf`
- `printing`
- `flutter_svg`
- `cached_network_image`

## 6) Frontend Temel Mimari ve Dosya Yapısı

Kurulan temel katmanlar:

- `app/` (router, theme)
- `features/` (auth, catalog, orders, producer, profile)
- `shared/` (role tipleri, ortak shell, badge bileşeni)
- `core/` (responsive page altyapısı)

Tema/token başlangıcı yapıldı:

- `app_colors.dart`
- `app_spacing.dart`
- `app_theme.dart`

## 7) Rol Bazlı Akış (Alıcı vs Üretici)

Başta iki rol aynı sayfaları görüyordu. Sonrasında ayrıştırıldı.

### Alıcı (Alıcı)

Sekmeler:

- `Katalog`
- `Sipariş`
- `Takip`
- `Hesap`

### Üretici (Üretici)

Sekmeler:

- `Gelenler`
- `Üretim`
- `Revizyon`
- `Hesap`

Üretici için eklenen sayfalar:

- `features/producer/presentation/producer_orders_page.dart`
- `features/producer/presentation/producer_production_page.dart`
- `features/producer/presentation/producer_revisions_page.dart`

Router ve shell bileşeni rol bazlı davranacak şekilde güncellendi.

## 8) Sipariş Oluşturma (Renk-Beden) Ekranı İyileştirmeleri

Kullanıcı geri bildirimlerine göre ekran yeniden kurgulandı.

Yapılanlar:

- Renk seçim modalı eklendi (çoklu seçim).
- Renkler seçme sırasına göre değil, default sırada listeleniyor.
- Seçilen renkler için aşağıda kartlar oluşuyor.
- Renk kartlarında:
  - Renk adı yanında küçük renk karesi
  - Rengi kaldırma (`x`)
  - Beden chip’leri
  - Beden satırı bazında kaldırma (`x`)
- Bedenler varsayılan seçili geliyor (kullanıcı istemediklerini kaldırıyor).
- Kaldırılan beden tekrar seçilebiliyor.
- Gönderim kuralları sıkılaştırıldı:
  - Seçili her renkteki aktif bedenlerin tamamında adet > 0 olmalı.
  - Aksi durumda `Siparişi Gönder` pasif.

## 9) Takip Sekmesindeki Boş Ekran ve Layout Hatası

`Takip` sekmesinde `BoxConstraints forces an infinite width` hatası vardı.

Düzeltmeler:

- FilledButton tema minimum size ayarı iyileştirildi.
- Tracking kartındaki buton yerleşimi `Flexible` ile güvenli hale getirildi.

Sonuç:

- Takip sekmesi tekrar veri göstermeye başladı.
- Layout taşma/sonsuz genişlik hatası giderildi.

## 10) Header / Geri Butonu

Geri butonu davranışı güncellendi:

- Stack pop varsa normal geri.
- Tab akışında gerekli durumlarda kataloga dönüş.
- Rol bazlı shell akışıyla uyumlu olacak şekilde düzenlendi.

## 11) Test ve Doğrulama

Süreç içinde defalarca:

- `flutter analyze`
- `flutter test`

çalıştırıldı ve son düzenlemeler analiz/testten temiz geçti.

## 12) Mevcut Durum (Son)

Şu an sistemde:

- Proje build alabiliyor.
- APK emülatöre kurulabiliyor.
- Ana sayfa/sekme akışı çalışıyor.
- Rol bazlı ayrım aktif.
- Sipariş oluşturma ekranı kullanıcı geri bildirimine göre ciddi ölçüde iyileştirildi.

## 13) Sonraki Önerilen Adımlar

1. Alıcı ve Üretici için gerçek business action butonlarını bağlamak.
2. Mock veriden repository + Supabase data source katmanına geçmek.
3. Sipariş oluşturma ekranına form validasyon mesajlarını daha ayrıntılı eklemek.
4. PDF export akışını gerçek sipariş modeline bağlamak.
5. En kritik akışlar için ek widget/integration testleri yazmak:
   - Renk/beden seçim kuralları
   - Gönder butonu aktif/pasif koşulları
   - Rol bazlı route guard ve sekme görünürlüğü

---

## 14) Ek Güncellemeler (Son Oturum)

Bu bölüm, ilk `progress.md` oluşturulduktan sonra yapılan yeni geliştirmeleri içerir.

### 14.1 Çalışma/Kurulum Durumu

- Emulator ve SDK path sorunları çözülerek uygulama emülatörde başarıyla çalıştırıldı.
- Gradle/Kotlin cache kaynaklı hatalar zaman zaman tekrar etti, ancak son durumda APK derlenip cihaza yüklendi.
- Runtime’da görülen `BoxConstraints forces an infinite width` hatası kod tarafında giderildi.

### 14.2 Takip Sayfası Layout Düzeltmesi

Sorun:

- `Takip` ekranında buton yerleşimi bazı cihaz koşullarında sonsuz genişlik constraint üretiyordu ve ekran boş görünüyordu.

Düzeltme:

- `filledButtonTheme` minimum size ayarı yatayda sonsuz zorlamayacak hale getirildi.
- Tracking kartındaki `PDF İndir` butonu `Flexible` içinde konumlandırıldı.

Sonuç:

- `Takip` sekmesi tekrar stabil şekilde içerik gösteriyor.

### 14.3 Header Geri Butonu Davranışı

- Geri butonu davranışı, tab akışında beklenen şekilde güncellendi.
- Stack geri varsa `pop`, yoksa ana route’a dönüş mantığı korunuyor.

### 14.4 Rol Bazlı Sayfa Ayrımı (Alıcı / Üretici)

Kullanıcı geri bildirimine göre iki rolün farklı iş akışları netleştirildi:

- Alıcı (alıcı): `Katalog / Sipariş / Takip / Hesap`
- Üretici (üretici): `Gelenler / Üretim / Revizyon / Hesap`

Eklenen üretici sayfaları:

- `lib/features/producer/presentation/producer_orders_page.dart`
- `lib/features/producer/presentation/producer_production_page.dart`
- `lib/features/producer/presentation/producer_revisions_page.dart`

Router ve shell:

- `lib/app/router.dart` ve `lib/shared/widgets/app_shell.dart` rol bazlı içerik dönecek şekilde güncellendi.

### 14.5 Sipariş Oluşturma Ekranı (İleri Seviye UX Güncellemeleri)

Kullanıcı taleplerine göre sipariş ekranı tekrar iyileştirildi:

- Renk seçim modalı genişletildi (default sırada renk listesi).
- Seçilen renk kartları default sıraya göre aşağıda oluşuyor.
- Kart başlığında renk karesi + renk adı + kaldırma (`x`) desteği.
- Bedenler varsayılan aktif geliyor, istenmeyen bedenler `x` ile kaldırılabiliyor.
- Kaldırılan beden chip üzerinden tekrar seçilebiliyor.
- Beden input satırları için stabil key kullanımı eklendi (değer taşınma bug fix).
- Gönderim kuralı sıkılaştırıldı:
  - Seçili her renkteki tüm aktif bedenlerin adedi > 0 değilse gönderim pasif.

Ana dosya:

- `lib/features/orders/presentation/create_order_page.dart`

### 14.6 Logoların Entegrasyonu

Kullanıcının sağladığı logolar projeye alındı:

- `assets/logos/textileflow.png`
- `assets/logos/producer_logo.png`

Tanımlama:

- `pubspec.yaml` içine `assets/logos/` eklendi.

Kullanım:

- Login’de portal kartlarında role göre logo gösterimi.
- Header sağ alanında aktif role göre logo gösterimi.
- `UserRole` extension içine logo asset map’i eklendi:
  - `lib/shared/types/user_role.dart`

### 14.7 Katalogdan Seçilen Modelin Sipariş Ekranına Taşınması

Sorun:

- Sipariş panelinde model bilgisi tek sabit model olarak görünüyordu.

Düzeltme:

- Katalog kartı tıklanınca seçilen model `router extra` ile sipariş ekranına taşınıyor.
- Sipariş teknik kartında model adı/kodu/kategori dinamik gösteriliyor.

Dosyalar:

- `lib/features/catalog/presentation/catalog_page.dart`
- `lib/app/router.dart`
- `lib/features/orders/presentation/create_order_page.dart`

### 14.8 Sipariş Ekranında Katalogdan Bağımsız Model Seçimi

Yeni özellik:

- Sipariş ekranına `Model Seçimi` dropdown kartı eklendi.
- Kullanıcı katalogdan gelmiş olsa bile sipariş ekranı içinde modeli değiştirebiliyor.
- Model değişince teknik kart anlık güncelleniyor.

Dosya:

- `lib/features/orders/presentation/create_order_page.dart`

### 14.9 Kalite Kontrol Durumu

Bu ek güncellemeler sonrasında:

- `flutter analyze` temiz
- `flutter test` temel senaryo geçer durumda

### 14.10 Güncel Durum Özeti

Şu an uygulama:

- Emülatörde açılıyor.
- Rol bazlı menü/akış ayrımını destekliyor.
- Renk-beden sipariş kurgusunda kullanıcı taleplerinin büyük kısmını karşılıyor.
- Logolar login ve header’da görünür.
- Sipariş ekranı modeli hem katalogdan alabiliyor hem ekrandan seçebiliyor.

---

## 15) 7 Mayıs 2026 — Kapsamlı UX, Auth ve Üretici Tarafı Yenileme

Bu bölüm, ilk oturumlardan sonra müşteri geri bildirimleri ve UX testleri sonucu yapılan büyük çaplı düzenlemeleri kapsar.

### 15.1 Sipariş Oluşturma — Model Aktarımı Bug Fix

Sorun:

- Katalogtan farklı modele tıklasak da sipariş ekranında hep ilk model (`MD-2024-X01 — Klasik Ağır Kumaş Polo`) görünüyordu.
- `Sipariş` sekmesine direkt girince yine default model gözüküyor, kullanıcıyı yanıltıyordu.

Sebep:

- `CreateOrderPage` `StatefulWidget` ve `_selectedModel` yalnızca `initState`’te bir kere set ediliyordu. ShellRoute içindeki widget reuse'u nedeniyle `initState` ikinci kez çalışmıyor; yeni `widget.selectedModel` state'e yansımıyordu.
- Ek olarak `_selectedModel = widget.selectedModel ?? mockCatalog.first` default fallback'i empty state'i yutuyordu.

Çözüm:

- `_selectedModel` `ProductModel?` (nullable) yapıldı; `mockCatalog.first` fallback kaldırıldı.
- `didUpdateWidget` eklendi: `widget.selectedModel != oldWidget.selectedModel` ise state güncelleniyor (hem dolu hem null durumlar). Renk/beden seçimleri korunuyor.
- Model seçilmediğinde `_EmptyModelState` kartı gösteriliyor.
- `_ModelSelectorCard` dropdown'una `isExpanded: true`, `TextOverflow.ellipsis`, `ValueKey(currentModel?.code)` eklendi (uzun isimler ve `initialValue` cache sorunları için).

Dosya:

- `lib/features/orders/presentation/create_order_page.dart`

### 15.2 Katalog ve Takip Filtrelemesi

Katalog (`lib/features/catalog/presentation/catalog_page.dart`):

- `StatefulWidget`'a çevrildi.
- Arama yalnızca **model koduna** göre case-insensitive `contains`.
- Çipler (`Tüm Modeller / Polo / Tişört / Sweatshirt`) `ActionChip` ile **tıklanabilir**; seçili olan navy dolgulu, diğerleri muted.
- Sonuç boşsa `_EmptyResultsCard`.
- AND mantığı: hem arama hem kategori birlikte uygulanıyor.

Takip (`lib/features/orders/presentation/tracking_page.dart`):

- Aynı patern: arama (sipariş kodu) + durum çipleri (`Tümü / Onaylandı / Üretimde / Revizyon / Sevk Edildi`).
- Status anahtarları `StatusBadge.order()` ile uyumlu (`approved`, `in_production`, `revision_requested`, `shipped`).
- Mock veri tipli `_OrderRow` modeline taşındı.
- Sonuç boşsa empty state kartı.

### 15.3 UI Temizlikleri (İşlevsiz Elementler Kaldırıldı)

- Katalog kartından `Stokta` / `Numune` durum chip'i kaldırıldı (müşteri istemiyor).
- Tracking kartındaki işlevsiz `⋮` (more) butonu kaldırıldı.
- `CreateOrderPage` özet kartından işlevsiz `Taslak Olarak Kaydet` butonu kaldırıldı (taslak storage akışı netleşince geri eklenecek). `Siparişi Gönder` tek aksiyon olarak duruyor.

### 15.4 Üretici (Üretici) Tarafı Tamamen Yenilendi

Sorun:

- Üretici sayfaları sadece sipariş kodu + durum gösteriyordu; hangi model olduğu, kaç renk × kaç adet, termin gibi bilgiler yoktu. Müşteri haklı olarak "ne ürettiğimi anlayamam" dedi.

Yapılanlar:

- `lib/features/producer/domain/producer_order.dart` (yeni): `ProducerOrder` modeli (kod, ürün referansı, alıcı, durum, renk-adet map, termin, üretim aşaması, revizyon notu) + 5 mock sipariş.
- `lib/features/producer/presentation/widgets/producer_order_card.dart` (yeni): üretici listelerinde kullanılan ortak kart.
  - Sol: model thumbnail (gradient placeholder, ileride gerçek görsele bağlanır).
  - Sağ: model kodu, model adı, sipariş no, alıcı, durum badge.
  - Alt info chip'leri: renk×adet özeti, termin, üretim aşaması.
  - Renk dağılım satırı (örn. `Siyah 120 · Beyaz 80 · Lacivert 60`).
  - Revizyon notu için sarı vurgulu kutu.
  - Duruma göre aksiyon butonları.
- Sayfalar:
  - `producer_orders_page.dart` (Gelenler): submitted/revision_requested/approved siparişler; aksiyonlar `Onayla`, `Revizyon Talep Et`, `Üretime Al`, `Revizyon Detayı`.
  - `producer_production_page.dart` (Üretim): in_production siparişleri + üst metrik kartı (aktif sipariş, toplam adet); aksiyonlar `Aşama Değiştir` (bottom sheet: Kesim/Dikim/Paketleme/Lojistik), `Sevke Hazır`.
  - `producer_revisions_page.dart` (Revizyon): revision_requested siparişleri; üreticinin notu vurgulu kutuda; aksiyonlar `Yeni Öneri Gönder`, `Yanıt Bekleniyor`.

Sonuç:

- Üretici paneline giren kullanıcı her sipariş için ne, ne kadar, ne zaman bilgisini ilk bakışta görüyor.
- Tüm aksiyonlar şimdilik `SnackBar` ile placeholder; Supabase entegrasyonunda gerçek mutation’lara bağlanacak.

### 15.5 Kalıcı Oturum (Beni Hatırla)

Yapılanlar:

- `shared_preferences: ^2.3.3` eklendi (`pubspec.yaml`).
- `SessionController` artık `SessionState { isLoaded, role, email, rememberMe }` döndürüyor (`lib/features/auth/application/session_controller.dart`).
- Açılışta `_restore()` ile diskten oturum yükleniyor.
- `signIn(email, password, rememberMe)` ve `signOut()` async; `rememberMe = true` ise rol + e-posta diske yazılıyor.
- Router'a `/splash` route'u eklendi (`lib/app/router.dart`): oturum yüklenirken `CircularProgressIndicator` gösteriliyor, sonra rol durumuna göre `/login` veya `/catalog`'a yönlendiriliyor.
- `AppShell` ve `ProfilePage` yeni `SessionState` tipine güncellendi.

Karar:

- Yanlışlıkla rol değişimi imkânsız; çünkü rol diske kaydedilen e-postaya bağlı. Alıcı kullanıcısı uygulamayı kapatıp açtığında hâlâ Alıcı panelinde olur.

### 15.6 Login Akışı — Rol Kartları Kaldırıldı, E-posta + Şifre

Müşteri kararı:

- Kullanıcı login’de Alıcı / Üretici seçmeyecek; sadece e-posta + şifre girecek, rol arka planda belirlenecek.

Yapılanlar:

- `lib/features/auth/data/auth_repository.dart` (yeni): `MockAuthRepository` + `AuthResult` + `AuthFailure`.
  - 4 mock kullanıcı (2 buyer / 2 producer), e-posta + şifre eşleşmesine göre rol dönüyor.
  - Backend (Supabase) entegrasyonunda yalnızca bu sınıfın iç implementasyonu değişecek; üst katmanlar aynı kalır.
- `lib/features/auth/presentation/login_page.dart` baştan yazıldı:
  - Alıcı / Üretici rol kartları kaldırıldı.
  - Ortada Alıcı logosu (filigransız, doğrudan yerleştirilmiş, 48dp yükseklik).
  - Form: `TextFormField` validasyonu (email format regex, şifre min uzunluk).
  - Şifre göster/gizle göz ikonu.
  - `Beni hatırla` checkbox (default true; önceki oturum durumunu hatırlar).
  - `Şifremi unuttum` dialogu (yer tutucu metin, ileride backend e-postasına bağlanacak).
  - Submit anında `CircularProgressIndicator` + buton disable; çift submit engellendi.
  - Hata durumunda kırmızı `SnackBar` ("E-posta veya şifre hatalı." vb.).
  - `AuthFailure` → UI'a yansıtılıyor.

### 15.7 Branding — Uygulama Adı `TextileFlow`

- `MaterialApp.title`: `TextileFlow` (`lib/app/app.dart`).
- Android `android:label`: `mobile_orderflow_flutter` → `TextileFlow` (`AndroidManifest.xml`).
- iOS `CFBundleDisplayName` ve `CFBundleName`: `TextileFlow` (`Info.plist`).
- `assets/logos/textileflow.png` müşterinin sağladığı yeni logoyla değiştirildi.

### 15.8 Profil Sayfası Yeniden Tasarlandı

`lib/features/profile/presentation/profile_page.dart`:

- `ConsumerStatefulWidget`'a çevrildi; bildirim toggle state'leri için.
- Yeni bölümler:
  - **Profil özeti kartı:** gradient avatar (kullanıcı baş harfleri), ad, ünvan, şirket, "Doğrulanmış İş Ortağı" yeşil rozet.
  - **Hesap Bilgileri:** Ad Soyad, Kurumsal E-posta, Şirket, Vergi No (read-only info row'lar).
  - **Bildirim Tercihleri:** 3 kategori (Sipariş Yaşam Döngüsü, Revizyon Talepleri, Üretim & Sevkiyat) × E-posta + Push kanal toggle'ları (kapsül buton stili).
  - **Oturum & Güvenlik:** aktif cihaz kartı + "Aktif" yeşil rozet + `Şifreyi Değiştir` butonu.
  - **Destek:** Hesap yöneticisi (avatar + isim + e-posta) + posta gönder ikonu.
  - **Çıkış Yap:** kırmızı kenarlıklı tam genişlik buton.
- Rol bazlı içerik: Alıcı kullanıcısı `Beyza Demir / Operasyon Sorumlusu / Demo Alıcı`, Üretici kullanıcısı `Selçuk Aydın / Üretim Yöneticisi / Demo Üretici` görüyor.

### 15.9 AppShell — Logo Duruşu ve Başlık

Önceki sorun:

- AppBar'ın sağ üstündeki beyaz logo kutusu yamuk görünüyordu, brand kimliği zayıftı.

Yapılanlar (`lib/shared/widgets/app_shell.dart`):

- Sağ taraftaki logo kutusu kaldırıldı.
- Başlıkta: 38×38 yumuşak gri arkaplanlı logo kapsülü + şirket adı + panel adı bir arada.
- Hem yatay (Alıcı) hem kare (Üretici) logosu için aynı çerçeve uyumlu çalışıyor.
- Geri butonu olduğunda `titleSpacing` otomatik 0 oluyor.

### 15.10 Login Layout — Responsive Düzenleme

Sorun:

- Sayfada kart altında çok büyük boş alan kalıyordu; orantı bozuk görünüyordu.
- Sabit pikselli boşluklar farklı telefon boyutlarında dengesiz görünüyordu.

Yapılanlar (`lib/features/auth/presentation/login_page.dart`):

- `LayoutBuilder` ile gerçek kullanılabilir yükseklik alındı.
- `Align(Alignment(0, -0.35))` ile blok dikeyde ortanın hafif üstüne hizalandı (oransal — her telefonda aynı kompozisyon).
- Logo–kart arası `(usableHeight * 0.035).clamp(16, 28)` — küçük telefonda sıkı, büyük telefonda hafif ferah; min/max ile saçılmıyor.
- Kart–footer arası 18dp sabit (her cihazda kompakt).
- `Spacer` kaldırıldı; footer artık sayfanın altına yapışmıyor, bloğun hemen altında.
- `SingleChildScrollView` + `minHeight = usableHeight - viewInsetsBottom`: çok kısa cihazlarda scroll, klavye açıldığında kart kesilmiyor.
- Kart `maxWidth: 560` ile sınırlı (tablet/landscape için).

Sonuç:

- Pixel 4a'dan tablete kadar farklı boyutlarda aynı kompozisyon korunuyor.

### 15.11 Kalite Kontrol Durumu

- IDE lint'leri temiz (`No linter errors`).
- `flutter analyze` çağrıldı (önceki turlarda) ve `No issues found` döndü.
- Yaşam döngüsü değişiklikleri için **hot restart** gerekiyor; asset değişikliği için `flutter clean` + `flutter run` öneriliyor.

### 15.12 Açık Konular ve Sonraki Adımlar

1. Üretici aksiyonları henüz `SnackBar` ile placeholder; gerçek state mutation (sipariş onayı, aşama güncelleme, revizyon formu) bağlanacak.
2. Mock veriden Supabase repository katmanına geçiş.
3. Şifre sıfırlama gerçek e-posta akışına bağlanacak.
4. Taslak siparişler için yerel veya backend storage kararı (şu an buton kaldırıldı).
5. Üretici thumbnail'ı şu anda gradient placeholder; gerçek model görselleri eklenecek.
6. Müşteri ile sayfa/sekme yapısı netleştikten sonra şirket bazında genişletme (multi-tenant) opsiyonu değerlendirilecek.
7. PRD'deki revizyon akışında Alıcı'in **revizyon yanıtı** UI'ı (Takip detayında) henüz yok — bağlanacak.
8. Stitch dokümanındaki **matris sipariş tablosu** (renkler satır, bedenler sütun) tasarımı için müşteri kararı bekleniyor; mevcut "her renk için ayrı kart" kurgusu bu kararla yeniden değerlendirilecek.

---

## 16) 7 Mayıs 2026 (gece) — Ürün Görselleri, Sipariş Önizleme, Profil Sadeleştirme

### 16.1 Ürün Görselleri (Asset’ler)

Yapılanlar:

- `assets/images/products/` klasörü oluşturuldu; müşteri tarafından sağlanan üç ürün fotoğrafı projeye alındı:
  - `md_2024_x01.png` → `MD-2024-X01` (Klasik Ağır Kumaş Polo)
  - `tx_882_cr.png` → `TX-882-CR` (Premium Pamuk Bisiklet Yaka)
  - `hd_140.png` → `HD-140` (Kapüşonlu Sweatshirt)
- `pubspec.yaml` içine `assets/images/products/` eklendi (asset bundle’a dahil).

### 16.2 Domain ve Mock Katalog

Yapılanlar:

- `ProductModel` sınıfına `imageAsset` alanı eklendi (`lib/features/catalog/domain/product_model.dart`).
- `mock_catalog.dart` içinde her ürün için ilgili asset yolu tanımlandı (`lib/features/catalog/data/mock_catalog.dart`).

### 16.3 Katalogda Görseller

Yapılanlar (`lib/features/catalog/presentation/catalog_page.dart`):

- Ürün kartındaki gradient placeholder kaldırıldı.
- `AspectRatio` + `ClipRRect` + `Image.asset(..., fit: BoxFit.cover)` ile gerçek ürün görseli gösteriliyor; arka plan için hafif `surfaceMuted` kullanılıyor.

### 16.4 Sipariş Oluşturma — Teknik Kart Önizlemesi

Yapılanlar (`lib/features/orders/presentation/create_order_page.dart`):

- `_TechnicalInfoCard` sol üstteki ikonlu gradient kutu yerine seçili modelin `imageAsset` ile 56×56 küçük önizleme gösteriyor.
- Küçük görsele tıklanınca `_ProductPreviewDialog` açılıyor:
  - Koyu yarı saydam arka plan (`barrierColor`).
  - `InteractiveViewer` ile parmakla yakınlaştırma (min 1×, max 4×).
  - Üstte model kodu + adı; sağ üstte kapatma (`X`).
- Thumbnail üzerinde küçük zoom ikonu + tooltip (`Görseli büyüt`) ile tıklanabilirlik ipucu verildi.

### 16.5 Üretici Listelerinde Görseller

Yapılanlar (`lib/features/producer/presentation/widgets/producer_order_card.dart`):

- `_ModelThumbnail` artık sabit gradient + ikon değil; `order.product.imageAsset` ile 64×64 `BoxFit.cover` görsel gösteriyor.

### 16.6 Hesap (Profil) — Bildirim Tercihleri Kaldırıldı

İstem:

- Hem Alıcı hem Üretici hesap ekranında “Bildirim Tercihleri” kartı istenmiyor; koddan tamamen silinsin.

Yapılanlar (`lib/features/profile/presentation/profile_page.dart`):

- Bildirim bölümü başlığı + kartı kaldırıldı.
- İlgili state (`_notifications` map’i) silindi.
- Kullanılmayan yardımcı sınıflar silindi: `_NotificationPrefs`, `_NotificationTile`, `_ChannelToggle`.
- Sayfa alt başlığı metni güncellendi: artık “bildirim tercihleri” ifadesi yok; “Profil bilgilerinizi ve oturum güvenliğinizi yönetin.”

### 16.7 Kalite ve Çalıştırma Notu

- IDE lint kontrolü temiz.
- Yeni asset klasörü eklendiği için değişiklikleri görmek için **`flutter clean` + `flutter pub get` + `flutter run`** önerilir (hot reload asset bundle’ı güncellemez).

### 16.8 §15.12 ile İlişki

- Önceki "Üretici thumbnail'ı gradient placeholder" maddesi bu oturumla **geçersiz kılındı**; üretici kartlarında da gerçek ürün görseli kullanılıyor.

---

## 17) 8 Mayıs 2026 (akşam) — TextileFlow Onay Pop-up'ı

Bu oturumda yapılan tüm değişiklikler tek dosyada toplandı: `lib/features/orders/presentation/create_order_page.dart`.

### 17.1 Onay Dialog'u Eklendi

İstem:

- Alıcı panelinde "Siparişi Gönder" butonuna basıldığında bir pop-up çıksın; sipariş özeti gösterilsin, "Emin misiniz?" tarzı bir soru sorulsun. Evet → gönder, Hayır → düzenlemeye dön.

Yapılanlar:

- `_OrderSummary` widget'ına `onSubmit` callback'i eklendi; "Siparişi Gönder" butonu artık boş `() {}` yerine bu callback'e bağlı.
- State sınıfına `_handleSubmitTap()` metodu eklendi:
  - `showDialog<bool>` ile `_OrderConfirmDialog` açılıyor (`barrierDismissible: false` — yanlışlıkla kapanmasın).
  - Dialog `bool` döndürüyor: `true` = gönder, `false` = düzenlemeye dön.
  - Onaylanırsa form sıfırlanıyor (renkler `Siyah` + `Beyaz` default'una dönüyor, `activeSizesByColor` ve `quantities` temizleniyor) ve yeşil bir başarı `SnackBar`'ı gösteriliyor: "Sipariş başarıyla gönderildi."
  - Reddedilirse hiçbir şey değişmiyor; kullanıcı düzenlemeye geri dönüyor.
- `_OrderConfirmDialog` (StatelessWidget) içeriği:
  - **Üst:** "Siparişi Onayla" başlığı + sağ üstte `X` kapatma ikonu.
  - **Model kartı:** 52×52 thumbnail + model kodu + adı + kategori (`AppColors.surfaceMuted` arkaplan).
  - **İki istatistik kutusu** (`_SummaryStat`): "Toplam renk", "Toplam adet".
  - **Renk / Beden Detayı:** `_ColorBreakdown` widget'ları — renk swatch'ı + renk adı + satır toplamı + her aktif beden `S: 10`, `M: 20` gibi pill chip olarak.
  - **Uyarı kutusu** + soru.
  - **Aksiyonlar:** "Hayır, düzenle" ve "Evet, gönder" butonları.

### 17.2 Uyarı Kutusu Rengi: Soft Blue → Warning

İstem:

- "Emin misiniz?" uyarısı farklı bir renkte olsun.

Yapılanlar:

- Soft blue tonundan `AppColors.warning` (#F2994A) tonuna geçildi: %12 alpha arkaplan + %45 alpha kenarlık.
- Sol tarafa `Icons.warning_amber_rounded` ikonu (turuncu, 20px) eklendi.
- Metin rengi `AppColors.text` (kontrast için).

### 17.3 "Hayır, düzenle" Butonu Belirginleştirildi

İstem:

- Hayır butonu daha belirgin görünsün.

Yapılanlar:

- `TextButton` → `OutlinedButton.icon`.
- Lacivert (`AppColors.navy`) 1.5 px çerçeve + lacivert metin + sol ikon (`Icons.edit_outlined`).

### 17.4 Buton Boyut Eşitliği (Renkler Korundu)

İstem:

- Evet ve Hayır butonları boyut olarak aynı görünsün; renklere dokunulmasın.

Yapılanlar:

- Her iki buton:
  - `minimumSize: Size.fromHeight(48)`
  - Aynı padding: `EdgeInsets.symmetric(horizontal: 12, vertical: 12)`
  - Aynı şekil: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`
  - Aynı kenarlık kalınlığı: 1.5 px navy `BorderSide` (FilledButton'a aynı renkten side eklendi → çerçeve geometrisi eşit, görsel renk değişimi yok).
- İkonlar 18 px.

### 17.5 AlertDialog `actions` Genişlik Sorunu — Butonlar `content`'e Taşındı

Sorun:

- AlertDialog'un `actions` alanı Material 3'te `OverflowBar` ile davrandığı için `Row` + `Expanded` dialog genişliğini almıyor; sol buton dar kalıyordu.

Yapılanlar:

- Butonlar `actions`'tan çıkarıldı, `content` içindeki `Column`'a alındı.
- `actionsPadding` kaldırıldı; `contentPadding` alt değeri 0 → 16 yapıldı.
- `crossAxisAlignment: CrossAxisAlignment.stretch` ile butonlar gerçekten dialog genişliğini alıyor.

### 17.6 Sticky Buton Yerine İçerik Akışı

İstem:

- Butonlar pop-up'ın altında sabit kalmasın; turuncu uyarının altında, kaydırılan içeriğin parçası olsun.

Yapılanlar:

- İlk denemede `Column` → ConstrainedBox(maxHeight) + SingleChildScrollView (üst) + Row (alt sabit) yapısıyla butonlar sticky idi.
- Final yapı: tek `SingleChildScrollView` → `Column` (model kartı, istatistikler, renk listesi, turuncu uyarı, **butonlar**). Hepsi birlikte kayıyor.

### 17.7 Dialog Yükseklik Tavanı: %55 → %85

İstem:

- Detay çok olduğunda pop-up yeterince uzun olsun; az detayda küçük kalsın.

Yapılanlar:

- `ConstrainedBox(maxHeight: MediaQuery.sizeOf(context).height * 0.85)`.
- `mainAxisSize.min` ile az detayda zaten shrink ediyor; sadece tavan yükseldi.

### 17.8 Bug Fix — Gönder Sonrası Eski Adetlerin Görünmesi

Sorun:

- Sipariş gönderildikten sonra `selectedColors`, `activeSizesByColor`, `quantities` sıfırlanıyordu **ama** `TextFormField`'larda eski sayılar görünmeye devam ediyordu.
- Sebep: `TextFormField` `initialValue` ile çalışıyor; `key`'i sadece `color` + `size`'a göre değişiyordu. Reset sonrası varsayılan renkler (Siyah/Beyaz) aynı `key`'lerle yeniden kullanılınca Flutter widget state'ini koruyor, `initialValue` yeniden uygulanmıyordu.

Yapılanlar:

- State alanına `int _formVersion = 0;` eklendi.
- `_ColorSizeCard` constructor'ına `formVersion` parametresi + `super.key` eklendi.
- İç `TextFormField` ve satır `Row`'ının `ValueKey`'lerine `formVersion` dahil edildi (`input_${color}_${size}_$formVersion`).
- Dış `_ColorSizeCard`'ın `key`'i de `ValueKey('color_card_${color}_$_formVersion')` ile bağlandı.
- `_handleSubmitTap` içinde gönderim onaylandığında `_formVersion++` yapılıyor → tüm input widget'ları yeniden yaratılıyor → `initialValue` boş olarak yeniden uygulanıyor.

### 17.9 Kalite Kontrol

- IDE lint temiz (`No linter errors found`).
- `dart analyze lib/features/orders/presentation/create_order_page.dart` → `No issues found!` (birden fazla kez doğrulandı).
- Renk paleti yalnızca `AppColors` token'ları üzerinden kullanıldı: `navy`, `warning`, `text`, `textMuted`, `surfaceMuted`, `surfaceContainer`, `border`, `success`, `neutral`.

### 17.10 Sonraki Adımlar / Açık Konular

1. Şu anda gönderim sadece form'u sıfırlıyor + `SnackBar` gösteriyor; gerçek bir order entity oluşturma + repository (mock veya Supabase) çağrısı bağlanacak.
2. Üretici tarafında bu sipariş yeni "Beklemede / Onay" durumunda görünmeli; producer order list'i ile bağ kurulacak (§15.12 maddesi 1 ile ilişkili).
3. Onay dialog'unun aynı yapısı, gerektiğinde **revizyon talebi** ya da **iptal** akışlarında da yeniden kullanılabilir; ortak bir `ConfirmDialog` bileşenine çıkarmak ileride değerlendirilebilir.

---

## 18) 9 Mayıs 2026 — Revizyon akışının tamamen kaldırılması

Müşteri isteği: revizyon süreci netleşmediği için uygulamadan tamamen çıkarıldı.

### Yapılanlar / Çözüm

- `ProducerRevisionsPage` ve dosyası `producer_revisions_page.dart` silindi.
- Üretici alt sekmeleri **Gelenler / Üretim / Hesap** olacak şekilde 4’ten 3’e indirildi (`app_shell.dart`); üretici için sekme indeksleri `/catalog`, `/orders/new`, `/profile` ile hizalandı.
- Üretici rolü `/tracking` URL’sine giderse (eski derin link) `/catalog`’a yönlendiriliyor (`router.dart`).
- `ProducerOrder` içinden `revisionNote` kaldırıldı; mock `LP-1202` durumu `submitted` yapıldı (`producer_order.dart`).
- Gelenler: `revision_requested` filtresi, “Revizyon Talep Et” / “Revizyon Detayı” aksiyonları ve revizyon metinleri kaldırıldı (`producer_orders_page.dart`).
- `ProducerOrderCard` içindeki sarı vurgulu not alanı (`highlightNote`) ve ilgili UI kaldırıldı.
- Alıcı Takip: “Revizyon” durum filtresi kaldırıldı; örnek sipariş `TF-98430` durumu `in_production` yapıldı (`tracking_page.dart`).
- `StatusBadge.order` içinde `revision_requested` eşlemesi kaldırıldı (`status_badge.dart`).

### Durum

- Revizyon durum anahtarı ve UI metinleri `lib` altında kalmadı.
- IDE lint: ilgili dosyalarda sorun raporu yok.

### Sonraki adımlar

- PRD / tasarım dokümanlarındaki revizyon maddeleri ihtiyaç halinde ayrıca güncellenebilir (bu oturumda yalnızca Flutter `lib` ve ilerleme kaydı güncellendi).

---

## 19) 9 Mayıs 2026 (devam) — Güncelleme talepleri, katalog renk galerisi, kararlar

### 19.1 Sipariş güncelleme talepleri (Alıcı ↔ Üretici)

**Amaç:** Revizyon ekranı kalktıktan sonra “sipariş güncelleme talebi” dilinde ayrı bir ileti dizisi; Üretici’nun aynı talebe tekrar onay vermemesi ve listelerde doğru “bekliyor” hissi.

**Domain / notifier (`lib/features/requests/`):**

- `request_thread.dart`: zaman çizelgesi giriş türleri, `sortedEntries`, `hasPendingBuyerRequest` — kronolojide **son giriş** `aliciTalep` ise Üretici yanıtı bekleniyor kabulü.
- `request_threads_notifier.dart`: `addBuyerRequest`, üretici `producerApprove` / `producerGeriBildirim`, thread oluşturma vb.

**UI:**

- Liste: `producer_requests_page.dart` — diziler `hasPendingBuyerRequest` ve güncelliğe göre sıralanır; **“Yanıt gerekli” / “Güncel”** chip ve turuncu vurgu.
- Detay: `request_thread_detail_page.dart` — Üretici onay/geri bildirim alanı **yalnızca** `hasPendingBuyerRequest` iken; aksi bilgilendirme kartı.
- Alıcı: yeni talep **göndermeden önce** `AlertDialog` (sipariş no + metin özeti + İptal / Gönder); beklemede bilgi bandı (son talep Üretici’da bekliyor).

**Routing:** `/requests` ve `thread/:threadId` shell içi uyumu (`router.dart`, `app_shell.dart` ile uyumlu).

**Kalite:** `dart analyze` ilgili alanlar temiz.

### 19.2 Katalog: model başına kaydırılabilir renk galerisi

**İstem:** Alıcı katalog kartlarında tek görsel yerine ilgili modelin tüm renk varyantları yatay galeride; sipariş oluşturmada ise tek renge odaklı önizleme.

**Domain:** `catalog/domain/product_model.dart` — `ProductColorVariant` (`colorName`, `imageAsset`); `ProductModel.colorVariants`; geriye uyum `imageAsset` getter → ilk varyant; `imageAssetForColor`, `imageAssetPreferringColors`.

**Mock:** `catalog/data/mock_catalog.dart` — her model için çoklu varyant (şimdilik bazı renkler aynı PNG’ye bağlı; gerçek dosyalar eklendiğinde sadece yollar güncellenir).

**UI:**

- `catalog/presentation/catalog_page.dart` — `_CatalogVariantGallery` (`PageView` + sayfa göstergesi + aktif renk etiketi).
- `orders/presentation/create_order_page.dart` — tek küçük önizleme / zoom: seçili renk sırasının **ilk** rengine göre; onay diyaloğu küçük görsel `imageAssetPreferringColors(orderedColors)`.
- `tracking_order_detail_page.dart` — özet küçük görsel ilk sipariş satırı rengine göre.
- `producer/.../producer_order_card.dart` — thumbnail `colorBreakdown` anahtar sırasına göre ilk eşleşen görsel.

### 19.3 Ürün görselleri ve gerçek veri — bilinçli erteleme

Backend/PIM bağlanana kadar **gerçek URL + renk başına gerçek farklı foto** işi yazılımcı için orta çaba; ana maliyet veri/model eşlemesi ve DAM içeriği olduğu için **tam uygulama olgunlaştıktan sonra** yeniden değerlendirilecek.

Müşteri tarafında kafa karışıklığı çıkarsa (mock’ta görsel sabit olduğu süre): katalog yeniden tek ana görsele indirgenebilir; bu karar bekletildi.

### Durum / sonraki adımlar

1. Güncelleme talepleri: backend ve sipariş `status` alanı hâlâ ayrı mock katmanları; istenirse ileride eşlenecek.
2. Katalog görselleri: API şeması + `Repository` bağlandığında `Image.network` / `cached_network_image` ile genişletilebilir.

---

## 20) 13 Mayıs 2026 — Üretici katalog yönetimi (mock), görsel UX, yönlendirme düzeltmeleri

### Yapılanlar

**Ortak bellek içi katalog (mock):**

- `lib/features/catalog/application/catalog_list_provider.dart` — `CatalogListNotifier` (`upsert`, `removeByCode`), `catalogListProvider`; başlangıç `mockCatalog` kopyası.

**Ürün durumu «Taslak» ve Alıcı görünürlüğü:**

- `Taslak` ürünler Alıcı katalog ve sipariş model seçiminde listelenmiyor (`catalog_page.dart`, `create_order_page.dart`).
- Takip ve sipariş özetlerinde ürün görseli `catalogListProvider` ile güncel modele bağlandı (`tracking_page.dart`, `tracking_order_detail_page.dart`).

**Üretici — katalog admin UI:**

- `lib/features/producer/catalog_admin/presentation/producer_catalog_admin_page.dart` — liste, durum filtreleri, arama, sil (onaylı), düzenle navigasyonu.
- `lib/features/producer/catalog_admin/presentation/producer_catalog_product_editor_page.dart` — yeni/düzenle formu; kategori ve durum (`Taslak` / `Stokta` / `Numune`); renk satırları.

**Yönlendirme:**

- `lib/app/router.dart` — `/producer/catalog-admin` (shell içi); `/producer/catalog-admin/new` ve `.../edit` **ShellRoute dışında** kök navigator’da tanımlandı (Shell içinde `parentNavigatorKey` ile alt rota bazen «page not found» üretiyordu).
- `lib/features/producer/presentation/producer_orders_page.dart` — «Ürün kataloğu» kartı → `context.push('/producer/catalog-admin')`.

**Form / UI ince ayarları:**

- `DropdownButtonFormField`: `value` → `initialValue` + kategori/durum için `ValueKey` (Flutter deprecations).
- Renk kartı: başlık ile «Renk adı» arası boşluk; önizleme `BoxFit.contain` + `AspectRatio(4/5)` + çerçeve; ikinci renk eklenince layout sıçramaması için kapatma ikonu yokken `48×48` boşluk; kartlar arası tutarlı `SizedBox`.

**Telefondan görsel — UI ve istemci seçimi:**

- `pubspec.yaml` — `image_picker: ^1.1.2`.
- Ürün düzenleyicide birincil aksiyon: **Galeri** / **Kamera** (`FilledButton.tonalIcon`); `ExpansionTile` altında **Örnek görsel** (mevcut asset dropdown); bilgilendirici metinler (Supabase yükleme sonrası kalıcılık).
- `lib/shared/widgets/catalog_display_image.dart` (+ `catalog_display_image_io.dart` / `catalog_display_image_web.dart`) — `assets/…`, `http(s)://…`, mobilde yerel dosya yolu ile gösterim; ilgili katalog/sipariş/takip/üretici thumbnail yerleri `catalogDisplayImage` kullanacak şekilde güncellendi.
- **Android:** `CAMERA`, `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE` (maxSdk 32). **iOS:** `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`.
- Web: galeri/kamera tıklanınca kısa bilgi `SnackBar` (yerel path akışı mobil odaklı).

### Sorunlar

- ShellRoute içinde `parentNavigatorKey` ile tanımlı `new` / `edit` alt rotalarında **Page not found** görülmesi.

### Çözümler

- Katalog düzenleyici tam ekran rotaları shell dışına taşındı; liste sayfası shell içinde kaldı.

### Durum

- `dart analyze lib` son kontrol: sorun yok (tip uyumu: `CachedNetworkImage` için `Alignment` parametresi io/web impl’de düzeltildi).

### Sonraki adımlar

1. Supabase Storage ile dosya yükleme + ürün/variant kaydında **kalıcı URL veya path** saklama.
2. `AppShell` üretici sekmesinde `/producer/catalog-admin` iken seçili sekme indeksinin netleştirilmesi (isteğe bağlı UX).
3. Geçici dosya yollarının uygulama yeniden başlatılmasından sonra geçersiz kalması — backend bağlanınca giderilecek; gerekirse kullanıcıya kısa uyarı.

---

## 21) 14 Mayıs 2026 — Takip detayı, sıralama, talepler UI, Excel tarihi, sağlamlaştırma

### Yapılanlar

**Sipariş takip (Alıcı) — detay ve liste:**

- `tracked_order_lookup.dart` + `mock_tracked_orders.dart` içinde `trackedOrderByCode` köprüsü; `TrackedOrdersNotifier` içinde `syncTrackedOrdersLookup` (`build` / `append`).
- `TrackedOrder` modeline `createdAt` (`DateTime`) eklendi; tohum veriler ve `create_order_page.dart` yeni sipariş üretimi buna yazıyor.
- `tracking_page.dart`: filtre sonrası `createdAt` ile sıralama; Üretici’daki gibi **yalnızca ok ikonu** ile yön değiştirme (`IconButton`, `tooltip`).
- Takip detay rotası: `router.dart` içinde `/tracking` alt rotası `order/:orderNo` + `parentNavigatorKey: rootNavigatorKey` (shell ile navigator çakışması / donma riskini azaltmak için); `TrackingOrderDetailLoader` (`Consumer` + `ref.watch`) ve `context.push(..., extra: order)` (`tracking_page.dart`, `tracking_order_detail_page.dart`).
- Takip detayında sipariş notu: düzenleme + **Kaydet** kaldırıldı; salt okunur `_BuyerOrderNoteDisplay` (`buyerOrderNotesProvider`).

**Güncelleme talepleri (Alıcı listesi) — kafa karışıklığı:**

- `request_thread_order_status_row.dart`: “**Sipariş durumu**” etiketi + rozet; liste kartlarında rozet üst satırdan ayrıldı (`buyer_requests_page.dart`, `producer_requests_page.dart`); detay üst kartta aynı satır (`request_thread_detail_page.dart`).

**Üretici Excel / üretici model:**

- `ProducerOrder` alanı **`orderedAt`** (sipariş verilme anı); Excel ve önizlemede tarih hücresi artık **`dueAt` (termin) değil `orderedAt`**; başlık metni **`SİPARİŞ TARİHİ`** (`producer_order_excel.dart`, `producer_order_excel_preview_sheet.dart`, `producer_order.dart` mock + `create_order_page.dart`).

**Genel sağlamlaştırma:**

- `product_model.dart`: `colorVariants` boşken `primaryImageAsset` için yedek yol (`.first` `RangeError` önlemi).
- `producer_order_detail_page.dart`: `_previewColorLabel` için boş variant koruması.
- `main.dart`: `kDebugMode` iken `FlutterError.onError` + `PlatformDispatcher.instance.onError` ile konsola ek `debugPrint` (kırmızı ekran kök nedenini terminalden yakalamak için).

### Sorunlar

- Takip detayında eski üst seviye `trackedOrderByCode` çağrısı / hot reload sonrası `NoSuchMethodError`.
- Detayda “Sipariş bulunamadı” veya navigasyonda donma hissi (shell dışı kök rota + `ProviderScope.containerOf` birlikteliği şüphesi).
- Güncelleme talepleri listesinde sipariş durumu rozetinin “talep onayı” sanılması.
- Excel’de “TARİH” hücresinin termin ile özdeş okunması.

### Çözümler

- Köprü + `Consumer` yükleyici + `extra` ile tutarlı çözüm; rota shell altına alınıp tam ekran için `rootNavigatorKey`.
- Talep kartında açık “Sipariş durumu” satırı + `tooltip`.
- Excel’de `orderedAt` ve etiket netliği.

### Durum

- `dart analyze` / `flutter test` / örnek `flutter build apk --debug`: bu oturumda kontrol edilen kapsamda sorun raporu yok.

### Sonraki adımlar

1. Kırmızı ekran devam ederse: cihaz/IDE konsolundaki **ilk exception satırı + stack** ile tekrar triyaj (şu an log yalnızca debug’da zenginleştirildi).
2. İstenirse üretici sipariş detayında **“Sipariş tarihi”** metası ayrıca chip olarak gösterilebilir (şu an Excel/termin ayrımı modelde hazır).

---

## 22) 15 Mayıs 2026 — Katalog onayı, termin, sıralama UI, Türkçe takvim

### Yapılanlar

**Üretici — katalog ürün kaydı onay pop-up’ı:**

- `lib/features/producer/catalog_admin/presentation/producer_catalog_product_editor_page.dart`
- Yeni ürün ve düzenleme: Kaydet öncesi `_CatalogProductConfirmDialog` (model özeti, renk/görseller, taslak uyarısı, «Hayır, düzenle» / «Evet, kaydet» veya «Evet, güncelle»).
- SnackBar metinleri ekleme / güncelleme için ayrıldı.

**Katalog düzenleyici — «Hazır görsel» etiketi:**

- `ExpansionTile` içinde yüzen `labelText` kesiliyordu; etiket `InputDecoration.labelText` ile «Renk adı» ile aynı outlined yapıda; kart `clipBehavior: Clip.none`.

**Sipariş tarihi ve termin (Alıcı ↔ Üretici):**

- `lib/shared/order_date_labels.dart` — Türkçe uzun tarih (`8 Mart 2024` vb.), `dateOnly`.
- Alıcı sipariş oluşturma: `_DueDateCard` + `showDatePicker`; varsayılan +21 gün; termin `ProducerOrder` ve `TrackedOrder`’a yazılıyor.
- Onay diyaloğu (`create_order_page.dart`): termin özeti kutusu.
- `TrackedOrder`: `dueAt`, `dueAtLabel`; tohum veri + takip detayında «Termin» satırı.
- Üretici gelen sipariş detayı: «Sipariş: …» chip’i (`orderedAt`, `producer_order_detail_page.dart`).

**Liste sıralama satırı — tek tip UI:**

- `lib/shared/widgets/list_sort_count_row.dart` — solda filtrelenmiş adet (`N sipariş` / `N talep`), sağda ok; «Termin: Yakın→Uzak» vb. metinler kaldırıldı.
- Kullanım: `tracking_page.dart`, `producer_orders_page.dart`, `producer_production_page.dart`, `producer_requests_page.dart`.
- Ok mantığı korundu (↑ = varsayılan mod; Takip/taleplerde yeni önce, Gelenler/Üretimde termin yakın önce). İleride ok yanına kısa ibare eklenebilir.

**Türkçe takvim:**

- `pubspec.yaml`: `flutter_localizations`.
- `lib/app/app.dart`: `locale: tr_TR`, delegeler.
- Termin `showDatePicker`: `locale: tr_TR` (`create_order_page.dart`).

### Sorunlar

- Sıralama satırlarında farklı açıklama metinleri (termin / tarih) tutarsız görünüyordu.
- `ExpansionTile` + `clipBehavior` yüzünden «Hazır görsel» etiketi yarım.
- Termin sabit +21 gün; kullanıcı seçemiyordu.
- Üretici detayda yalnızca termin, sipariş oluşturma tarihi yoktu.
- Takvim İngilizce ay/gün adlarıyla açılıyordu.

### Çözümler

- Ortak `ListSortCountRow` + adet gösterimi.
- Outlined alan + `Clip.none`; onay diyalogları katalog ve sipariş için.
- Termin seçimi ve model alanları; `order_date_labels` ile tutarlı etiketler.
- Uygulama geneli `tr_TR` yerelleştirme.

### Durum

- `dart analyze` (ilgili dosyalar): sorun yok.
- §21 madde 2 (sipariş tarihi chip) bu oturumda Üretici detayda karşılandı.

### Sonraki adımlar

1. Ok yanına isteğe bağlı kısa sıra ibareleri («yeni önce», «termin yakın»).
2. Alıcı güncelleme talepleri listesine sıralama + `ListSortCountRow` (şu an yok).
3. Supabase bağlantısında termin ve `orderedAt` sunucu doğrulaması.

---

## 23) 17 Mayıs 2026 — Backend başlangıç: `database/` ve `backend/` ayrımı

### Yapılanlar

- Repo kökünde iki ayrı klasör kararı:
  - [`database/`](database/) — yalnızca PostgreSQL: `migrations/`, `policies/`, `seeds/`, kurulum [`database/README.md`](database/README.md)
  - [`backend/`](backend/) — Edge Functions / webhook (Faz 7); [`backend/README.md`](backend/README.md)
- Plan dosyası klasör yapısı buna göre güncellendi.

### Sizin yapmanız gerekenler (şimdi)

1. [`database/README.md`](database/README.md) dosyasını açıp **1–5. adımları** sırayla uygulayın (Supabase hesap, sign-up kapalı, SQL çalıştırma — SQL dosyaları Agent modunda eklenecek).
2. 4 test kullanıcısı + `seeds/dev_seed.sql` içinde UUID yer tutucularını doldurun.
3. Hazır olunca geliştiriciye yalnızca **Project URL** + **anon key** iletin (`service_role` paylaşmayın).

### Durum

- `database/migrations/001_core.sql` … `006_notifications.sql` eklendi.
- `database/policies/001_rls.sql`, `002_storage_rls.sql` eklendi.
- `database/seeds/dev_seed.sql` eklendi (UUID yer tutucuları doldurulacak).
- `frontend/.env.example` eklendi.

### Sonraki adımlar

1. **Siz:** [`database/README.md`](database/README.md) — Supabase proje + SQL sırası + 4 kullanıcı + seed UUID.
2. Flutter `Supabase.initialize` + repository (Faz 3).
3. Frontend: şifre, Taslak/Yayında, termin (mock; depolama çubuğu Faz 4b).

---

## 24) 17 Mayıs 2026 — Flutter Supabase Auth bağlantısı (Faz 3 başlangıç)

### Yapılanlar

- `flutter_dotenv` + `.env` asset; `.gitignore` içine `.env`.
- [`lib/core/config/app_env.dart`](frontend/lib/core/config/app_env.dart), [`supabase_bootstrap.dart`](frontend/lib/core/config/supabase_bootstrap.dart).
- [`SupabaseAuthRepository`](frontend/lib/features/auth/data/auth_repository.dart): `signInWithPassword` + `profiles` tablosundan rol; profil yoksa «Hesabınız henüz tanımlanmadı».
- [`session_controller.dart`](frontend/lib/features/auth/application/session_controller.dart): Supabase oturumu «Beni hatırla» ile geri yükleme; çıkışta `signOut`.
- `.env` yoksa veya eksikse otomatik **mock auth** (geliştirme yedek).

### Sizin test adımları

1. `.env` dolu olduğundan emin olun (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
2. `flutter pub get` → `flutter run`.
3. Seed’deki e-posta/şifre ile giriş (Dashboard’da oluşturduğunuz şifre).
4. Profil satırı yoksa: `dev_seed.sql` UUID’leri doğru mu kontrol edin.

### Sonraki adımlar

1. Katalog + sipariş repository (Supabase).
2. Frontend: şifre değiştirme, Taslak/Yayında, termin.
3. Storage upload + depolama çubuğu (Faz 4b).

---

## 25) 17 Mayıs 2026 — Android emülatör siyah ekran düzeltmesi

### Sorun

`flutter run` logunda Supabase başarılı olmasına rağmen emülatörde siyah ekran; `FlutterRenderer: Width is zero`, GoRouter `child` null iken `SizedBox.shrink()`.

### Yapılanlar

- [`app_bootstrap.dart`](frontend/lib/app/app_bootstrap.dart): `runApp` hemen; Supabase init arka planda, beyaz yükleme ekranı.
- [`app.dart`](frontend/lib/app/app.dart): `themeMode: light`, router `child` null → beyaz fallback.
- Oturum geri yükleme: 8 sn timeout + hata yakalama; splash yalnızca redirect.
- Android: Impeller opt-out kaldırıldı; gece teması launch arka planı beyaz.
- Eksik logo: [`brand_logo_image.dart`](frontend/lib/shared/widgets/brand_logo_image.dart) çökmez.

### Test

`flutter run` → beyaz yükleme → giriş ekranı. Logo dosyaları için `assets/logos/` (textileflow.png, producer_logo.png) ekleyin.

---

## 26) 17 Mayıs 2026 — Faz 4 + Dal A (katalog Supabase, UI)

### Yapılanlar

**Katalog (Supabase)**
- [`catalog_status_mapper.dart`](frontend/lib/features/catalog/data/catalog_status_mapper.dart): `Taslak`/`Yayında` ↔ `draft`/`published`
- [`supabase_catalog_repository.dart`](frontend/lib/features/catalog/data/supabase_catalog_repository.dart): listeleme, CRUD, Storage `catalog-images` yükleme
- [`catalog_list_provider.dart`](frontend/lib/features/catalog/application/catalog_list_provider.dart): yükleme/hata durumu; giriş sonrası yenileme
- Mock: Stokta/Numune → Yayında ([`mock_catalog.dart`](frontend/lib/features/catalog/data/mock_catalog.dart))

**UI**
- Üretici katalog admin: filtre Tümü / Taslak / Yayında
- Üretici ürün editör: kayıt Supabase + fotoğraf upload
- Alıcı katalog: `buyerCatalogItemsProvider` (yalnızca Yayında)
- Termin: [`shared/date_input.dart`](frontend/lib/shared/date_input.dart) + elle yazma ([`create_order_page.dart`](frontend/lib/features/orders/presentation/create_order_page.dart))
- Profil: gerçek şifre değiştirme (`auth.updateUser`)

### Test

1. `flutter run` — Supabase ile giriş
2. Alıcı katalog: seed’deki 3 ürün (Yayında)
3. Üretici: yeni ürün / fotoğraf / Taslak vs Yayında
4. Sipariş formu: termin `17.05.2026` yazımı
5. Hesap → Şifreyi değiştir

### Sonraki adımlar

1. ~~Faz 4b: Üretici depolama çubuğu~~ (§27)
2. Faz 5: Siparişler Supabase
3. Faz 8b: PDF

---

## 27) 20 Mayıs 2026 — Faz 4b (Üretici depolama çubuğu)

### Yapılanlar

**Hesaplama**
- [`catalog_storage_service.dart`](frontend/lib/features/producer/catalog_admin/data/catalog_storage_service.dart): kullanım = `max(DB file_size_bytes, Storage listesi, Storage URL info)`; klasör taramasında `storage.info()` ile boyut; join sorgusu `catalog_models!inner`
- Kota: `.env` → `STORAGE_QUOTA_BYTES` (varsayılan 1 GB)
- [`supabase_ready_provider.dart`](frontend/lib/core/config/supabase_ready_provider.dart): `catalogRepositoryProvider` Supabase hazır olunca yeniden bağlanır
- [`catalog_storage_usage_provider.dart`](frontend/lib/features/producer/catalog_admin/application/catalog_storage_usage_provider.dart): oturum değişince invalidate; sayfa açılışında `refresh`

**UI**
- [`catalog_storage_usage_bar.dart`](frontend/lib/features/producer/catalog_admin/presentation/catalog_storage_usage_bar.dart): Üretici **Katalog** — «Görsel depolama» kartı (Supabase yoksa bilgi kartı; hata + Yenile)
- Çubuk: %80+ turuncu, dolu kırmızı; **%0’da `value: 0`** (belirsiz animasyon kapatıldı)
- Yükleme engeli: `ensureCanAdd` — editörde fotoğraf seçimi + kayıt/upload öncesi
- Kayıtta `file_size_bytes` yazılıyor; silme/güncelleme sonrası çubuk yenileniyor

**Not (0 MB normal)**
- Seed / boş `image_url` ürünlerde ekran `assets/...` örnek görseli gösterir; Storage’da dosya yoksa çubuk **0.0 MB** kalır. Gerçek galeri/kamera yüklemesi sonrası artar.

### Test

1. Üretici giriş → **Katalog** sekmesi → «Görsel depolama» kartı (animasyonsuz boş çubuk @ %0)
2. Ürün düzenle → galeriden fotoğraf → kaydet → MB artmalı
3. Kotayı düşük tutup (`.env`) büyük dosya → uyarı metni
4. Supabase Dashboard → Storage → `catalog-images` → şirket klasörü (dosya yoksa 0 MB doğru)

### Sonraki adımlar

1. ~~Faz 5: Siparişler Supabase~~ (§28 — temel akış)
2. Faz 6: İstekler
3. Faz 8b: PDF

---

## 28) 20 Mayıs 2026 — Faz 5 (siparişler Supabase, temel)

### Yapılanlar

**Veri katmanı**
- [`orders_repository.dart`](frontend/lib/features/orders/data/orders_repository.dart) + [`supabase_orders_repository.dart`](frontend/lib/features/orders/data/supabase_orders_repository.dart)
- Oluşturma: `orders` + `order_lines` (alıcı RLS); `TF-` / `LP-` kod üretimi
- Listeleme: alıcı `fetchBuyerOrders` → `TrackedOrder`; üretici `fetchProducerOrders` → `ProducerOrder`
- Durum: `approved`, `in_production` (+ `cutting` aşama), `shipped`; `order_status_events` tetikleyici ile log
- [`production_stage_mapper.dart`](frontend/lib/features/orders/data/production_stage_mapper.dart): Kesim/Dikim/… ↔ DB enum

**Riverpod**
- [`tracked_orders_notifier.dart`](frontend/lib/features/orders/application/tracked_orders_notifier.dart): Supabase veya mock seed; giriş sonrası `refresh`
- [`producer_orders_notifier.dart`](frontend/lib/features/producer/application/producer_orders_notifier.dart): `approve` / `startProduction` / `updateProductionStage` / `markShipped`

**UI bağlantısı**
- [`create_order_page.dart`](frontend/lib/features/orders/presentation/create_order_page.dart): «Siparişi Gönder» → Supabase (model `id` + yayında kontrolü)
- [`producer_order_detail_page.dart`](frontend/lib/features/producer/presentation/producer_order_detail_page.dart): Onayla / Üretime al → DB
- [`producer_production_page.dart`](frontend/lib/features/producer/presentation/producer_production_page.dart): aşama + sevk
- `ProducerOrder.buyerNote` ← `orders.buyer_note`

### Test

1. Alıcı: katalogdan model → Sipariş → gönder → **Takip** listesinde görünmeli
2. Üretici: **Gelenler** → yeni sipariş → Onayla → Üretime al → **Üretim** sekmesi
3. Alıcı takipte durum güncellenmeli (yenile / sekme değiştir)
4. Mock mod (Supabase yok): eski seed + bellek davranışı devam eder

### Sonraki adımlar (Faz 5+)

1. ~~Sipariş detay timeline (`order_status_events` UI)~~ (§29)
2. Faz 6: İstekler Supabase
3. Faz 8b: PDF gerçek sipariş verisi

---

## 29) 20 Mayıs 2026 — Faz 5b (sipariş durum zaman çizelgesi)

### Yapılanlar

- [`order_status_event.dart`](frontend/lib/features/orders/domain/order_status_event.dart) + [`order_status_timeline_provider.dart`](frontend/lib/features/orders/application/order_status_timeline_provider.dart)
- Supabase: `order_status_events` listesi (`fetchStatusEvents`); mock: [`mock_order_status_timeline.dart`](frontend/lib/features/orders/data/mock_order_status_timeline.dart)
- [`order_status_timeline_card.dart`](frontend/lib/features/orders/presentation/order_status_timeline_card.dart): Alıcı **Takip detay** → «Durum geçmişi»
- `TrackedOrder.id` — olay sorgusu için

### Test

1. Takip → sipariş detay → «Durum geçmişi» (gönderildi → … → güncel adım vurgulu)
2. Üretici onayladıktan sonra Alıcı detayı yenileyince yeni adım görünmeli

### Sonraki adım

~~**Faz 6 — İstekler Supabase**~~ (§30)

---

## 30) 20 Mayıs 2026 — Faz 6 (güncelleme talepleri Supabase)

### Yapılanlar

- [`requests_repository.dart`](frontend/lib/features/requests/data/requests_repository.dart) + [`supabase_requests_repository.dart`](frontend/lib/features/requests/data/supabase_requests_repository.dart)
- Tablolar: `order_update_threads` (sipariş başına 1), `order_update_entries` (`buyer_request` / `producer_approval` / `producer_feedback`)
- [`request_threads_notifier.dart`](frontend/lib/features/requests/application/request_threads_notifier.dart): Supabase veya mock seed; giriş sonrası yenileme
- Alıcı: talep gönder; Üretici: onay + geri bildirim; okunmamış rozet mantığı (son kayıt türüne göre)
- Takip ekranından «Güncelleme talebi» → thread oluştur / aç (`ensureThread` async)

### Test

1. Alıcı: Supabase siparişi → Takip → Güncelleme talebi → metin gönder
2. Üretici: **Alıcı** sekmesi → talep görünür → Onayla veya geri bildirim
3. Alıcı: **İstekler** listesinde thread + Üretici yanıtı

### Sonraki adımlar

1. ~~**Faz 8b** — PDF~~ (§31)
2. ~~**Faz 7** — Bildirimler (uygulama içi)~~ (§31); push: `backend/functions/send-push`

---

## 31) 20 Mayıs 2026 — Faz 8b + Faz 7 (PDF + uygulama içi bildirimler)

### Yapılanlar

**PDF (Alıcı)**
- [`buyer_order_pdf.dart`](frontend/lib/features/orders/export/buyer_order_pdf.dart): sipariş özeti, renk/beden tablosu, not; `printing` ile paylaş
- Takip listesi + detay: **PDF İndir** aktif
- `TrackedOrder.buyerNote` ← `orders.buyer_note`

**Bildirimler (uygulama içi)**
- [`007_notification_triggers.sql`](database/migrations/007_notification_triggers.sql): yeni sipariş → Üretici; durum → Alıcı; talep/yanıt → karşı taraf
- [`supabase_notifications_repository.dart`](frontend/lib/features/notifications/data/supabase_notifications_repository.dart)
- Hesap sayfası: **Bildirimler** listesi; üst çubuk: zil + okunmamış sayısı
- Push (FCM): yalnızca iskelet [`backend/functions/send-push/index.ts`](backend/functions/send-push/index.ts) — Firebase kurulumu sizde

**Saat dilimi**
- [`supabase_instant.dart`](frontend/lib/shared/supabase_instant.dart): offset’siz UTC string düzeltmesi

### Supabase’de sizin yapmanız gereken (test öncesi)

SQL Editor’da sırayla (README tablosu): **`007_notification_triggers.sql`** çalıştırın (daha önce 001–006 + policies yapıldıysa yalnızca bu dosya).

### Test planı (uçtan uca)

1. **Alıcı:** katalog → sipariş gönder → Takip → PDF İndir → Güncelleme talebi  
2. **Üretici:** Gelenler → onay → üretim; **Alıcı** sekmesi → talep yanıtı  
3. **Her iki hesap:** Hesap → Bildirimler; üstte zil sayacı  
4. Emülatör saat dilimi: **İstanbul (GMT+3)**

---

## 32) 25 Mayıs 2026 — `.env` düzeltmesi, APK build, performans değerlendirmesi

### 32.1 `.env` tırnak işareti sorunu

**Sorun:**

- `.env` dosyasındaki `SUPABASE_URL` ve `SUPABASE_ANON_KEY` değerleri çift tırnak (`"..."`) içinde tanımlıydı.
- `flutter_dotenv` tırnağı değerin parçası olarak okuyor → Supabase bağlantısı başarısız → uygulama **mock auth** moduna düşüyor → yalnızca sabit mock şifreler (`123456`) çalışıyor, Supabase Dashboard'daki gerçek şifreler reddediliyor.

**Çözüm:**

- `.env` içinden tırnak işaretleri kaldırıldı:
  - `SUPABASE_URL="https://..."` → `SUPABASE_URL=https://...`
  - `SUPABASE_ANON_KEY="eyJ..."` → `SUPABASE_ANON_KEY=eyJ...`
- APK yeniden oluşturulmalı (`flutter clean && flutter pub get && flutter build apk --release`) çünkü `.env` build sırasında asset olarak gömülür.

**Dosya:** `frontend/.env`

### 32.2 Performans değerlendirmesi

Uygulama analiz edildi; günlük kullanımda kasma beklenmez:

**İyi:**
- Arka planda sürekli yenileme / polling yok
- Canlı Supabase dinleme (RealtimeChannel) yok — ekstra CPU kullanmaz
- Ağ görselleri `CachedNetworkImage` ile önbellekli
- APK içi asset toplam ~0,6 MB
- Push (FCM) kapalı — arka planda ek yük yok

**Dikkat noktaları (ileride):**
- Üretici katalog admin: depolama çubuğu hesabı (`Storage.info()` çağrıları) çok görsel olunca 1–3 sn gecikebilir
- Sipariş listesi limitsiz çekiliyor; yüzlerce sipariş olunca sayfalama gerekebilir
- PDF üretimi kısa süre ana thread'de çalışır (yarım saniye donma hissi normal)
- Push eklendiğinde: doğru kurulursa (token kaydı + sunucudan gönderim) performans etkisi küçük kalır

### 32.3 Proje durum özeti (güncel)

**Tamamlanan özellikler:**
- Auth (Supabase + mock fallback), kalıcı oturum, şifre değiştirme
- Alıcı: katalog, sipariş oluşturma (renk-beden matrisi), takip + detay + zaman çizelgesi, PDF, güncelleme talepleri
- Üretici: gelen siparişler, üretim aşamaları, katalog yönetimi (CRUD + fotoğraf), depolama çubuğu, Excel, güncelleme talepleri
- Bildirimler (uygulama içi): trigger + liste + zil sayacı
- 7 SQL migration + RLS + seed

**Yapılmamış:**
1. Push bildirimler (FCM): tablo + trigger hazır; Flutter Firebase bağlantısı + token kaydı + `send-push` Edge Function yok
2. iOS build (Windows'ta yapılamaz)
3. Şifremi unuttum (gerçek e-posta sıfırlama)
4. Uygulama ikonu + markalı splash
5. Kapsamlı test coverage

### Sonraki adımlar

1. `.env` düzeltmesi sonrası APK yeniden oluştur + Supabase şifresi ile test
2. İstenirse: push (FCM), uygulama ikonu, splash ekranı

---

## 33) 26 Mayıs 2026 — Profil/mock temizlik, gerçek profil verisi, Excel iyileştirmeleri, uygulama ikonu

### 33.1 Bildirimler sistemi kaldırıldı

**İstem:** Profildeki bildirimler alanı ve ilgili tüm kod/SQL kaldırılsın.

**Yapılanlar:**

- 5 Dart dosyası silindi:
  - `lib/features/notifications/domain/app_notification.dart`
  - `lib/features/notifications/data/notifications_repository.dart`
  - `lib/features/notifications/data/supabase_notifications_repository.dart`
  - `lib/features/notifications/application/notifications_provider.dart`
  - `lib/features/notifications/presentation/notifications_section.dart`
- `notifications/` klasörü tamamen kaldırıldı.
- `profile_page.dart`: `NotificationsSection` widget'ı ve import'u silindi.
- `app_shell.dart`: Bildirim zili ikonu (badge + unread count) ve `notifications_provider` import'u kaldırıldı.
- SQL migration dosyaları silindi: `database/migrations/006_notifications.sql`, `database/migrations/007_notification_triggers.sql`.
- `database/policies/001_rls.sql`: `device_tokens` ve `notifications` RLS policy satırları kaldırıldı.

### 33.2 Vergi No alanı kaldırıldı

- `profile_page.dart`: "Vergi No" satırı ve `_ProfileData.taxId` field'i silindi.

### 33.3 Destek alanı kaldırıldı

- `profile_page.dart`: "Destek" section header ve "Hesap Yöneticiniz" kartı silindi.
- `_showSnack` metodu (artık kullanılmayan) kaldırıldı.

### 33.4 Mock veriler temizlendi

- 3 mock dosya silindi:
  - `lib/features/catalog/data/mock_catalog.dart`
  - `lib/features/orders/data/mock_tracked_orders.dart`
  - `lib/features/orders/data/mock_order_status_timeline.dart`
- Tüketici dosyalardaki mock referanslar temizlendi:
  - `catalog_list_provider.dart`: `mockCatalog` import ve referansı kaldırıldı.
  - `tracked_orders_notifier.dart`: `kSeedTrackedOrders` import ve referansı kaldırıldı.
  - `order_status_timeline_provider.dart`: `mockTimelineForOrder` kaldırıldı; `repo == null` → boş liste.
  - `producer_orders_notifier.dart`: `mockProducerOrders` referansı kaldırıldı.
  - `producer_order.dart`: `mockProducerOrders` listesi ve `producerOrderByCode` fonksiyonu silindi, `mock_catalog.dart` import'u kaldırıldı.
- `formatTimelineTimestamp` fonksiyonu `order_status_timeline_card.dart` dosyasına taşındı (silinen mock dosyada tanımlıydı).

### 33.5 Profil sayfası gerçek veritabanı verisine bağlandı

**Sorun:** Profil sayfasında ad, unvan, şirket ve e-posta bilgileri hardcoded'dı (Beyza Demir / Selçuk Aydın).

**Yapılanlar:**

- `AuthResult`: `fullName`, `title`, `companyName` alanları eklendi.
- `SupabaseAuthRepository._profileForUser`: Supabase sorgusu `full_name`, `title` ve `companies(name)` join'ini çekecek şekilde genişletildi.
- `SessionState`: `fullName`, `title`, `companyName` alanları eklendi; `signIn` ve `_restore` metodları bu alanları dolduruyor.
- `profile_page.dart`: Hardcoded `_profileFor(role)` metodu kaldırıldı, yerine `_profileFrom(session, role)` konuldu. Artık veritabanındaki gerçek `full_name`, `title`, `email` ve `companies.name` değerleri gösteriliyor.

### 33.6 Şifremi unuttum butonu kaldırıldı

- `login_page.dart`: `_onForgotPassword` metodu, `onForgotPassword` parametresi ve "Şifremi unuttum" `TextButton`'u tamamen kaldırıldı.
- Şifre sıfırlama Supabase Dashboard'dan manuel yapılacak.

### 33.7 Uygulama adı ve ikonu güncellendi

**Uygulama adı:**
- `AndroidManifest.xml`: `android:label` → `TextileFlow`
- `Info.plist`: `CFBundleDisplayName` ve `CFBundleName` → `TextileFlow`

**Uygulama ikonu:**
- Beyaz arkaplan üzerine koyu antrasit "TextileFlow" ve altında "Sipariş" yazılı ikon oluşturuldu.
- `assets/logos/app_icon.png` olarak kaydedildi.
- `flutter_launcher_icons` ile tüm çözünürlüklerde (mipmap, adaptive icon, iOS) uygulandı.
- `pubspec.yaml`: `adaptive_icon_background` → `#FFFFFF`, `image_path` → `app_icon.png`.

### 33.8 Excel export iyileştirmeleri

**Tablo çizgileri:**
- Tüm hücrelere `Border(borderStyle: BorderStyle.Thin)` eklendi (başlık, veri ve TOPLAM satırları).

**Hücre ortalama:**
- Tüm hücrelere `HorizontalAlign.Center` + `VerticalAlign.Center` eklendi.

**Sütun genişlikleri:**
- A (Sipariş Veren): 20, B (Renk): 18, C (Adet): 12, D-H (Bedenler): 10.

**Ürün görseli Excel'e gömülüyor:**
- `excel` paketi → `excel_community ^1.1.4` geçişi yapıldı (görsel gömme desteği).
- `xml ^7.0.1` dependency override eklendi (`flutter_svg` ile uyumluluk).
- `_loadProductImage`: Supabase URL → HTTP ile indir, asset → `rootBundle`, yerel dosya → `File.readAsBytes`.
- `buildWorkbook`: `productImageBytes` parametresi; görsel varsa `ExcelImage` + `ImageAnchor.fromPixels` ile gömülüyor, yoksa metin placeholder kalıyor.
- `http` paketi eklendi (görsel indirmek için).
- `flutter_native_splash` dev dependency kaldırıldı (artık runtime'da kullanılmıyor, `xml` çakışması çözüldü).

**Sipariş veren bilgisi DB'den:**
- `buildWorkbook`, `share`, `showProducerOrderExcelPreview`: `orderedByName` parametresi eklendi.
- 3 çağrı noktası güncellendi: `tracking_page.dart`, `tracking_order_detail_page.dart`, `producer_order_detail_page.dart` — `ref.read(sessionControllerProvider).fullName` ile gerçek kullanıcı adı aktarılıyor.
- Önizleme tablosu (`_PreviewDataTable`): `orderedByName` parametresi eklendi.

### 33.9 Kalite kontrol

- `flutter analyze` → `No issues found!`
- Tüm mock referansları temizlenmiş durumda.
- Bildirim sistemi tamamen kaldırılmış.

### 33.10 Güncel durum ve yapılmamışlar

**Tamamlanan (bu oturumda):**
- Bildirimler, Vergi No, Destek alanları kaldırıldı
- Mock veriler temizlendi
- Profil gerçek DB verisine bağlandı
- Şifremi unuttum kaldırıldı
- Uygulama adı ve ikonu güncellendi
- Excel: border, ortalama, sütun genişlikleri, görsel gömme, sipariş veren DB'den

**Yapılmamış:**
1. Push bildirimler (FCM)
2. iOS build
3. Kapsamlı test coverage

---

## 34) 2 Haziran 2026 — Sevk/güncelleme talebi kuralları ve "Talebi kapat" akışı

### Yapılanlar

- `lib/features/requests/domain/request_thread.dart`
  - `isOrderShipped`, `hasOpenUpdateWorkflow` ve `lastIsProducerFeedback` yardımcı getter'ları eklendi.
- `lib/features/requests/presentation/request_thread_detail_page.dart`
  - Alıcı tarafında sevk edilmiş sipariş için yeni talep alanı gizlendi, bilgilendirme kartı eklendi.
  - Üretici tarafında son kayıt `producer_feedback` ise yeni bir "Talebi kapat" kartı eklendi.
  - "Talebi kapat" aksiyonu için onay popup'ı (opsiyonel not alanı ile) eklendi; onayda `producerApprove` çağrılıyor ve yeni `producer_approval` kaydı atılıyor.
- `lib/features/requests/data/supabase_requests_repository.dart`
  - `addBuyerRequest` öncesi thread'in bağlı siparişi `shipped` ise talep ekleme backend tarafında da engellendi.
- `lib/features/producer/presentation/producer_production_page.dart`
  - "Sevke Hazır" butonuna onay popup'ı eklendi.
  - Sevk öncesi talep thread'i yenilenip açık workflow kontrolü yapılıyor.
- `lib/features/producer/application/producer_orders_notifier.dart`
  - `markShipped` içinde açık talep akışı kontrolü eklendi (son kayıt `buyer_request` veya `producer_feedback` ise sevk engelleniyor).
- `lib/features/orders/data/supabase_orders_repository.dart`
  - `updateOrderStatus(status: shipped)` çağrısında backend guard eklendi: thread son kaydı `buyer_request`/`producer_feedback` ise sevk reddediliyor.
- `lib/features/producer/domain/producer_order.dart`, `lib/features/orders/data/supabase_orders_repository.dart`, `lib/features/orders/presentation/create_order_page.dart`
  - `ProducerOrder` modeline `buyerOrderNo` alanı eklendi; thread eşlemesi için dolduruldu.

### Sorunlar

- Sevk edilmiş siparişlerde takip ekranında buton kalkmış olmasına rağmen "İstekler" detayından yeni talep girilebiliyordu.
- Açık güncelleme talebi varken sipariş sevk edilebiliyordu.
- Üretici yanlışlıkla "Geri bildirimi kaydet" seçtiğinde, Alıcı yeni talep atmadıkça süreç kapanmıyor ve sevk kilitli kalıyordu.
- "Sevke Hazır" aksiyonunda kullanıcı onayı yoktu.

### Çözümler

- UI + notifier + repository katmanlarında çoklu guard ile sevk edilmiş siparişe talep ekleme kapatıldı.
- Sevk geçişine hem uygulama katmanında hem repository katmanında "açık talep akışı" kontrolü eklendi.
- Üretici için "Talebi kapat" akışı eklendi: geri bildirimi silmeden yeni `producer_approval` event'i ekleniyor (audit korunuyor).
- Sevk işlemi için onay popup'ı eklendi; yanlış tıklama riski azaltıldı.

### Durum

- İlgili dosyalarda lint/analyze temiz:
  - `flutter analyze lib/features/requests/domain/request_thread.dart lib/features/requests/presentation/request_thread_detail_page.dart` → **No issues found**.
- Kural seti güncel:
  - Sevk edilen siparişe yeni talep girilemez.
  - Açık workflow varken sevk yapılamaz.
  - Üretici, geri bildirim sonrası "Talebi kapat" ile workflow'u kapatabilir.

### Sonraki adımlar

1. UAT: Alıcı + Üretici iki hesapla uçtan uca regresyon testi (talep, geri bildirim, talebi kapat, sevk).
2. İstenirse "Talebi kapat" aksiyonunu producer liste kartına da kısayol olarak ekleme.
3. Aynı business kuralını DB tarafında RPC/policy seviyesine taşımayı değerlendirme (çoklu istemci güvenliği için).

---

## 35) 2 Haziran 2026 — Güncelleme talepleri için push bildirim akışı netleştirmesi

### Yapılanlar

- `database/migrations/012_push_update_requests.sql`
  - `order_update_entries` tablosuna gelen yeni kayıtlar için push kuyruğu akışı eklendi.
  - Tür bazlı senaryolar kapsandı: `buyer_request`, `producer_approval`, `producer_feedback`.
- `backend/functions/send-push/index.ts`
  - Kuyruktaki push kayıtlarını tekil satır mantığıyla işleyen akış, güncelleme talebi event'leriyle uyumlu çalışacak şekilde kullanılıyor.

### Sorunlar

- `progress.md` içinde güncelleme talepleri push akışı önceki bölümlerde dağınık kalmıştı; "bugün ne eklendi?" görünürlüğü düşüktü.

### Çözümler

- Push tarafındaki güncelleme talebi akışı ayrı başlıkta net bir kayıt olarak eklendi.
- SQL migration + Edge Function yolları açıkça referanslandı.

### Durum

- Güncelleme talepleri için push tetikleme akışı dokümana işlendi.
- Operasyonel olarak geçerli olması için migration'ın çalıştırılmış ve edge function'ın deploy edilmiş olması gerekir.

### Sonraki adımlar

1. `012_push_update_requests.sql` çalıştırma durumunu ortamda doğrulama.
2. `send-push` fonksiyon deployment + webhook bağlantısını kontrol etme.
3. Uçtan uca test: Alıcı talep / Üretici onay / Üretici geri bildirim senaryolarında doğru şirkete tekil push gittiğini doğrulama.

---

## 36) 2 Haziran 2026 — Push / ön plan ile otomatik veri yenileme

### Eklenen

- `lib/core/sync/remote_data_sync.dart` — FCM veya uygulama `resumed` olunca `trackedOrders`, `producerOrders`, `requestThreads` paralel `refresh` (400 ms debounce).
- `lib/core/sync/push_navigation.dart` — bildirim `data` → hedef rota.
- `lib/app/app.dart` — ön plan push’ta sync + SnackBar «Görüntüle»; bildirime tıklama / cold start öncesi sync; `WidgetsBindingObserver` ile `resumed` sync.
- `ProducerOrderDetailPage` — `orderCode` ile provider’dan canlı sipariş (push sonrası detay güncellenir).
- `ResponsivePage.onRefresh` — Takip, Gelenler, Üretim, Sevk, İstekler listelerinde pull-to-refresh.

### Test

İki cihaz/emülatör: karşı panel aksiyonu → SnackBar + liste/detay anında güncellenmeli; uygulamayı öne alınca `resumed` ile de yenilenmeli.

---

## 37) 3 Haziran 2026 — Çeki listesi (sevk)

**Özet:** Veri girişi ve kayıt **tamam**; Excel export **kısmen** — Storage’daki resmi Alıcı şablonu kullanılıyor ancak hücre eşlemesi ve ExcelJS kayıt sorunları nedeniyle çıktı her cihazda güvenilir değil.

### Eklenen

- `database/migrations/013_order_packing_lists.sql` — `order_packing_lists` + `order_packing_list_lines`, RLS.
- `database/migrations/014_packing_list_line_series_size.sql` — satır bazında `series_size` (beden oranı toplamı).
- `database/migrations/015_function_templates_storage.sql` — private `function-templates` bucket (xlsx şablon; Edge Function service role ile okur).
- Üretici «Sevke Hazır» → `packing_list_ship_dialog.dart` (renk / seri / çuval / pasif beden artanları, yumuşak adet uyarısı). Seri boyutu renk başına sipariş oranından (`colorSizeRatios` toplamı); sabit 7 yok.
- `savePackingListAndMarkShipped` — çeki kaydı + `status=shipped`.
- `backend/functions/generate-packing-list-excel` — çeki Excel; şablon **Storage** `function-templates/MADMEXT_CEKI_LISTESI.xlsx` (fonksiyon klasöründe xlsx gerekmez).
- `order_excel_chooser_sheet.dart` — Sipariş Exceli / Çeki Listesi (Üretici detay + Alıcı sevk detay); sunucu hata mesajını SnackBar’da gösterir.
- Alıcı sevk detayında `BuyerPackingListSummary` salt okunur özet.
- `database/migrations/016_packing_list_description.sql` — açıklama alanı (`description`).
- Üretici sevk dialogu — opsiyonel **Açıklama** + **Not** (Excel C28 / B22).

### Formül (renk başına)

**Satır toplamı = seri adedi × oran toplamı + Σ(aktif beden artanları)**  
Örnek (oran toplamı 7): 29×7 + (1+3+2) = 209 adet.

### Kurulum

1. Migration `013`, `014`, `015_function_templates_storage.sql` (Supabase SQL Editor).
2. Storage → `function-templates` → `MADMEXT_CEKI_LISTESI.xlsx` yükle (orijinal xlsx; Dashboard editöründe **açmayın**).
3. Edge Functions → `generate-packing-list-excel` → yalnızca `index.ts` deploy.
4. Flutter: çeki Excel hata mesajı iyileştirmesi için APK yeniden derle (sunucu düzeltmeleri için APK şart değil).

### Deploy / teknik notlar

- Yanıt `Content-Type: application/octet-stream` olmalı (`generate-order-excel` ile aynı). Aksi halde Supabase Flutter istemcisi xlsx’i metin sanır; Dashboard 200 döner ama uygulama hata verir.
- Dashboard’da fonksiyon klasörüne xlsx eklemek **gerekmez**; ikili dosya metin editöründe bozulabilir → Storage kullanın.
- Şablon değişince yalnızca Storage’dan dosyayı güncellemek yeterli (fonksiyon yeniden deploy şart değil).

### Durum (3 Haziran 2026 — güncelleme)

**Yeni resmi şablon** (`MADMEXT ÇEKİ LİSTESİ ÜRÜN GÖNDERİMİ`) repoya alındı; Storage’a aynı dosya (`MADMEXT_CEKI_LISTESI.xlsx`) yüklenmeli.

**Tamamlanan (bu tur):**

- `index.ts` — yeni şablona göre hücre eşlemesi (K2–K5, I5, satır 7–18, toplam 19, B22 not, C28 açıklama).
- `016_packing_list_description.sql` — `order_packing_lists.description`.
- Üretici sevk dialogu — opsiyonel **Açıklama** ve **Not** alanları (Excel’e yazılır).
- Özet kart — açıklama/not salt okunur gösterim.

**Hâlâ izlenmeli:** ExcelJS birleşik hücreli şablonu kayıtta bozabilir (masaüstü Excel vs mobil). Devam ederse alternatif üretim yolu değerlendirilir.

### Kurulum (güncel)

1. Migration `016_packing_list_description.sql` (Supabase SQL Editor).
2. Storage → `function-templates` → yeni `MADMEXT_CEKI_LISTESI.xlsx` yükle (repodaki dosya).
3. `generate-packing-list-excel` → `index.ts` deploy.
4. Flutter APK yeniden derle (açıklama/not alanları için).

### Açık işler

1. LP-43102065 ile Excel uçtan uca doğrulama (tarih, ürün adı, renk/seri, not/açıklama).
2. Masaüstü Excel boş açılırsa exceljs alternatifi.

7461 / Kahve (oran toplamı 7): 29 seri×7 + 1S+3M+2L = 209 adet → sevk → Excel seçici.

---

## 38) 4 Haziran 2026 — Çeki Excel eşlemesi, katalog Storage, Takip Excel seçici

### Yapılanlar

**Çeki listesi Excel (`generate-packing-list-excel/index.ts`)**

- Güncel şablon (`MADMEXT ÇEKİ LİSTESİ ÜRÜN GÖNDERİMİ 3.xlsx`) repoya alındı; hücre haritası yeniden yazıldı.
- Üst bilgi: K2 tedarikçi, K3 ürün adı, K4 sipariş tarihi, **K5 teslimat tarihi** (model kodu artık buraya yazılmıyor).
- Veri satırı 7–18: **A** model kodu, **B** renk (orijinal yazım, büyük harfe çevrilmez), **C–K** XS–5XL artan, **L** seri adeti, **M** çuval adeti.
- Toplam: **satır 20** — A20 şablonda TOPLAM; **B20** adet, **L20** seri, **M20** çuval (ekstra TOPLAM yazısı yok).
- NOT / Açıklama: **B22**, **B28** — sola ve üste yaslı (`wrapText`).
- İmza: **D35** teslim alan (siparişi oluşturan), **K35** teslim eden (sevk eden Üretici kullanıcısı); profil `full_name` DB’den.

**Katalog Storage temizliği (Flutter)**

- `catalog_storage_service.dart` — `deleteModelFolder`, `syncModelFolder` (orphan dosya silme).
- `supabase_catalog_repository.dart` — ürün silinince `{companyId}/{modelCode}/` klasörü Storage’dan silinir; güncellemede kullanılmayan görseller temizlenir.
- RLS zaten vardı; eksik olan uygulama kodu tamamlandı.

**Alıcı Takip — Excel seçici + çeki önizleme**

- `tracking_page.dart` — **sevk edilmiş** siparişlerde «Excel İndir» → Sipariş Exceli / Çeki Listesi seçimi (detay sayfası ile aynı).
- `packing_list_excel_preview_sheet.dart` — çeki listesi tablo önizlemesi + indirme onayı.
- `packing_list_excel_export.dart` — Edge Function çağrısı ayrı dosyaya alındı.
- `order_excel_chooser_sheet.dart` — çeki seçeneği önizlemeye yönlendirir; `packingList` parametresi eklendi.
- `tracking_order_detail_page.dart`, `producer_order_detail_page.dart` — `packingList` geçirimi.

### Sorunlar

- Excel hücre eşlemesi birkaç tur yanlış kaldı (model kodu teslimat hücresine, renk/seri yanlış sütun); kullanıcı şablonu **elle düzeltti**.
- ExcelJS birleşik hücreli xlsx’i kaydederken hücre kayması yapabiliyor (PC vs mobil farklı görünüm).
- Repodaki xlsx XML ile Excel’de görünen sütun düzeni (MODEL/RENK) bazen uyuşmuyor — **canlı şablon Storage + kullanıcı Excel’i** tek doğruluk kaynağı olmalı.
- Daha önce silinen katalog ürünlerinin Storage dosyaları otomatik temizlenmedi (yalnızca DB cascade).

### Çözümler

- Hücre sabitleri `TOTAL_ROW = 20` vb. güncellendi; yorumlar `backend/README.md` ile hizalandı.
- Storage silme/güncelleme senkronu eklendi (yeni silmeler otomatik; **eski orphan dosyalar** Dashboard’dan elle temizlenmeli).
- Takip listesinde sevk siparişleri için Excel akışı detay ile birleştirildi.

### Durum

| Alan | Durum |
|------|--------|
| Çeki listesi veri girişi (Üretici sevk) | Tamam |
| Çeki Excel Edge Function | Deploy gerekli; eşleme güncel `index.ts` |
| Çeki Excel çıktı doğruluğu | Kullanıcı doğrulaması gerekli; ExcelJS riski devam |
| Katalog Storage silme | Tamam — **APK yeniden derle** |
| Takip Excel seçici + çeki önizleme | Tamam — **APK yeniden derle** |

### Kurulum / deploy

1. Storage → `function-templates` → güncel `MADMEXT_CEKI_LISTESI.xlsx` (repodaki son sürüm).
2. Supabase → `generate-packing-list-excel` → **Deploy updates** (`index.ts`).
3. Flutter **APK yeniden derle** (Storage silme + Takip Excel + çeki önizleme).
4. Migration `016` henüz çalıştırılmadıysa SQL Editor’de çalıştır.

### Sonraki adımlar

1. Deploy + APK sonrası bir sevk siparişinde Excel uçtan uca kontrol (model A, renk B, seri L, toplam B20).
2. Masaüstü Excel’de boş/kayık açılma devam ederse exceljs dışı yol veya sadeleştirilmiş şablon.
3. Eski Storage orphan klasörlerini (`catalog-images/{companyId}/{eski_model}/`) Dashboard’dan temizle.
4. İsteğe bağlı: hücre haritasını JSON config + smoke test (regresyon önleme).

### Test

- Üretici: katalogdan ürün sil → Storage’da ilgili klasör gitmeli; kota çubuğu düşmeli.
- Alıcı Takip: sevk edilmiş sipariş → Excel İndir → iki seçenek → her birinde önizleme → indir.
- Çeki Excel: renk adları DB’deki gibi; toplam satır 20.

---

## 39) 7 Haziran 2026 — Bildirim navigasyonu, Alıcı takip UX, sipariş kodu, dinamik kategoriler

### Yapılanlar

**Push bildirim → detay navigasyonu (Üretici + Alıcı, Android + iOS):**

- `lib/core/sync/push_navigation.dart`
  - `navigatePushTarget()` — bildirim hedefi shell sekmesi korunarak `push` ile açılır; shell yoksa önce `/catalog`, sonra `push` (`go` ile yığın silinmez).
  - `safePopDetail()` — `canPop` ise `pop`, değilse `go(fallback)` (varsayılan `/catalog`); GoError önlenir.
  - Alıcı sipariş bildirimi → `/tracking/order/:code`; üretici → `/producer/incoming/:code`.
- `lib/app/app.dart` — SnackBar «Görüntüle», cold start ve `onMessageOpenedApp` akışı `navigatePushTarget` kullanıyor.
- `lib/features/producer/presentation/producer_order_detail_page.dart` — AppBar geri butonu her zaman görünür (yükleme + detay); Onayla / üretime al sonrası `safePopDetail`.
- Platform ayrımı yok; iOS ve Android aynı Dart kodunu çalıştırır.

**Alıcı takip listesi — özet kart düzeni:**

- `lib/features/orders/presentation/tracking_page.dart` — `BuyerOrderSummaryCard` **arama çubuğunun üstüne** taşındı; `buyer_shipped_page.dart` ile aynı sıra: başlık → özet kart → arama → durum çipleri → sıralama → liste.
- Özet metni durum filtresine göre (`trackingSummaryOrderLabel`) güncellenmeye devam eder.

**Sipariş kodu — global artan LP numarası:**

- `database/migrations/017_order_code_sequence.sql` — `order_code_seq` + `next_order_code()` → `LP-0000001` formatı; mevcut kayıtlar migrate edilir; sequence en büyük numaradan devam eder.
- Flutter tarafında Supabase sipariş oluşturma bu fonksiyonu kullanır (§28 repository ile uyumlu).

**Dinamik katalog kategorileri:**

- `database/migrations/018_catalog_categories.sql` — `catalog_categories` tablosu, RLS (authenticated SELECT yalnızca `is_active`); **seed yok** (kategoriler Table Editor ile eklenir).
- `lib/features/catalog/data/supabase_catalog_repository.dart` — `fetchActiveCategoryNames()`.
- `lib/features/catalog/application/catalog_list_provider.dart` — `catalogCategoriesProvider`.
- `lib/features/producer/catalog_admin/presentation/producer_catalog_product_editor_page.dart` — sabit kategori listesi kaldırıldı; dinamik dropdown; «Örnek görsel» / asset seçimi kaldırıldı; ürün görseli zorunlu; `image_picker` sıkıştırması kaldırıldı.
- Katalog / admin / zoom: `BoxFit.contain` ile görsel sığdırma.

**Diğer UX (aynı dönem):**

- `create_order_page.dart` — gönderim sonrası model seçimi sıfırlanır + `context.go('/orders/new')`.
- `producer_production_page.dart` — «Detay» butonu sipariş detayına gider.
- `producer_order_detail_page.dart` — «Talepleri görüntüle» bağlantısı.
- Talep kartlarında ürün kodu thumb (`RequestThread.productCode`).

### Sorunlar

- Uygulama içindeyken bildirim → Görüntüle → Üretici **Onayla** sonrası **GoError** (yığında geri gidilecek sayfa yok).
- Bildirimden açılan Üretici sipariş detayında AppBar geri butonu görünmüyordu (`canPop == false`).
- Alıcı **Takip** sekmesinde özet kart arama çubuğunun **altında** kalmıştı; **Sevk** sekmesiyle tutarsızlık.
- `018` migration'da `id` sütununa manuel `1` yazılınca UUID hatası (`invalid input syntax for type uuid`).

### Çözümler

- Bildirim navigasyonu `go` → shell + `push`; detay çıkışı `safePopDetail`.
- Takip sayfası layout'u sevk listesiyle hizalandı.
- Kategori ekleme: `id` boş bırakılır veya yalnızca `name`, `sort_order`, `is_active` insert edilir.

### Durum

- Navigasyon düzeltmesi Android ve iOS'ta ortak kod; ayrı iOS implementasyonu yok.
- `dart analyze` — navigasyon dosyaları temiz.
- Migration **017** ve **018** Supabase'te çalıştırılmadıysa sırasıyla SQL Editor'de uygulanmalı; **018** sonrası kategoriler Table Editor'dan eklenmeli.

### Sonraki adımlar

1. **Siz:** `017_order_code_sequence.sql` + `018_catalog_categories.sql` çalıştır; kategorileri ekle (ör. Polo, Tişört — `id` otomatik UUID).
2. APK/iOS build sonrası: bildirim → Görüntüle → Onayla + geri butonu regresyon testi (Üretici ve Alıcı).
3. Takip / Sevk özet kartlarının filtre değişiminde sayıların doğru güncellendiğini doğrula.
4. Sezon sıfırlamada `order_code_seq` duplicate riski — sequence sıfırlanmamalı veya yıl/sezon prefix değerlendirilmeli.

---

## 40) TextileFlow bootcamp — demo ayrıştırma ve teslim hazırlığı

### Yapılanlar

- Canlı müşteri ortamından tamamen ayrı **demo** Supabase + Firebase projesi; nötr markalama (TextileFlow, Demo Alıcı / Demo Üretici).
- Kod, SQL enum ve dokümanlarda eski firma/marka izleri temizlendi; talep türleri `buyer_request` / `producer_approval` / `producer_feedback` olarak güncellendi.
- Sipariş kodu öneki `SPRS-`; migration'lar `001–012` olarak sadeleştirildi.
- Palet 2 (logodan), anlamsal buton renkleri, kategori çipleri, yerel ürün placeholder görselleri.
- **FastAPI + Gemini 2.5 Flash:** sipariş notu ve güncelleme talebi düzenleme (`backend/api`); Flutter `AssistApi` + «AI ile düzenle» butonları.
- `.gitignore`: `google-services.json` hariç tutuldu.
- Web release build alındı (`frontend/build/web`); lokal static server ile doğrulandı.

### Kararlar

- **Backend ayrımı:** iş verisi Supabase (Auth, RLS, Edge Functions); FastAPI yalnızca LLM asistanı — genel CRUD FastAPI'de yok.
- Demo kullanıcıları Supabase Auth + `dev_seed.sql` ile; self-servis kullanıcı yönetimi kapsam dışı.
- AI opsiyonel: `API_BASE_URL` tanımlı değilse butonlar gizlenir; canlı teslimde URL prod API'ye işaret etmeli.

### Sorunlar / çözümler

- AI yanıtı yarıda kesiliyordu → `thinking_budget=0`, `max_output_tokens` artırıldı, akıllı `_clip`.
- Android emülatör depolama dolu → eski APK kaldırıldı / emulator wipe önerildi.
- Mevcut Supabase'te enum yeniden adlandırma: `ALTER TYPE ... RENAME VALUE` + `010_push_update_requests.sql` fonksiyonu yeniden çalıştırıldı.

### Durum

- Uygulama Android + web build ile çalışır durumda; Supabase demo projesi kurulu.
- Canlı web deploy (Vercel), prod `API_BASE_URL`, kök `README.md`, demo video ve GitHub push **bekliyor**.

### Sonraki adımlar

1. `frontend/.env` → canlı `API_BASE_URL` (HTTPS); web yeniden build + Vercel deploy.
2. FastAPI canlı host (Render/Railway vb.) + `ALLOWED_ORIGINS` Vercel domain.
3. Kök `README.md`, demo video, GitHub son commit, teslim formu.

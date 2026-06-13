# TextileFlow — Tasarım Sistemi

TextileFlow, tekstil sektörü için geliştirilmiş bir B2B sipariş yönetim uygulamasıdır. Bu doküman; renk, tipografi, boşluk, bileşen ve sayfa standartlarını tek bir kaynakta toplar. Amaç, veri yoğun bir B2B arayüzünde **netlik, hız ve tutarlılık** sağlamaktır.

Tasarım dili **Kurumsal / Modern Minimalizm**'dir: fonksiyon önceliklidir, görsel süs minimumda tutulur, kullanıcının odağı sipariş doğruluğu ve takibinde kalır.

### Marka & Stil
Marka kişiliği **güvenilirlik, hassasiyet ve operasyonel verimlilik** üzerine kuruludur. Hedef kullanıcı, tekstil sektöründe yoğun bilgiyle çalışan B2B operasyon sorumluları ve üretim koordinatörleridir; bu nedenle yüksek bilgi yoğunluğu okunabilirlikten ödün vermeden sunulur. "Form'dan çok fonksiyon" felsefesi izlenir; cömert beyaz alan ve titiz hizalama ile premium bir his korunur. Estetik his düzenli bir üretim hattını çağrıştırır: yapısal, temiz ve amaca yönelik.

---

## 1. Renk Paleti (Palet 2 — logodan türetilmiş)

Palet, uygulama logosundan türetilmiş **indigo birincil** renk ve **turuncu / mercan / teal** aksanlardan oluşur. Kaynak: `frontend/lib/app/theme/app_colors.dart`.

### Marka / Birincil
| Token | Hex | Kullanım |
|---|---|---|
| `navy` (primary) | `#6047D6` | Birincil butonlar, aktif sekme, marka vurgusu |
| `navyDark` | `#2D2A6E` | Splash/adaptive ikon zemini, koyu vurgular |

### Aksanlar
| Token | Hex | Kullanım |
|---|---|---|
| `softBlue` (teal) | `#14B8A6` | Bilgi tonu, "Üretimde" durumu, ikincil vurgu |
| `secondary` | `#F07818` | Turuncu aksan (kategori çipleri, vurgular) |
| `tertiary` | `#F0554C` | Mercan aksan (kategori çipleri, vurgular) |

### Yüzeyler ve Metin
| Token | Hex | Kullanım |
|---|---|---|
| `surface` | `#F8FAFC` | Sayfa arka planı |
| `surfaceContainer` | `#FFFFFF` | Kart ve form yüzeyleri |
| `surfaceMuted` | `#F4F2FB` | İkincil/sönük zeminler |
| `border` | `#E7E5F4` | İnce sınırlar, ayraçlar |
| `text` | `#17142B` | Birincil metin |
| `textMuted` | `#6B6786` | İkincil/silik metin |

### Anlamsal (Durum) Renkleri
| Token | Hex | Anlam |
|---|---|---|
| `success` | `#16A34A` | Onaylandı / olumlu aksiyon |
| `warning` | `#F97316` | Beklemede / dikkat |
| `critical` | `#EF4444` | İptal / hata / silme |
| `neutral` | `#828282` | Arşiv / pasif |

---

## 2. Tipografi

**Yazı tipi:** Inter (sans-serif) — veri yoğun arayüzlerde yüksek okunabilirlik.

| Stil | Boyut | Ağırlık | Kullanım |
|---|---|---|---|
| H1 | 30px | 600 | Sayfa başlıkları |
| H2 | 24px | 600 | Bölüm başlıkları |
| H3 | 20px | 600 | Alt başlıklar |
| Body | 16px | 400 | Genel metin |
| Body-sm | 14px | 400 | Liste/tablo metni, form etiketleri |
| Label-md | 14px | 500 | Buton ve etiket metni |
| Label-caps | 12px | 700 | Tablo başlıkları, rozet/mikro kopya (harf aralığı geniş) |

Başlıklar Semi-Bold (600) ile hiyerarşi sağlar; gövde 16px tabandadır, liste ve tablolar yoğunluğu artırmak için 14px kullanır.

---

## 3. Yerleşim ve Boşluk

- **Taban birim:** 4px. Ölçek: 4 / 8 / 16 / 24 / 32px. Dikey ritim için 4px taban kayması kullanılır.
- **Grid:** 12 kolonlu sistem, 16px gutter. Pano (dashboard) görünümleri **sabit grid**, veri tabloları **akışkan grid** mantığıyla kurulur.
- **Konteyner kenar boşluğu:** mobilde 16–20px; geniş ekranlarda 40px (arayüzün "havadar" durması için). Yoğun görünümlerde (sipariş logları) dikey iç boşluk 8px'e iner; giriş/login gibi sayfalarda 24px+'a çıkar.
- **Köşe yarıçapı (radius):** standart bileşenler 8px; buton ve kartlar 12px; büyük konteynerler/modallar 16px.

### Yükselti & Derinlik
Görsel hiyerarşi **tonal katmanlar** ve **yumuşak (ambient) gölgeler** ile kurulur. Arka plan nötr taban (`surface`), birincil içerik konteynerleri (kart, tablo sarmalayıcı) saf beyazdır (`surfaceContainer`). Derinlik; **geniş bulanıklık (12–16px)** ve **çok düşük opaklık (%4–6 siyah)** ile sinyallenir — kalın çizgiler yerine hafif "kalkma" hissi. Modal ve açılır menüler, alttaki veri katmanından ayrışmak için biraz daha belirgin gölge kullanır.

### Şekiller
Şekil dili tutarlı biçimde **yuvarlatılmıştır**; standart bileşenlerde (buton, giriş alanı) 8px taban yarıçap, büyük konteyner ve modallarda 16px kullanılır. Bu yuvarlaklık seviyesi, tekstil işinin endüstriyel doğasını modern bir yazılım hissiyle dengeler.

---

## 4. Bileşenler

### Butonlar (anlamsal renklendirme)
Kaynak: `frontend/lib/app/theme/app_button_styles.dart`. Butonlar aksiyonun anlamına göre renklenir:

| Stil | Renk | Kullanım |
|---|---|---|
| `brand` | `navy` | Birincil/marka aksiyonu (ör. "Sevk et", "Sevke Hazır") |
| `positive` | `success` | Olumlu/onay aksiyonu (ör. "Onayla") |
| `progress` | `softBlue` | Süreç ilerletme (ör. "Üretime Al") |
| `danger` | `critical` (dolu) | Yıkıcı aksiyon (ör. "Sil") |
| `dangerOutlined` | `critical` (çerçeveli) | İkincil yıkıcı aksiyon |

Tüm butonlar min. 52px yükseklik, 12px radius, kalın (w700) etiket metni kullanır. **Hover/basılı** durumda dolu butonlar hafifçe koyulaşır; çerçeveli (ghost) butonlar soluk bir zemin dolgusu kazanır.

### Veri Tabloları
Tablolar veri yoğun ekranların merkezidir:
- Uzun listelerde **yapışkan başlık** (sticky header).
- Yalnızca **yatay eksende 1px** ince ayraçlar (gözü satır boyunca yönlendirir).
- Zebra desen yerine **satır-hover vurgusu** (`surfaceMuted`).
- Başlıklar `label-caps` stili ile (büyük harf, geniş aralık) sütun taramasını kolaylaştırır.

### Durum Rozetleri (Status Badge)
Kaynak: `frontend/lib/shared/widgets/status_badge.dart`. Yumuşak arka plan + aynı tonda koyu metin yaklaşımı. Sipariş durumu → renk eşlemesi:

| Durum | Renk |
|---|---|
| `submitted` (gönderildi) | `warning` |
| `approved` (onaylandı) | `success` |
| `in_production` (üretimde) | `softBlue` |
| `shipped` (sevk edildi) | `navy` |
| varsayılan | `neutral` |

### Kategori Çipleri
Katalog kategorileri, kategori adının hash'ine göre aksan renkleriyle (`secondary`, `tertiary`, `softBlue`, `navy`) renklendirilir; böylece liste görsel olarak çeşitlenir.

### Giriş Alanları (Input)
1px `border` çerçeve; **odakta** çerçeve kalınlaşır ve birincil indigoya (`navy`) döner. Etiket her zaman alanın üstünde konumlanır (netlik için).

### Rozetler / Çipler (Chips/Badges)
Durum rozetleri "yumuşak zemin" yaklaşımı kullanır: durum renginin açık tonu + aynı tonun koyu, kalın metni (ör. "Üretimde" için açık teal zemin, koyu teal metin).

### Sipariş Durum Zaman Çizelgesi (Progress Tracker)
Tamamlanan adımlarda birincil/anlamsal renk, gelecek adımlarda `neutral` kullanan stepper bileşeni. Dikey kullanımda (takip detayı "Durum geçmişi") her adım o durumun anlamsal rengiyle işaretlenir (yukarıdaki rozet eşlemesiyle aynı); herhangi bir siparişin durumu anında görülür.

---

## 5. Sayfa Standartları

### Giriş (Login)
- Ortalanmış TextileFlow logosu (büyük), e-posta/şifre alanları ve belirgin birincil buton.
- Rol seçimi backend profiline göre belirlenir (alıcı / üretici).

### Katalog
- Üstte model koduna/adına göre arama.
- Dikey ürün kartları: görsel + model kodu + ad; kategori çipi aksan rengiyle.
- Görsel yoksa kategori/renk bazlı yerel placeholder görseli kullanılır.

### Matris Sipariş Formu
- Satırlar renkler, sütunlar bedenler (S, M, L, XL, …).
- Hücre başına adet girişi; satır ve genel toplam anlık hesaplanır.
- Ek alanlar: termin tarihi, sipariş notu. Sipariş notu için **"AI ile düzenle"** yardımcısı (bkz. Tech Stack).

### Sipariş Takibi
- Kalıcı geçmiş: kullanıcı yetkili olduğu tüm siparişleri görür, otomatik silme yoktur.
- Durum zaman çizelgesi: `submitted → approved → in_production → shipped`, zaman damgalı.
- **Excel indir**: sipariş özeti Excel olarak dışa aktarılır.

### Güncelleme Talepleri (Talep Akışı)
- Alıcı, sipariş bazlı güncelleme talebi açar (`buyer_request`).
- Üretici onaylar (`producer_approval`) veya geri bildirim verir (`producer_feedback`).
- Açık talep akışı kapanmadan sevk yapılamaz.
- Talep ve geri bildirim metinleri için **"AI ile düzenle"** yardımcısı.

### Üretici Sipariş Yönetimi
- Gelen sipariş detayı: "Onayla" (positive), "Üretime Al" (progress).
- Üretim sayfası: "Sevke Hazır" / "Sevk et" (brand).
- Katalog yönetimi: ürün oluştur/düzenle/sil ("Sil" = danger).

---

## 6. Tasarım İlkeleri

1. **Hız:** Büyük, kolay tıklanabilir aksiyon alanları; minimum dokunuş.
2. **Netlik:** Sipariş durumu, talep geçmişi ve kalıcı kayıtlar açık ve izlenebilir.
3. **Standartlaşma:** Dağınık (ör. WhatsApp üzerinden) veri akışını matris yapı ve durum akışıyla disipline eder.
4. **Tutarlılık:** Renk, tipografi, boşluk ve bileşenler token tabanlıdır; ad-hoc stil kullanılmaz.

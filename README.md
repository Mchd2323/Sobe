# SOBE — Faz 1 Gri Kutu v0.2: Yakan Top 2v2

## Kurulum (5 dakika)
1. [godotengine.org/download](https://godotengine.org/download) → **Godot 4.3+** indir.
2. Godot → **Import** → `project.godot` seç.
3. **F5** → oyun açılır.

## Kontroller
| Oyuncu | Hareket | Atış / Kapma / Alma |
|---|---|---|
| P1 | WASD | Boşluk |
| P2 | Ok tuşları | Enter |
| P3 / P4 | Gamepad sol çubuk | A |

Varsayılan **1 insan + 3 bot** — `scripts/main.gd` → `HUMAN_PLAYERS` (1-4).
Takımlar: MAVİ = P1+P3, KIRMIZI = P2+P4.

## Kurallar
- **AMAÇ:** Rakip takımın ikisini de yak.
- **YANMA:** Havadaki top değerse. Seken top yakmaz; takım arkadaşına çarpan top söner (perde). Yananlar mezarlıktan oynar — **mezarlıktan rakip vuran geri döner (1 hak, ikinci yanış kesin).**
- **ŞİDDET 🟡:** Topu havada kaparsan atan yanar.

## 1 numaralı test sorusu
`scripts/constants.gd` → `MEZARLIK_RETURN` bayrağı:
- `true`: dönüş var (geri dönüş dramı, uzun turlar)
- `false`: yanan yandı (kısa, acımasız turlar — GDD anayasası)

**İkisiyle de 3'er maç oyna. Hangisinde daha çok gülüyorsanız kural odur.**

## v0.2 değişiklikleri (kod incelemesi sonrası)
- Sahaya duvar eklendi + sahipsiz top 6 sn'de ortaya döner → kilitlenme hatası kapandı
- Top taşıma kinematik moda alındı (titreme/çarpışma kaçırma düzeltmesi)
- Takım arkadaşına çarpan yanık top artık sönüyor
- Mezarlıktan dönüş kuralı eklendi (bayraklı, tek hak)
- `RoundBase` sözleşmesine olay kancaları eklendi — Main artık yalnız sözleşmeyi çağırıyor
- Yetim node sızıntısı giderildi; sabit sınıfı `C` → `Cfg`

## v0.3 — ilk kez gerçekten Godot'ta derlendi/koşturuldu

v0.1 ve v0.2 hiç çalışmıyordu. Godot 4.3 headless ile doğrulandı:

**1. `main.gd` hiç yüklenmiyordu (oyun açılmıyordu).**
`for pi in [3, 4]` içinde `pi` Variant olduğu için `var device := pi - 3`
tip çıkaramıyor → Parse Error → main.gd yüklenemiyor.
Düzeltme: `for pi: int in [3, 4]:`

**2. Botlar topu hiç almıyordu (maç hiç başlamıyordu).**
`_reachable_free_ball()` toleransı ±0.3'tü; top orta çizgide (x=0) doğduğu ve
her sıfırlamada oraya döndüğü için İKİ takımın da penceresinin dışında kalıyordu
(takım 0: [-7.9, -0.1] • takım 1: [0.1, 7.9]).
Ölçüm: 45 saniyede 0 atış, 0 yanma, 0 kapma, 7 top sıfırlaması.
Düzeltme: tolerans `Cfg.PICKUP_RADIUS`.

**3. `burn()` topun `held_by` referansını temizlemiyordu.**
Bugün tetiklenmiyor (tek top var), ikinci topla garantili kilitlenme. 1 satır.

### Ölçülen taban (Godot 4.3 headless, HUMAN_PLAYERS=0, saf 2v2 bot)
8 maç: hepsi bitti • kazanan dağılımı 4–4 • süre 19.8–59.8 sn (ort. ~38.7 sn)

Not: bunlar bot maçı ölçümleridir; **his testi değildir.** Atış hızı, kapma
penceresi ve mezarlık dönüşü kararları hâlâ 4 kişilik kanepe testine bağlı.

## v0.4 — kanepe testi sonrası (Godot 4.7.2)

İlk gerçek oynanış testi yapıldı. Kilitlenen kararlar ve düzeltmeler:

**KİLİTLENDİ (kanepe kararı):** `THROW_SPEED = 14`, `PLAYER_SPEED = 6` — "çok iyi".
Botların hareketi de yeterli bulundu. Kapma mekaniği olduğu gibi bırakıldı.

**Düzeltilenler**
- **SAYIŞMA:** top ortaya dönerken artık `DROP_COUNTDOWN` (1.5 sn) geri sayım var ve
  sayım boyunca iki takım da orta çizgiye `DROP_KEEPOUT` (3 m) mesafede tutuluyor.
  Öncesinde çizgide bekleyen oyuncu topu bedavaya alıp anında atabiliyordu — mücadele yoktu.
  Açılış topu da aynı yoldan iniyor.
- **UI taşması:** kural kartı ve kazanan yazısı `PRESET_CENTER` ile konumlanıyordu; bu preset
  kutunun SOL ÜST köşesini ekranın ortasına koyduğu için panel sağa taşıyor, yazılar
  kesiliyordu. `CenterContainer` + `FULL_RECT` ile gerçekten ortalandı, etiketlere sarma eklendi.
- **Mezarlık cezası** (`MEZARLIK_CATCH_PENALTY`): yanık atıcının topu havada kapılırsa dönüş
  hakkı yanar. Öncesinde mezarlıktan atmanın hiçbir riski yoktu.
- Proje 4.3 → **4.7** sürümüne alındı; CI de 4.7.2 ile koşuyor.

**CI bot maçı testi**
`scripts/autotest.gd` yalnız bayrakla yüklenir, normal oyunda hiç okunmaz:

    godot --headless --path . -- --sobe-autotest

Tüm koltukları bota çevirir, maçı başlatır, sonucu basar; tur 120 sn'de bitmezse
çıkış kodu 1 verir. CI her push'ta 3 maç koşar.

### Ölçülen taban (Godot 4.7.2, saf 2v2 bot, 8 maç)
Hepsi bitti, kilitlenme yok • kazanan dağılımı 6–2 • süre 21.4–95.5 sn (ort. 60.7 sn)

Not: süre v0.3'teki 38.7 sn ortalamadan yükseldi. Ölçüm: maç başına 3-7 kez top
sahipsiz kalıp sıfırlanıyor (`BALL_RESET_TIME` 6 sn), sayışma da her sıfırlamaya
1.5 sn ekliyor. Asıl kaldıraç sayışma süresi değil, **sıfırlama sıklığı**.
Tempo uzun geliyorsa önce `BALL_RESET_TIME`'a bakılmalı. Kanepe kararı bekliyor.

## v0.5 — top hakkı sistemi (kanepe geri bildirimi)

**Sorun:** Top ortada doğuyordu. Geri sayım kamp kurmayı engelledi ama asıl mesele
kalmıştı: sayım bitince topu kim önce kaparsa rakibi anında yakıyordu. Mücadele değil,
piyango. Kullanıcının tespiti: *"ortada top olmasın, top sırayla takımlarda olsun."*

**Çözüm:** Top artık ortada doğmaz — bir takıma **verilir** ve o takımın oyuncusunun
elinde sayışma başlar. Sıfırda oyun onun elindeki topla açılır.

| Durum | Top kime gider |
|---|---|
| Maç başı | `POSSESSION_START_TEAM` (varsayılan MAVİ) |
| Yanma | **Yanan** takıma (`POSSESSION_TO_SCORER = false`) |
| Kapma | Kapan oyuncuya — elinde kalır (bilerek istisna) |
| Iskalanan top 6 sn sahipsiz | Son atanın **rakibine** |

**Neden yanan takım?** Kullanıcı kararı bana bıraktı. 2v2'de yakan taraf topu da
tutsaydı, tek kalan rakibi anında yakardı ve maç saniyelerde biterdi — kartopu.
Yanan tarafa vermek geride kalana karşılık verme şansı tanır. Tek satırla tersine
çevrilebilir: `Cfg.POSSESSION_TO_SCORER = true`.

Kapma bilerek istisna: zor ve riskli bir hamledir, ödülü hem yakma hem top hakkıdır.

Sayışma boyunca kimse atamaz/alamaz; top sahibinin elinde bekler.

### Ölçülen taban (4.7.2, saf 2v2 bot, 8 maç)
Hepsi bitti, kilitlenme yok • **kazanan dağılımı 4–4** • süre 19.4–116.3 sn (ort. 56.4 sn)

Not: ortalama v0.4'e yakın (60.7 → 56.4) ama **sapma büyüdü**. Sebebi tasarımın
kendisi: yanan takım topu alınca geri dönüş yaşanıyor, `MEZARLIK_RETURN` de açıkken
maçlar uzayabiliyor. İki uzun maç 110 sn'yi aştı. Tempo kararı hâlâ kanepede —
kısaltmak gerekirse önce `MEZARLIK_RETURN`, sonra `BALL_RESET_TIME`.

## v0.6 — oynanış hataları (kanepe geri bildirimi)

**1. Topla koşulamıyordu.** Kullanıcı: *"top elimdeyken topla birlikte hareket
edemiyorum, WASD bana sadece yön gösteriyor."* Doğru tespit, gerçek hata:
tutulan top hâlâ katı bir cisimdi ve oyuncunun tam **0.7 m** önünde duruyordu.
Oyuncu yarıçapı 0.4 + top yarıçapı 0.3 = 0.7 — yani tam temas noktası. Oyuncu her
adımda kendi topuna sürtünüyor, ileri gidemiyordu. Artık top elde tutulurken
çarpışma şekli kapatılıyor, atınca geri açılıyor.

**2. Köşedeki topu botlar almıyordu** (insan alabiliyordu). İki sebep:
- Topun sıçraması yoktu (fizik malzemesi tanımsız = bounce 0), duvara değince
  köşede ölüyordu. `BALL_BOUNCE = 0.45` eklendi — kullanıcının önerisi.
- Botların uzanma menzili insanınkinden dardı: `PICKUP_RADIUS * 0.9` (1.35 m) vs
  insanın 1.5 m'si. Aradaki 15 cm'lik ölü bant tam köşede devreye giriyordu.
  Menzil eşitlendi.

**3. CI watchdog 120 → 180 sn.** Watchdog'un işi kilitlenmeyi yakalamak; gerçek
kilitlenme hiç bitmez, yavaş maç biter. 120 sn sınırı meşru maçlarda yanlış alarm
verdi (run #4 kırmızı). Sınır en uzun meşru maçın belirgin üstünde olmalı.

### Ölçülen taban (4.7.2, saf 2v2 bot)
6 maç: kilitlenme yok • süre 15.1–60.0 sn (**ort. 34.5 sn**)

Tempo kendiliğinden düzeldi: v0.5'te ort. 56.4 sn ve max 116 sn idi. Sekme +
eşit menzil sayesinde top artık köşede ölmüyor, botlar hemen alıyor, 6 saniyelik
"sahipsiz top" beklemeleri büyük ölçüde ortadan kalktı.

## v0.7 — A1: akış makinesi

**LOBİ → BRİFİNG → DENEME ATIŞI → OYUN → SKOR**

GDD §6'nın brifing standardı ("20 sn ölümsüz deneme, düdük") artık kodda.
`GameFlow` faz otoritesi; Main sadece `phase_changed` dinleyip arayüzü çiziyor.

- **LOBİ:** ATIŞ tuşuna basınca brifinge geçer
- **BRİFİNG:** Kural Karesi; ATIŞ tuşu denemeye geçirir
- **DENEME ATIŞI:** 20 sn, `RoundBase.practice = true` — kurallar işler, isabet
  olur, top el değiştirir ama **kimse yanmaz**. Sayaç ekranda.
- **OYUN:** "DÜDÜK!" → maç; oyuncular ve top sıfırlanmış halde başlar
- **SKOR:** kazanan yazısı; ATIŞ tuşu lobiye döndürür (artık sahne yeniden
  yüklemek gerekmiyor)

Turlar sözleşme üzerinden takılıyor: yeni mini oyun eklemek akışı değiştirmez.
CI `flow.skip_to_playing()` ile lobi/brifing/deneme adımlarını atlar.

### Doğrulama
- Akış testi: BRİFİNG → DENEME ATIŞI → (20 sn) → OYUN geçişleri doğru;
  deneme atışı boyunca hiç yanma olmadı (ölümsüzlük kontrolü tetiklenmedi)
- Bot maçı: 6/6 bitti, dağılım 3–3, süre 16.1–56.8 sn (ort. **33.7 sn**) —
  A1 öncesiyle aynı (34.5 sn), akış makinesi tempoyu bozmadı

## v0.8 — A2: lobi ve katılım

`HUMAN_PLAYERS` sabiti **kaldırıldı**. Kim oynayacağı artık LOBİ'de belirleniyor:

- Lobi ekranı dört koltuğu listeler: **Cenk (MAVİ) • Aslı (KIRMIZI) • Deniz (MAVİ) • Selim (KIRMIZI)**
- Kendi ATIŞ tuşuna basan koltuğa oturur (`✔ KATILDI`)
- Katıldığın tuşa **tekrar** basmak maçı başlatır
- Boş kalan koltuklar bot olur; kod dosyası düzenlemeye gerek yok

Karakterler GDD §4'ten. Aynı takımın iki oyuncusu ayırt edilebilsin diye ikinci
koltuk açık tonda (`Cfg.seat_color`).

### Doğrulama
- Koltuk testi: 2 insan (Cenk, Selim) + 2 bot (Aslı, Deniz) kurulumu doğru —
  insan koltuklarında beyin yok, bot koltuklarında var
- Bot maçı: 18 maç, kilitlenme yok, ort. ~34 sn

**Ölçüm notu:** ilk 6 maçın 6'sını da takım 1 kazandı (%3 ihtimal). Yanlılık
şüphesiyle 12 maç daha koşuldu, onlar 7–5 çıktı; toplam 18 maçta 11–7. Yani
sistemsel bir yanlılık değil, örneklem küçüklüğüydü. Küçük örneklemde
"dağılım bozuk" demeden önce örneklemi büyütmek gerekiyor.

## v0.9 — A3: misket skor sistemi

GDD §6: *"her oyun sıralamaya göre misket dağıtır (4/2/1/0)"*.

- `ScoreBoard` misketleri **oyunlar arası taşıyor**; SKOR ekranında sıralama
  tablosu çıkıyor (isim, takım, toplam misket, bu oyunda kazanılan `+n`)
- Sıralama ölçütü sözleşmede: `RoundBase.get_ranking()`. Yakan top şöyle sıralıyor —
  **kazanan takım önce → takım içinde çok yakan önce → eşitlikte ayakta kalan önce →
  son çare koltuk sırası** (deterministik, testlerde tekrarlanabilir olsun diye)
- Bunun için oyuncuya `burns_dealt` sayacı eklendi (kapma da sayılır)
- FFA oyunlar geldiğinde `get_ranking()` bitiş sırasını döndürecek; `ScoreBoard`
  değişmeyecek

Ayrıca `PRACTICE_TIME` kanepede onaylandığı için `Cfg`'ye taşındı (kilitli sabit).

### Doğrulama
autotest artık **iki ardışık oyun** koşup toplam misketi denetliyor: her oyun
4+2+1+0 = 7 dağıtır, iki oyun sonunda toplam 14 olmalı. 4 bağımsız koşumun
dördü de geçti; misketler oyunlar arası doğru taşındı.

## v0.10 — okunabilirlik (kanepe geri bildirimi)

Skor tablosu ekranda arenanın üstüne biniyordu ve okunmuyordu (lobide de aynı
sorun daha hafif haldeydi). Gri kutuda okunabilirlik sanattan önce gelir:

- Bekleme fazlarında (LOBİ / BRİFİNG / SKOR) sahaya **karartma katmanı** iniyor
- Lobi ve skor metinleri artık koyu, yuvarlak köşeli bir **zemin kutusunun**
  içinde — arenanın üstünde bile net okunuyor
- Kutular metin bittiğinde tamamen gizleniyor (boş koyu dikdörtgen kalmıyor);
  düdük yazısı 1.5 sn sonra kutusuyla birlikte siliniyor

## v0.11 — A4: rol bazlı brifing modülü

GDD §6: *"Rol bazlı 3 satırlık Kural Karesi (AMAÇ/YANMA/ŞİDDET — 1v3'te ebenin
kartı farklı), Hakem'in ölü sesli anlatımı."*

`Briefing` sahneden bağımsız bir modül: tur şu üçünü doldurur, o çizer.

| Sözleşme | Ne yapar |
|---|---|
| `get_hakem_line()` | Hakem'in ölü sesli tek cümlesi |
| `get_roles()` | bu turdaki roller (`[""]` = tek rol) |
| `get_rule_card(role)` | o role ait AMAÇ / YANMA / ŞİDDET |

Tek rollü oyunlarda (yakan top) hiçbir şey değişmiyor — tek kart, rol başlığı yok.
1v3 geldiğinde ebe ve koşucu kendi kartını görecek; modülün tek satırı değişmeyecek.

### Doğrulama
`--sobe-briefingtest` (CI'da koşuyor): gerçek yakan top turu tek kart + Hakem
satırı üretiyor, rol başlığı çıkmıyor. Daruma-san'ın yerine geçen sahte 1v3
turu iki ayrı kart üretiyor (`— EBE —` / `— KOŞUCU —`) ve metinleri farklı.

Ayrıca ekrandaki sürüm etiketi artık `Cfg.BUILD_LABEL`'dan geliyor — elle
güncellenen ikinci bir yer kalmadı (v0.2 ve v0.9 kaymaları bu yüzden olmuştu).

## v0.12 — üst şerit ve "YANDIN" uyarısı (kanepe geri bildirimi)

**Sorun:** *"Oyun başladıktan sonra deneme yazan kart sabit kalıyor ve ekran o
karttan dolayı görünmüyor."*

Ortadaki büyük metin kutusu oyun sırasında da kullanılıyordu ve arenanın tam
üstüne oturuyordu. Zamanlamayı kurcalamak yerine yapıyı değiştirdim:

- **Ortadaki büyük kutu artık YALNIZ lobide.** Oyun sırasında arenayı hiçbir
  şey kapatamaz — bu bir zamanlama düzeltmesi değil, yapısal garanti.
- Oyun içi bildirimler (deneme sayacı, düdük, yanma uyarısı) ekranın
  **tepesindeki ince şeride** taşındı.

**Ayrıca — "YANDIN" uyarısı.** Mezarlık sahanın KARŞI ucundadır: yanınca
karakterin rakip takımın arkasına ışınlanır. Bunu bilmeyen oyuncu kendini
kaybediyor ve "tuşlarım çalışmıyor" sanıyor. Artık yanan insan oyuncuya üst
şeritte kalıcı uyarı çıkıyor: *"YANDIN — mezarlıktasın: sahanın KARŞI ucunda,
koyu renkli olansın."*

### Doğrulama
Düdük anında üst şerit görünür, ortadaki kutu gizli; 2.5 sn sonra şerit de
temizleniyor, ortadaki kutu hâlâ gizli. Autotest bozulmadı (SKOR OK, 14 misket).

## v0.13 — deneme atışı 10 sn ve "hazırım" ile erken düdük

Kullanıcı: *"geri sayım olmasın, oyuncular hazır olunca başlasın. 20 sn yerine 10 sn."*

- `Cfg.PRACTICE_TIME` 20 → **10 sn**
- 10 saniye artık zorunlu bekleme değil, **üst sınır**: hazır olan oyuncu ATIŞ
  tuşuna basınca düdük hemen çalıyor
- Üst şerit bunu söylüyor: *"DENEME ATIŞI — 7 sn (kimse yanmaz) • ATIŞ tuşu: HAZIRIM"*

Not: 20 sn daha önce kanepede onaylanmıştı; oynadıkça revize edildi. Kararların
değişmesi normal — `GOREVLER.md`'deki kanepe kayıtları buna göre güncellendi.

## v0.14 — A5: duel-AI çekirdeği

Mendil Kapmaca ve Ruba Bandiera ailesinin ortak beyni. Düellonun tamamı üç sayı:

| Parametre | Ne yapar |
|---|---|
| `reaction_delay` | rakibin hamlesini fark etme gecikmesi (insanlık payı) |
| `bluff_chance` | dalıyormuş gibi yapıp geri çekilme olasılığı |
| `commit_window` | bir kez daldıktan sonra kararlı kalma süresi |

`DuelBrain` sahneden bağımsız: girdi bir sözlük, çıktı bir niyet
(BEKLE / BLÖF / DAL / KAÇ). Bu sayede oyunu çalıştırmadan, tohumla test edilebiliyor.

### Doğrulama (`--sobe-dueltest`, CI'da)
12 düello: hepsi bitiyor • aynı tohum → aynı sonuç • iki taraf da kazanabiliyor.

**Açık madde (B1'e devredildi):** soyut düelloda *"ikisi de yandı"* sonucu hiç
çıkmadı — eşit hızda, mendili kapan her zaman kaçıyor. GDD'de mendilin büküm
noktası tam da bu (*"kapıp kaçarken dokunulursan ikisi de yanar → blöf ve
vazgeçme taktiği"*). Yakalama penceresi açılmazsa blöf dekoratif kalır. Testte
bu sayı bilgi olarak basılıyor; gerçek geometride kovalayanın kesme açısı olmalı.

## v0.15 — B1: Mendil Kapmaca gri kutusu (kısmi)

İkinci oyun sahada. `RoundBase` sözleşmesi sınavı geçti: akış, skor, brifing ve
lobi sistemlerinin **tek satırı değişmeden** yeni bir oyunu kaldırdı.

    godot --headless --path . -- --sobe-round=mendil

- 1v1: mendil ortada, kapan kendi çizgisine dönerse sayar, önce 3 sayı kazanır
- Kapıp kaçarken dokunulursan ikisi de yanar, puan kimseye yazılmaz
- Taşıyan yavaşlar (`MENDIL_CARRY_SPEED`)
- Botlar `DuelBrain` kullanıyor; kişilikler GDD §4 karakterlerinden
  (Cenk tez canlı/az blöf, Aslı sabırlı/çok blöf, Selim en sabırlı)

**Mimari kazanç:** bot beynini artık TUR seçiyor (`RoundBase.make_brain`),
Main değil. Yakan topun dodge çekirdeği ile mendilin duel çekirdeği aynı şey
değil; bu ayrım olmadan mendil sahasında yakan-top botları dolaşıp kilitleniyordu.

### ⚠️ B1 KAPATILMADI — bitti şartı sağlanmadı

| Ölçüt | Hedef | Ölçülen |
|---|---|---|
| Düello süresi | 15-45 sn | **14.0 sn** (10.1–21.3) |
| Karakter dengesi | %10-15 avantaj | **Cenk 9/10** |
| "İkisi de yandı" | oyunun çekirdeği | **50 düelloda 0** |

Beş ayar turu denendi ve hiçbiri gerilimi doğurmadı. Teşhis: bu bir sabit
ayarı değil **mekanik** sorunu — 1B koridorda eşit hızlı kovalayan, avans almış
kaçanı yakalayamıyor. Seçenekler `GOREVLER.md` → AÇIK KARARLAR'da; hangisinin
eğlenceli olduğu ancak elle oynanarak anlaşılır.

## Not
Bu proje sanal ortamda yazıldı; ilk açılışta hata çıkarsa mesajı olduğu gibi
Claude'a / Claude Code'a yapıştır. Sonraki adım için: klasörü Claude Code ile aç →
"CLAUDE.md'yi oku, test senaryosu 5'i koş, sonra sıradaki görevi yap."

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

## v0.16 — B1 teşhisi: mendil 1B'de çalışmıyor

Kovalama penceresi mekaniği eklendi (yakalama yalnız kapıştan sonraki 1.1 sn
içinde mümkün) — ama sorunu çözmedi ve **niye çözmediği asıl bulgu**:

| Denenen | Sonuç |
|---|---|
| Taşıyan hızı 0.78 | kapan **hiç** yakalanmıyor |
| Taşıyan hızı 0.68 | kapan **hiç** kaçamıyor, tur bitmiyor |
| Yakalama menzili 1.4 | hep yakalanır, tur bitmiyor |
| Kovalama penceresi 1.1 sn | yine 0 yakalama |

Gradyan yok, bıçak sırtı var. Aritmetiği: iki bot mendile 2.2 m'de bekler,
biri 0.37 sn'de kapar, ötekinin tepki gecikmesi 0.22-0.48 sn — rakip daha tepki
verirken iş bitmiş, kapış anında 3 m uzakta.

**1B koridorda kovalayan tekdüze daha hızlıysa sonuç baştan bellidir: karar anı
yoktur, sadece aritmetik vardır.** Hiçbir sabit bunu değiştiremez.

➜ **Önerilen çözüm: düelloya ikinci boyut.** Koridor şerit olsun, kaçan yana
kırabilsin, kovalayan yanılabilsin. Sonuç aritmetik olmaktan çıkar, okuma ve
refleks meselesi olur — blöf de o zaman gerçekten kazandırır. Bu bir ayar değil,
B1'in yeniden tasarımı.

## v0.17 — B1 çekirdeği: Kaçış Düellosu (okuma savaşı)

Kullanıcı tasarım kartı. Kovalamaca **pozisyon savaşından okuma savaşına**
çevrildi. `DuelEncounter` sahneden bağımsız: girdi iki hamle, çıktı bir sonuç —
bu sayede denge 3B'ye hiç bağlanmadan ölçülebiliyor.

### Çözüm matrisi
|            | LUNGE_L | LUNGE_R | LUNGE_DÜZ | POZİSYON |
|---|---|---|---|---|
| **KIRMA SOL** | YAKALA | kaçar | kaçar | çekişme |
| **KIRMA SAĞ** | kaçar | YAKALA | kaçar | çekişme |
| **KAYMA** | YAKALA | YAKALA | kaçar (altından) | kaçar |
| **DURAKLAMA** | kaçar* | kaçar* | kaçar* | çekişme |

\* yalnız **erken** yapılmış hamleyi boşa düşürür.

### Ölçülen denge
| Bot tepkisi | Kaçış oranı |
|---|---|
| 0.30 sn (kolay) | %61.5 |
| **0.17 sn (varsayılan)** | **%51.5** |
| 0.11 sn (zor) | %22.5 |

Hedef bant %35-65; varsayılan zorluk göbekte.

### Yolda bulunan iki hata
1. **Alışkanlık okuma dejenereydi.** `argmax` kullanıyordum: sayaçlar
   517/483/498/502 iken %1'lik fark botu sonsuza kadar aynı yöne kilitliyordu
   (1779 hamlenin 1223'ü sola, 23'ü sağa). Oranla seçime çevrildi + eski
   alışkanlık soluyor.
2. **Zorluk parametresi ölüydü.** Tell'ler 0.10-0.18 sn, bot tepkisi 0.22-0.35 —
   yani bot hiçbir tell'i okuyamıyordu, üç zorluk da aynı sonucu veriyordu.
   Kademeler tell'lerin etrafına alındı. Ayrıca okumak artık garanti değil
   (`read_accuracy` 0.8); %100 okuma hızlı botu %8.8'e düşürüyordu.

### Kart şartına düzeltme
Kart "16 deterministik düello" diyordu; bu istatistiksel olarak yetersiz.
Gerçek oran %51.5 iken 16 düello %75 gösterdi (12/16) — sırf gürültü.
CI kapısı **400 düello** kullanıyor (saf mantık, maliyeti yok) ve ayrıca
zorluk eğrisinin monoton olduğunu doğruluyor.

## v0.18 — B1: kaçış düellosu sahaya bağlandı

Doğrulanmış çekirdek (`DuelEncounter`) artık mendil turunda çalışıyor.

- Kovalayan **%8 daha hızlı** → düz koşuyla kaçış imkânsız, düello mecburi
  (çemberde oyalanma da böylece baskın strateji olmaktan çıktı)
- `ENGAGE_RADIUS` 2.2 m içine girilince karşılaşma tetikleniyor; 0.7 sn yavaş çekim
- Kaçan: KIRMA SOL/SAĞ • KAYMA • DURAKLAMA — her birinin kendi tell süresi var
- Kovalayan: LUNGE SOL/SAĞ/DÜZ • POZİSYON
- Iskalayan kovalayan 0.5 sn toparlanıyor, kaçan mesafe kazanıyor
- **Skor klasiğe döndü:** temas = kovalayan sayı, çizgi = kaçan sayı.
  GDD'nin "ikisi de yanar" bükümü `Cfg.MENDIL_MUTUAL_BURN` bayrağında (varsayılan
  kapalı) — 1v1 ağacında teşvikleri bozuyordu
- Anti-stall: karşılaşma olmadan 10 sn geçerse mendil ortaya döner

### Ölçülen (10 düello, saf bot)
| | |
|---|---|
| Kaçış oranı | **%42.9** (49 karşılaşma / 21 kaçış) ✅ bant %35-65 |
| Kazanan dağılımı | 6–4 ✅ |
| Kilitlenme | yok ✅ |
| Süre | 12.7 sn (9.5–14.8) ❌ hedef 15-45 |

**Açık kalan tek ölçüt süre.** Koşu mesafesini 6.5→8.0 m yaptım, süre değişmedi —
yani zaman koşuda değil, **kapıştan önceki bekleşmede** geçmeli. Botlar mendile
fazla çabuk dalıyor; çember etrafındaki blöf/okuma safhası neredeyse hiç
yaşanmıyor. Çözüm oradadır.

## v0.19 — lobide oyun seçimi

Mendil yalnız komut satırı bayrağıyla açılıyordu; editörden F5'e basınca hep
yakan top geliyordu. Artık **lobide TAB ile oyun değiştiriliyor**:

```
SOBE

OYUN:  Mendil Kapmaca 1v1      [TAB] oyunu değiştir

P1  Cenk (MAVİ)     ✔ KATILDI
...
```

Oyun değişince tur, saha nesneleri ve Kural Karesi birlikte değişiyor; top
gerekmeyen turda sahadan top kaldırılıyor. Skor da sıfırlanıyor.

Doğrulandı: Yakan Top → top 1 • Mendil → top 0 • geri → top 1.
`--sobe-round=mendil` bayrağı CI için duruyor.

Bu, E3'ün (Serbest Maç menüsü) çekirdeği — menü geldiğinde aynı yol kullanılacak.

## v0.20 — mendil görünür oldu

Kullanıcı: *"Mendil tutulmuyor ayrıca hareketler belli değil."*

Mendil aslında taşınıyordu; sorun **hiçbir geri bildirim olmamasıydı**. Kim
mendili aldı, karşılaşma ne zaman oldu, hangi hamle yapıldı, sayı neden değişti —
hiçbiri ekranda yoktu. Görünmeyen kural yok sayılır.

- `RoundBase.get_status_text()` sözleşmeye eklendi: tur ne olup bittiğini kendi
  anlatıyor, Main sadece çiziyor
- Üst şeritte canlı durum: **MENDİL: Cenk    Cenk 2 - 1 Aslı**
- Karşılaşma anı: **▶ KARŞILAŞMA!**
- Sonuç satırı: **Cenk DURAKLADI ↔ Aslı SAĞA ATILDI → KAÇTI!**
- Faul, kapış ve süre aşımı da yazılıyor
- Mendil büyütüldü (0.4 → 0.75 m) ve parlatıldı; taşıyanın başının üstünde duruyor

**Ayrıca gerçek bir hata:** kapma yalnız `x` mesafesine bakıyordu, yanal
kayıklığı hiç saymıyordu — yandan geçen de mendili kapabiliyordu. 3B mesafeye
çevrildi.

## v0.21 — CI düzeltmesi ve süreç dersi

**Hata:** Tur kurulumu `_kur_tur()`'e taşınırken eski `round_finished.connect()`
satırı silinmemişti; sinyal iki kez bağlanıyordu.

```
ERROR: Signal 'round_finished' is already connected ... at: _ready (main.gd:49)
```

**Asıl mesele bunun neden yakalanmadığı:** yerel kontrolüm yalnız
`SCRIPT ERROR|Parse Error` arıyordu, CI ise düz `ERROR:` de arıyor. Godot bu tür
hataları çalışmayı durdurmadan basıyor — yerel grep görmüyor, CI görüyordu.
Yani **CI benim kontrolümden katıydı** ve iki commit üst üste kırmızı gitti.

Düzeltme: `scripts/kontrol.sh` eklendi — CI'nin birebir aynısını yerelde koşuyor
(parse → smoke → mendil smoke → dört test). `CLAUDE.md`'ye de kural olarak yazıldı.

## v0.22 — B1 KAPANDI: temas ve ıska görünür oldu

Kullanıcı: *"Mendili kapan kendi yerine varmadan bitiyor, ayrıca yakala nasıl
oluyor, dokununca yanma yok."*

İkisi de tek kusurun iki yüzüydü: **düello soyut çözülüyordu.** 2.2 m mesafede
gizli bir taş-kağıt-makas hesaplanıp sayı veriliyordu; ekranda ne temas vardı ne
çizgiye varış. Artık çözüm fiziksel:

- **YAKALANDI** → kovalayan fiilen kaçanın üstüne gelir, *"DOKUNDU!"* yazar,
  0.9 sn durur, sonra sayı yazılır
- **KAÇTI** → kovalayan hamlesinin hızıyla **yanından geçip ıskalar**,
  *"ISKA! — çizgine koş!"* yazar; kaçan çizgiye varınca sayıyı alır
- Gösterim boyunca ikisi de donar, olan biten görülür

### Ölçülen — bitti şartı SAĞLANDI
| Ölçüt | Hedef | Ölçülen |
|---|---|---|
| Kaçış oranı | %35-65 | **%37.9** ✅ |
| Süre | 15-45 sn | **15.9 sn** (10.2–25.6) ✅ |
| Kilitlenme | yok | **0/6** ✅ |

Süreyi çözen şey ayar değil **görünürlük** oldu. Yedi ayar turunda kovaladığım
15 saniye, temas ve ıskayı ekranda göstermenin yan ürünü olarak geldi.

## v0.23 — üç kanepe hatası

**1. "Kırmızıya dokunsam da sayı alamıyorum" — girdi eşleşmesi yanlıştı.**
Kırma YANAL bir hamledir: koşu ekseni `x`, kırma ekseni `z`. Ben hamle yönünü
`x`'ten okuyordum — yani kovalarken ileri basan oyuncu "yana atıldı" sayılıyor,
karşılaşmayı kaybediyordu. Artık ↑/↓ = yana kır/atıl, ATIŞ = kay/düz atıl,
hiçbir şeye basmamak = durakla/bekle.

**2. "Mendil yere düşüyor, sonra tekrar başına geliyor" — gerçek hata.**
Çözüm gösterimi (temas/ıska) sırasında `_process` erken dönüyordu ve mendil
taşıyanı izlemiyordu: gösterim boyunca havada asılı kalıp sonra sıfırlamayla
ortaya ışınlanıyordu. Mendil artık **her durumda** taşıyanı izliyor.

**3. "Mendil bendeyken yavaş hareket ediyorum" — hata değil, tasarım.**
Ama söylenmiyordu. Kovalayan %8 hızlı, taşıyan %8 yavaş; bu bilerek böyle,
çünkü düz koşuyla kaçış mümkün olsaydı karşılaşma hiç yaşanmazdı. Kural
Karesi'ne yazıldı: *"Mendil sendeyken YAVAŞSIN ve kovalayan daha hızlıdır —
bilerek. Kaçış koşuyla değil, KARŞILAŞMADA kazanılır."*

Ayrıca karşılaşma anında insan oyuncuya ne yapacağı yazılıyor:
*"KAÇAN → ↑/↓ kır • ATIŞ kay • boş bırak durakla"*

Denge korundu: kaçış %55.6, süre 16.6 sn, kilitlenme yok.

## v0.24 — blöf insana karşı da işliyor

Kullanıcı: *"Blöf neye göre atılıyor anlamadım."*

Oyunda **iki ayrı blöf** var ve ikisi de farklı şeyi cezalandırır:

**1. Çember blöfü (kapıştan önce).** Resmi kural: rakibini kandırıp mendili
almadan çembere sokarsan sayı senin. Dalacakmış gibi yapıp geri çekilirsin.

**2. DURAKLAMA (karşılaşmada).** Kırmak ya da kaymak yerine ani fren.
Kovalayan **erken** atıldıysa havada kalır, sen geçersin. Sabırla beklediyse
işe yaramaz. Yani duraklama **sabırsızlığı** cezalandırır.

### Bulunan hata
Kovalayan bot için "erken atıldı mı" hesaplanıyordu ama **insan kovalayan için
hep `false`** yazılmıştı. Sonuç: insana karşı duraklama asla kazanamıyor, hep
çekişmeye düşüyordu — yani blöf yarısı eksik bir mekanikti.

Artık insanın hamlesini **ne zaman** verdiği ölçülüyor: karşılaşma penceresinin
ilk yarısında atıldıysa ERKEN sayılıyor ve duraklamaya yeniliyor. Ayrıca ilk
verdiği hamle kilitleniyor — pencere içinde fikir değiştirip düzeltemiyor.

Ekrandaki ipucu da açık yazıyor:
```
KAÇAN:      ↑/↓ = yana KIR   ATIŞ = KAY   boş = DURAKLA (erken atılanı yener)
KOVALAYAN:  ↑/↓ = yana ATIL  ATIŞ = DÜZ   boş = BEKLE (duraklamaya karşı güvenli)
            Geç atıl: duraklamaya yakalanmazsın.
```

## v0.25 — çalım hamlesi, ayrı tuşlar, kayarak hareket

Kullanıcı: *"Sağdan giderken aniden solda beliriyor ama neye göre yaptığını
bilmiyorum. Başka tuşlar da eklenebilir: 1 kayma, 2 durup geri çekilme,
3 sağdan gösterip soldan kaçma."*

Üç şey birden düzeltildi:

**1. Hamleler artık ayrı tuşlarda.** Yön + aksiyon karışıyordu ve kazara blöf
yapılıyordu. Şimdi niyet açık:

| Kaçan | Kovalayan |
|---|---|
| **W/S** yana kır | **W/S** yana atıl |
| **[1]** KAY | **[1]** DÜZ atıl |
| **[2]** DURAKLA | boş bırak = BEKLE |
| **[3]** ÇALIM | |

**2. ÇALIM eklendi** (kullanıcının önerisi: sağdan gösterip soldan kaçma).
Matris artık tam — her hamlenin bir karşılığı var, bedava hamle yok:

|  | ATIL SOL | ATIL SAĞ | ATIL DÜZ | BEKLE |
|---|---|---|---|---|
| KIRMA SOL | YAKALA | kaçar | kaçar | çekişme |
| KIRMA SAĞ | kaçar | YAKALA | kaçar | çekişme |
| KAYMA | YAKALA | YAKALA | kaçar | kaçar |
| DURAKLAMA | kaçar\* | kaçar\* | kaçar\* | **YAKALA** |
| ÇALIM | kaçar | kaçar | YAKALA | YAKALA |

\* yalnız **erken** atılana karşı. Ayrıca DURAKLAMA artık sabırlı bekleyene
yakalanıyor — önce hiçbir karşılığı yoktu, yani bedava hamleydi.

**3. Işınlanma bitti.** Hamleler gösterim boyunca **kayarak** yapılıyor:
kaçan yana kırarken, kovalayan yanından geçerken görülüyor. "Aniden solda
beliriyor" şikâyeti buydu.

### Ölçülen
Çekirdek dengesi %41.8 (bant 35-65) • matris 12/12 • süre 17.6 sn (bant 15-45) •
kilitlenme yok • zorluk eğrisi monoton (45.8 → 36.8 → 15.2).

## v0.26 — çalım hatası ve kontrol boşluğu

Kullanıcı debugger panelini gönderdi ve **gerçek bir hata** çıktı:

```
MendilRound._karsilasma: Out of bounds get index '4' (on base: 'Dictionary')
```

ÇALIM'ı hamle enum'una ekledim ama **ekrandaki isim sözlüğüne eklemedim**.
Her çalım hamlesinde hata fırlıyordu. Düzeltildi.

Beş statik uyarı da temizlendi: kullanılmayan sinyal, `round` yerleşik ad
çakışması, kullanılmayan `opp` parametresi, uyumsuz ternary tipleri, enum
yerine int kullanımı.

### Asıl kusur: kontrolüm eksikti
Bu hatayı göremememin sebebi, mendil maçlarını koşarken **sadece `SONUC`
satırlarını** grep etmemdi — hataları hiç aramıyordum. Üstelik 12 saniyelik
smoke'ta çalım hamlesi hiç gelmiyor, yani smoke da yakalayamazdı.

`scripts/kontrol.sh` yeniden yazıldı:
parse → iki oyunun smoke'u → üç birim testi → **tam maçlar**, ve *hepsinin*
çıktısında `SCRIPT ERROR | ERROR: | Out of bounds | Invalid access | Nonexistent`
aranıyor. `CLAUDE.md`'ye de ders olarak yazıldı.

## v0.27 — kaçanın tuşları gerçekten okunuyor

Kullanıcı: *"Ben dokununca kırmızı her zaman kaybetmiyor, rakamlar sanki işe
yaramıyor."*

**Gerçek hata:** kaçanın hamlesi karşılaşmanın **başında** okunuyordu — oyuncu
daha hiçbir tuşa basmamışken. 0.7 saniyelik pencere boyunca bastığı 1/2/3 hiç
okunmuyordu. Artık pencere boyunca dinleniyor ve **ilk gerçek basış kilitleniyor**
(sonradan fikir değiştirilemiyor). Basılmazsa varsayılan DURAKLAMA.

**Ekranda geri bildirim:** karşılaşma sırasında `SEÇTİĞİN: KAYMA` yazıyor.
Tuşun okunup okunmadığını artık gözle görebilirsin.

**"Dokununca kaybetmiyor" — bu hata değil, tasarım.** Dokunmak yakalamanın
*sebebi* değil, *sonucu*: kovalayan doğru hamleyi seçerse dokunur. Hiçbir şeye
basmazsan BEKLE yaparsın; BEKLE yalnız DURAKLAMA ve ÇALIM'ı yakalar. Rakip
yana kırmışsa ya da kaymışsa seni geçer — çünkü sen okumadın, sadece koştun.

## v0.28 — İSTOP (mendilin yerine)

Kullanıcı kararı: Mendil Kapmaca 1.0'dan çıktı, **İstop** girdi. Gerekçe kartta:
doğuştan 4 kişilik FFA (seyirci yok), icat edilmiş meta-sistem gerektirmiyor,
top+kaçma+nişan tekniğini yeniden kullanıyor; 1v1 ağacı silindi, duel-AI ertelendi.

Kurallar araştırıldı ([Milliyet](https://www.milliyet.com.tr/cocuk/eglence/istop-oyunu-nasil-oynanir-6267288),
[Sabah](https://www.sabah.com.tr/yasam/istop-oyununun-kurallari-renksiz-ve-renkli-istop-nasil-oynanir-en-az-kac-kisiyle-oynanabilir-k1-6179275),
[Oyun Kuralları](https://oyunkurallari.org/sokak-oyunlari/istop-oyunu-nasil-oynanir/)):
ebe topu dikine atıp isim çağırır, çağrılan yere düşmeden yakalar ve "istop"
der, herkes donar, top sahibi donmuş birini vurmaya çalışır, vurulan yeni ebe
olur. **Üç adım** ve **İ-S-T-O-P harfleri** kaynaklarda geçmiyor — yaygın yerel
varyantlar, kullanıcı kartındaki haliyle uygulandı.

### Döngü
ÇAĞRI → KAÇIŞMA → **İSTOP! (herkes donar)** → ADIM+ATIŞ → yeni el

- Donmadan sonra `FREEZE_GRACE` (0.15 sn) toleransı; kıpırdayan harf alır
- Top sahibi en fazla 3 adım yürüyüp atar: isabet = hedefe ceza, ıska = atana
- Ceza harfleri İ-S-T-O-P; 5 harf = yandın. Az harfi olan eli kazanır

### İlk ölçüm (4 maç)
| | Kart | Ölçülen |
|---|---|---|
| Maç bitişi | harf ya da el sınırı | 4/4 el sınırı ✅ |
| Ceza yığılması | ≤ %40 | %30 / %30 / %38 / %40 ✅ |
| Tur süresi | 20-30 sn | **20.3 sn** ✅ |
| "Ortalama el süresi" | 20-35 sn | **2.5 sn** ❌ |

**Kartta çelişki:** "Tur döngüsü 20-30 sn, 6-8 el" ile "ortalama EL süresi
20-35 sn" uyuşmuyor — 8 el 20-30 saniyeye sığacaksa el ~3 sn olur. Ölçüm tur
döngüsü tarifine uyuyor. Kullanıcı onayı bekliyor.

**Ayrıca:** hiçbir maç harf sınırıyla bitmedi (en yüksek 4/5). Harf sistemi
8 elde nadiren doluyor.

Mendil oynanabilir listeden çıktı ama **kodu depoda duruyor** (doğrulanmış
dengesiyle); `--sobe-round=mendil` bayrağıyla hâlâ açılıyor. 2. dalgada hazır.

## v0.29 — "Identifier not declared" sorunu kökten çözüldü

Kullanıcı pull edip oyunu açtı, şu hatayı aldı:
```
main.gd:170 - Parse Error: Identifier "IstopRound" not declared in the current scope
Failed to load script "res://scripts/main.gd"
```

Dosyalar depodaydı ve bende çalışıyordu. Sebep: Godot `class_name` kayıtlarını
`.godot/` içinde tutar, o klasör git'te yoktur, ve **açık editör pull sonrası
yeni dosyaları taramaz.** Yani ben her yeni sınıf dosyası eklediğimde karşı
tarafta oyun tamamen kırılıyordu.

"Projeyi tekrar yükle" demek çözüm değil — her seferinde tekrarlanacak bir
zahmet. Yapısal düzeltme:

**Turlar ve beyinler artık `preload("res://...")` ile bağlanıyor.** `preload`
yola bakar, sınıf kaydına bakmaz. `class_name` satırları dosyalarda duruyor
(editör kolaylığı) ama artık onlara *bağımlı* değiliz.

**Doğrulama:** sınıf kayıt dosyasından `IstopRound` ve `IstopBrain` elle
silindi — kullanıcının durumu birebir taklit edildi — ve oyun sorunsuz koştu.

Kural `CLAUDE.md`'ye yazıldı: yeni dosyalar `preload` ile bağlanır.

## Not
Bu proje sanal ortamda yazıldı; ilk açılışta hata çıkarsa mesajı olduğu gibi
Claude'a / Claude Code'a yapıştır. Sonraki adım için: klasörü Claude Code ile aç →
"CLAUDE.md'yi oku, test senaryosu 5'i koş, sonra sıradaki görevi yap."

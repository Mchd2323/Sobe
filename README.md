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

## Not
Bu proje sanal ortamda yazıldı; ilk açılışta hata çıkarsa mesajı olduğu gibi
Claude'a / Claude Code'a yapıştır. Sonraki adım için: klasörü Claude Code ile aç →
"CLAUDE.md'yi oku, test senaryosu 5'i koş, sonra sıradaki görevi yap."

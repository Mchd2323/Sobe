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

## Not
Bu proje sanal ortamda yazıldı; ilk açılışta hata çıkarsa mesajı olduğu gibi
Claude'a / Claude Code'a yapıştır. Sonraki adım için: klasörü Claude Code ile aç →
"CLAUDE.md'yi oku, test senaryosu 5'i koş, sonra sıradaki görevi yap."

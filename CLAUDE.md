# SOBE — Claude Code Proje Sözleşmesi (v0.2)

Tasarım kaynağı: `sobe-gdd-v1.md` (v1.1 revizyonlu). Çelişkide GDD kazanır.

## Proje kimliği
- Godot 4.7+, GDScript, low-poly 3D, paylaşımlı tek kamera (bölünmüş ekran YOK).
- 1-4 yerel oyuncu; boş koltuklar bot. v1 online = Steam Remote Play Together.
- Dönem kilidi ~1975–1999: sahnede telefon/ekran/modern araç ASLA.
- **1.0 kapsamı: 4 ülke / 6 oyun** (TR: yakan top + mendil • İT: seksek •
  JP: beigoma + daruma 1v3 • CO: tejo). Gerisi güncelleme dalgası.

## Akış makinesi (A1)
- `GameFlow` (scripts/game_flow.gd) faz otoritesidir:
  **LOBİ → BRİFİNG → DENEME ATIŞI (20 sn ölümsüz) → OYUN → SKOR.**
- Main yalnız `phase_changed` sinyalini dinler ve arayüzü çizer; faz mantığı
  Main'e YAZILMAZ. Yeni mini oyun eklemek bu akışı değiştirmez.
- Deneme atışı `RoundBase.practice` bayrağıyla yürür: kurallar işler, kimse yanmaz.
  Bayrağı GameFlow açıp kapatır, uygulamak turun işidir (otorite turda kalır).
- CI/otomatik test `flow.skip_to_playing()` ile lobi-brifing-deneme adımlarını atlar.

## Mimari sözleşme
- Her mini oyun `RoundBase` (scripts/round_base.gd) sözleşmesini doldurur:
  `get_rule_card()` (3 satır), `setup()`, `start()`, `get_bounds()`,
  `on_player_hit()`, `on_catch()`, `on_ball_reset()`, `get_countdown()`,
  `round_finished` sinyali.
- **Main yalnız RoundBase arayüzünü çağırır** — tur-özel metod çağrısı yasak.
  Yeni olay gerekiyorsa önce sözleşmeye eklenir.
- **Online-uyumlu mimari kısıtı (bugünden):** oyun durumu otoritesi TEK yerde
  (round node) yaşar; oyuncu scriptleri durum kararı vermez, olay raporlar
  (`game.report_*`). Simülasyon girdilerden türer; oyuncu-başına fizik hilesi
  yok. Netcode şimdi yazılmaz ama bu disiplin sayesinde sonradan eklenebilir.
- AI yalnız paylaşımlı çekirdeklerden: dodge / duel / race / spin / ebe (1.0
  için 5 çekirdek). **Bot bütçesi gerçek bir kalemdir:** her çekirdek için
  ayar (tuning) süresi, kod süresine eşit planlanır; botlara "okunabilir
  kusur" kişilikleri Faz 2 işi.
- Fizik sabitleri SADECE `scripts/constants.gd` (`Cfg`) içinde yaşar.

## ⚠️ HER OYUN ÖNCE ARAŞTIRILIR (kullanıcı kuralı)

Yeni bir mini oyuna kod yazmadan ÖNCE gerçek kuralları araştır: oyun alanı ve
diziliş, kim nereden koşar, sayı nasıl alınır, hangi hareket faul, varyantlar.
Bulguları görev maddesine yaz, sonra tasarla.

**Neden:** Mendil kapmaca (B1) araştırılmadan yazıldı. Sonuç: yedi ayar turu
boşa gitti çünkü iki kural bilinmiyordu —
1. Koşucu kendi grubunun **ters hizasında** başlar (kaçan rakibin üstünden
   geçmek zorunda). Bunsuz kovalayan hep geride kalıyor, hiç yakalayamıyor.
2. **Rakibini çembere sokmak sayıdır.** Bunsuz blöf saf zarar; ölçümde az blöf
   yapan karakter 9/10 kazanıyordu.
Hiçbir sabit ayarı bu ikisinin yerini tutmadı. Kural bilgisi tasarımın
girdisidir, süsü değil.

## Kovalamaca ilkesi (kalıcı)
Hiçbir kovalamaca saf 1B bırakılmaz — British Bulldog ve Patintero için de
geçerli. Tek eksende kovalayan ya hep yakalar ya hiç yakalayamaz; ara yoktur.
(Mendilde yedi ayar turu bunu kanıtladı; çözüm yanal blöf/okuma katmanıydı.)

Not: "çapraz ateş yakan top" kartı KAPI 1 yedeği olarak duruyor — UYGULANMAZ,
yalnız kanepe testinde tempo sorunu çıkarsa gündeme gelir.

## ⚠️ YENİ DOSYALAR `preload` İLE BAĞLANIR, `class_name` İLE DEĞİL

Godot `class_name` kayıtlarını `.godot/global_script_class_cache.cfg` içinde
tutar. O klasör `.gitignore`'da (olmalı da). Sonuç: kullanıcı pull ile yeni bir
sınıf dosyası aldığında **açık editör onu taramaz**, sınıf kayıtlı olmaz ve
`main.gd` "Identifier ... not declared" ile parse edilemez — oyun HİÇ açılmaz.
Bir dosya eklemek, karşı tarafta oyunu tamamen kırabiliyor.

**Kural:** bir script başka bir script'e atıfta bulunacaksa
`const X := preload("res://scripts/x.gd")` kullan. `preload` YOLA bakar,
sınıf kaydına bakmaz. `class_name` satırı dosyada kalabilir (editör kolaylığı)
ama ona BAĞIMLI olunmaz.

Doğrulama yöntemi: `.godot/global_script_class_cache.cfg` dosyasından yeni
sınıfları elle silip oyunu koştur — kullanıcının durumunu birebir taklit eder.

## Kod standartları
- `class_name` + açık tipler; sinyaller `snake_case`; gri kutu fazında sahneler kod-önce.
- Kod İngilizce, oyun metni Türkçe.
- Sıra: tasarım kartı → gri kutu → 4 girişli test → sanat. Atlanmaz.

## Test senaryoları (her değişiklikte)
1. HUMAN_PLAYERS=1: bot maçı kendi kendine bitiyor mu? Top hiç kayboluyor mu?
   (duvarlar + 6 sn sahipsiz-top sıfırlaması bunu engellemeli)
2. HUMAN_PLAYERS=2: WASD vs oklar — çakışma yok mu?
3. Kapma: doğru anda Boşluk → atan yanıyor mu?
4. Seken top söndü mü? Takım arkadaşına çarpan top söndü mü?
5. **MEZARLIK DÖNÜŞÜ (1 numaralı his testi):** `Cfg.MEZARLIK_RETURN` true/false —
   hangisi daha eğlenceli? İki ayarla da 3'er maç oyna, notunu buraya yaz.

## Kilitli his sabitleri (kanepe kararı — GDD 11b)
`THROW_SPEED = 14` ve `PLAYER_SPEED = 6` gerçek oynanış testinde onaylandı.
Bu ikisi gerekçesiz DEĞİŞTİRİLMEZ. Açık kalanlar: `MEZARLIK_RETURN`,
`BALL_RESET_TIME` (tempo), `DROP_COUNTDOWN`.

## ⚠️ PUSH ÖNCESİ KONTROL = CI İLE AYNI KATILIKTA

CI iki kez kırmızıya döndü çünkü yerel kontrolüm CI'dan **gevşekti**:
ben yalnız `SCRIPT ERROR|Parse Error` arıyordum, CI ise düz `ERROR:` de arıyor.
Godot bazı hataları (örn. "Signal already connected") çalışmayı durdurmadan
basar — yerel grep görmez, CI görür.

**İKİNCİ DERS:** smoke yetmez. Kullanıcının debugger'ında çıkan
`Out of bounds get index '4'` hatası, ÇALIM hamlesi oynandığında fırlıyordu —
12 saniyelik smoke'ta o hamle hiç gelmedi. **Tam maçların çıktısı da hata için
taranmalı**, sadece `SONUC` satırı okunmamalı.

`scripts/kontrol.sh` bunu yapar: parse → smoke (iki oyun) → üç birim testi →
tam maçlar, ve HEPSİNİN çıktısında `SCRIPT ERROR|ERROR:|Out of bounds|
Invalid access|Nonexistent` aranır.

**Push etmeden önce koşulacak dizi (CI'nin birebir aynısı):**
1. `--headless --editor --quit` → `SCRIPT ERROR|Parse Error` yoksa geç
2. `--headless` 12 sn → **`SCRIPT ERROR|ERROR:`** yoksa geç (ERROR: dahil!)
3. Aynısı `-- --sobe-round=mendil` ile
4. `--sobe-encountertest`, `--sobe-briefingtest`, `--sobe-dueltest`, `--sobe-autotest`

## CI
Her push: parse kontrolü + smoke + 3 bot maçı (`--sobe-autotest`).
Yeni mini oyun eklendiğinde kendi bot maçı testini bu kancaya ekler.

## Sıradaki görevler
- [ ] Mendil Kapmaca 1v1 gri kutu (duel-AI: tepki gecikmeli blöf)
- [ ] Skor: misket dağıtımı (4/2/1/0) + damga
- [ ] Deneme Atışı fazı (20 sn ölümsüz) brifing modülüne
- [ ] Daruma-san 1v3 (ebe-AI + "Ebe seni izliyor" telegraf kalıbı)
- [ ] Kamp sahnesi iskeleti

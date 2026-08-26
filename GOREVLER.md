# SOBE — GÖREVLER.md (üretim sırası)

> Bu dosya repo kökünde yaşar. Code görevleri **sırayla** yürütür, her görevi
> "bitti şartı" sağlanınca ve **CI yeşilken** kapatır (`- [x]`), commit mesajına
> görev ID'sini yazar (`[A1] ...`). Kaynak hiyerarşisi: GDD v1.1 > CLAUDE.md > bu dosya.

## Çalışma Protokolü
0. **Yeni mini oyuna başlamadan gerçek kurallarını ARAŞTIR** (alan, diziliş,
   kim nereden koşar, sayı, faul, varyantlar). Bulguları göreve yaz, sonra kod.
   Bkz. `CLAUDE.md` — B1'de bu atlandı ve yedi ayar turu boşa gitti.
1. Her göreve başlamadan `CLAUDE.md` ve GDD'nin ilgili bölümünü oku.
2. Denge/his sabitleri YALNIZ `Cfg`'de yaşar; her yeni sabit CHANGELOG satırı alır.
3. `RoundBase` sözleşmesi ve online-uyumlu mimari kısıtı (otorite round'da,
   oyuncular olay raporlar) her görevde geçerlidir.
4. Her yeni mini oyun CI'a kendi bot-maçı testini ekler (autotest kancası üzerinden).
5. 🛑 **KAPI** görevlerinde DUR: kullanıcıya tek paragraf durum raporu + test
   talimatı yaz, onay gelmeden sonraki bloğa geçme. Kapı dışında durma, ilerle.
6. Bir görev tahminden büyük çıkarsa böl, ama sırayı bozma. Takıldığın kararı
   "AÇIK KARARLAR" bölümüne yaz, varsayılanla ilerle.

---

## BLOK A — Çekirdek Altyapı

- [x] **A0 — Bekleyen iki onaylı iş:** `on_catch` mezarlık cezası (`Cfg` bayraklı,
  varsayılan açık) + CI'a `--sobe-autotest` bot maçı testi (3 maç, ayrı script,
  bayrak yoksa yüklenmez). *Bitti şartı:* CI'da bot maçı adımı yeşil. ✅ **Kapandı** (7e58631, run #2 yeşil — 3 maç 63 sn).
  Ek olarak: sayışma (`DROP_COUNTDOWN`/`DROP_KEEPOUT`) ve UI ortalama düzeltmesi aynı commit'te.
- [x] **A1 — Akış makinesi (`GameFlow`):** LOBİ → BRİFİNG → DENEME ATIŞI (20 sn
  ölümsüz) → OYUN → SKOR. Round'lar sözleşme üzerinden takılır. *Bitti:* yakan top
  bu akışın içinde oynanıyor, autotest hâlâ geçiyor. ✅ **Kapandı** (90b0397, run #7 yeşil).
  Akış testi: BRİFİNG→DENEME ATIŞI→(20 sn)→OYUN doğru, deneme atışında hiç yanma yok.
  Bot maçı 6/6, 3–3, ort. 33.7 sn (A1 öncesi 34.5 sn — tempo bozulmadı).
- [x] **A2 — Lobi & katılım:** "tuşa bas, katıl" ekranı; katılmayan koltuk bot;
  4 karakter yer tutucu (renk + isim: Cenk/Aslı/Deniz/Selim). *Bitti:* 1-4 insan
  karışımı elle doğrulanabilir, HUMAN_PLAYERS sabiti silindi. ✅ **Kapandı** (40b68d8, run #8 yeşil).
  Koltuk testi: 2 insan + 2 bot doğru kuruluyor. Kullanıcı lobiyi ekranda doğruladı.
- [x] **A3 — Skor sistemi:** oyun sonu misket dağıtımı (4/2/1/0), maçlar arası
  taşınan skor durumu, sıralama tablosu ekranı. *Bitti:* autotest 2 ardışık oyun
  koşup toplam skoru doğruluyor. ✅ **Kapandı** (e972d58, run #9 yeşil).
  4 bağımsız koşumun dördünde de toplam tam 14 misket (2 × 7).
- [x] **A4 — Brifing modülü genelleştirme:** Kural Karesi rol bazlı kart desteği
  (1v3 için ebe/koşucu ayrı metin), Hakem anlatım şablonu. *Bitti:* yakan top +
  (ileride) daruma aynı modülü kullanabiliyor. ✅ **Kapandı** (c08e985, run #11 yeşil).
  Sahte 1v3 turuyla kanıtlandı: iki ayrı kart (EBE/KOŞUCU) üretiliyor, `--sobe-briefingtest` CI'da.
- [x] **A5 — Duel-AI çekirdeği:** parametrik tepki gecikmesi + blöf olasılığı +
  hamle penceresi. Mendil ve ruba bandiera ailesinin ortak beyni. *Bitti:* birim
  test: iki duel-bot maçı deterministik tohumla bitiyor. ✅ (`--sobe-dueltest`, CI'da)
  12 düello bitti, aynı tohum aynı sonuç, iki taraf da kazanabiliyor.

## BLOK B — Oyun 2: Mendil Kapmaca

> **B1 revizyonu (kullanıcı tasarım kartı):** kovalamaca pozisyon savaşından
> OKUMA savaşına çevrildi. Çekirdek (`DuelEncounter`) yazıldı ve dengesi
> doğrulandı; 3B'ye bağlanması kaldı.
>
> **PROJE İLKESİ:** hiçbir kovalamaca saf 1B bırakılmaz. Tek eksende kovalayan
> ya hep yakalar ya hiç yakalayamaz — ara yoktur. Yanal blöf/yanılma katmanı
> mendil, British Bulldog ve Patintero için de şarttır.

- [ ] **B1 — Mendil gri kutu (1v1):** orta mendil, kap-kaç, dokunma = ikisi de
  yanar kuralı, blöf alanı. *Bitti:* duel-AI ile 8 bot düellosu, süre 15-45 sn bandında.
  🔶 **KISMEN — kaçış düellosu bağlandı, tek ölçüt kaldı.**
  ✅ Kaçış oranı **%42.9** (49 karşılaşma / 21 kaçış) — hedef bant %35-65 içinde.
  ✅ 10/10 düello bitiyor, kilitlenme yok, kazanan dağılımı 6–4.
  ✅ Çekirdek dengesi ayrıca saf mantıkla doğrulandı (400 düello, `--sobe-encountertest`).
  ❌ **Süre ort. 12.7 sn** (9.5–14.8), hedef 15-45.
     Teşhis: koşu mesafesi 6.5→8.0 m yapıldı, süre DEĞİŞMEDİ. Demek ki zaman
     koşuda değil, **kapıştan önceki bekleşmede** geçmeli — botlar mendile fazla
     çabuk dalıyor, çember etrafındaki blöf/okuma safhası neredeyse hiç yaşanmıyor.
     Çözüm oradadır: kapış öncesi duraksama/blöf davranışını uzatmak.

- [ ] **B2 — 1v1 ağacı formatı:** yarı finaller → 3.lük → final, seyirci bekleme
  görünümü kısa (< 20 sn). *Bitti:* 4 botla tam ağaç autotest'te koşuyor, misket
  dağıtımı doğru.

## BLOK C — Türkiye Dikey Dilimi

- [ ] **C1 — Kamp iskeleti:** ateş başı sahnesi, sıralı diyalog kutusu (metin
  dosyasından okur: `story/camp_tr.txt`), devam tuşu. Kumar masası YER TUTUCU
  (kapı görseli, "yakında"). *Bitti:* yakan top → skor → kamp → mendil akışı çalışıyor.
- [ ] **C2 — VHS kırpıntı sistemi:** 10-15 sn, atlanamaz, karakter-bazlı seçim
  (her insan oyuncu kendi karakterinin parçasını görür; solo'da sırayla). İçerik
  yer tutucu: statik kare + altyazı + VHS filtresi (shader). *Bitti:* TR bölümü
  sonunda Cenk parçası oynuyor.
- [ ] **C3 — Kaçış prototipi:** tek şerit koşu, Hakem engelleri, 2 kişilik iş
  bölümü basit hali (biri tutar, biri çevirir; solo'da bot yardımcı). *Bitti:*
  60-90 sn, ölüm = şerit başı, autotest botla tamamlıyor.
- [ ] **C4 — TR bölümü uçtan uca bağlama:** varış metni → brifing → yakan top →
  kamp → mendil ağacı → skor → VHS → kaçış → "sınır" ekranı + kayıt noktası.
  *Bitti:* baştan sona kesintisiz koşuyor, CI tam-bölüm smoke testi ekli.

### 🛑 KAPI 1 — KANEPE ONAYI (his kilidi)
Kullanıcıya rapor + talimat: en az 2 kişiyle TR bölümünü oyna. Karar bekleyenler:
`MEZARLIK_RETURN`, `on_catch` cezası, `THROW_SPEED`/`CATCH_RADIUS` hissi,
tur uzunluğu. **Onay + sabit değerleri gelmeden BLOK D'ye geçme.**
Onay sonrası: seçilen değerleri `Cfg`'ye kilitle, GDD 11b'ye "kanepe kararı" notu düş.

## BLOK D — Kalan 4 Oyun (her biri: gri kutu → format → bot → CI testi)

- [ ] **D1 — Seksek/Campana (FFA yarış):** basınç plakalı desen, yanlış kare
  ceza, ritim hızlanması. Race-çekirdeği (AI'sız, parkur). *Bitti:* 4 botlu
  (rastgele-yürüyüş sürücüsü) autotest + 3 zorluk deseni.
- [ ] **D2 — Beigoma (4'lü çanak):** ip sarma mini-girdisi = fırlatma gücü,
  çanak fiziği, son dönen kazanır. Spin-çekirdeği. *Bitti:* 8 bot maçı, süre
  20-60 sn, kazanan dağılımı tek tarafa yatmıyor (≤ 6/8).
- [ ] **D3 — Daruma-san (1v3 Ebe Eli):** dönüş telegrafı ("EBE SENİ İZLİYOR"
  kalıbının ilk kullanımı), donma kontrolü, zincir + zincir kesme kurtarması.
  Ebe-çekirdeği (hem bot-ebe hem insan-ebe). *Bitti:* iki yönlü autotest
  (bot-ebe vs botlar / sabit-girdili koşucular).
- [ ] **D4 — Tejo (2v2 sıralı atış):** güç+açı nişan, barut kapsülü patlaması,
  misilleme kuralı. Aim-çekirdeği (sıra tabanlı). *Bitti:* 2v2 bot maçı skorla
  bitiyor, patlama alan etkisi test edildi.

## BLOK E — Turnuva Bütünleşmesi

- [ ] **E1 — Rota + harita ekranı:** 4 ülke düğümü (TR→İT→JP→CO), ilerleme
  görünümü, ülke geçiş kayıtları. *Bitti:* 4 bölüm sırayla, skor taşınıyor.
- [ ] **E2 — Ebe'nin Hileleri v1:** yalnız puan liderine, ülke başına ≤ 1,
  HER ZAMAN telegraflı; ilk set 4 hile (top takibi, damga kaçışı, sahte sayış,
  kural mührü). *Bitti:* autotest hilelerin yalnız lidere geldiğini doğruluyor.
- [ ] **E3 — Serbest Maç modu:** oyun seç / 3-6 oyunluk mini turnuva, hikâyesiz,
  ana menüden. *Bitti:* menü → serbest maç → skor → menü döngüsü temiz.
- [ ] **E4 — Kumar masası v1 (kamp):** mangala VEYA aşık atma (birini seç,
  basit olanı), misket bahisli. *Bitti:* kampta oynanabilir, bakiye skorla entegre.

## BLOK F — Hikâye (ilk yarı: EA içeriği)

- [ ] **F1 — Açılış sahnesi:** 4 arkadaşın çekilişi + Hakem kural ilanı
  ("sadece biriniz çıkabilir") — motor içi, metin+sahneleme. *Bitti:* yeni
  oyun akışının başında oynuyor, atlanabilir DEĞİL ama < 90 sn.
- [ ] **F2 — Kamp diyalog yayı (TR+İT):** iğneleme→eski hesap tonu, karakter
  başına 6-8 replik, `story/` metin dosyaları. *Bitti:* iki ülkenin kampı dolu.
- [ ] **F3 — VHS içerik (Cenk+Deniz parçaları):** storyboard karesi + altyazı
  formatında (gerçek çizim sanat bloğunda). *Bitti:* iki parça sistemde.

## BLOK G — Sanat Geçişi

- [ ] **G1 — Stil testi:** TEK sahne (TR arenası) low-poly kartpostal + VHS
  arayüz + 1 karakter modeli — tam sanat kalitesi denemesi. 🛑 **KAPI 2 — stil
  onayı:** kullanıcı görselden onay vermeden diğer sahnelere sanat GİRMEZ.
- [ ] **G2 — 4 karakter + Hakem (TR maskesi: Karagöz-Hacivat).** *Bitti:* lobi
  ve oyunda modeller; siluetler 4 kişide ayırt edilebilir.
- [ ] **G3 — 4 ülke kartpostal dioraması** (TR→İT→JP→CO, dönem kilidi denetimiyle:
  sahnede ekran/telefon/modern araç YOK). *Bitti:* her arena + kamp köşesi giydirildi.
- [ ] **G4 — UI/VHS estetiği + ses yer tutucuları** (CC0/işlemsel; gerçek müzik =
  dış kalem, AÇIK KARARLAR'a yaz). *Bitti:* menü→maç→skor tek görsel dilde.

## BLOK H — EA Hazırlık

- [ ] **H1 — Ayarlar:** sert mod (şiddet), tuş yeniden atama, ekran/ses,
  Türkçe+İngilizce dil altyapısı. *Bitti:* ayarlar kalıcı kaydediliyor.
- [ ] **H2 — Kararlılık:** 30 dk autotest maratonu sızıntısız/çökmesiz;
  performans hedefi 60 fps (orta donanım profili). 
- [ ] **H3 — RPT doğrulama senaryosu** + build betiği (Windows+Linux export,
  CI'dan artifact). *Bitti:* indirilebilir build CI'dan çıkıyor.
- [ ] **H4 — Steam malzeme paketi:** ekran görüntüsü otomasyonu, 6 oyun kısa
  klipleri, mağaza metni taslağı (TR+EN). 🛑 kullanıcı incelemesine sun.
- [ ] **🚢 EA ÇIKIŞI** — Serbest Maç (6 oyun) + Hikâye TR+İT.

## BLOK I — 1.0 (EA sonrası ücretsiz güncellemeler)

- [ ] **I1 — Hikâye ikinci yarı:** JP+CO kamp yayı + Selim+Aslı VHS parçaları.
- [ ] **I2 — Reveal sekansı + mod dönüşü** (kumandalar takıma döner anı).
- [ ] **I3 — Co-op saklambaç finali:** iz sürme, "kimse geride kalmazsa" kapı
  kuralı, "Sobe" hakkı = puan lideri; solo'da bot reveal replikleri.
- [ ] **I4 — Son cila + 🚢 1.0.**

## 1.0 SONRASI (sıra dışı, ayrı planlanır)
Uzun Koşu (roguelite kural seti) • 2. dalga ülkeler (Brezilya/queimada öncelikli)
• şehir kural paketleri • gerçek netcode araştırması.

## KANEPE KARARLARI (kapandı)
- ✅ Deneme atışı: önce 20 sn onaylandı, sonra kanepede **10 sn**'ye revize edildi
  ve zorunlu bekleme kaldırıldı — ATIŞ tuşuyla erken düdük. ("geri sayım olmasın,
  oyuncular hazır olunca başlasın") → `Cfg.PRACTICE_TIME = 10.0`.
- ✅ Topla koşabilme, sekme ve bot menzili düzeltmeleri kanepede doğrulandı.
- ✅ Top ortada doğmaz, takıma verilir (kullanıcı tespiti). Yanma sonrası hak
  YANAN takıma — 2v2 kartopunu engellemek için (karar Code'a bırakıldı).
- ✅ Sayışma geri sayımı iyi bulundu.
- ✅ `THROW_SPEED = 14`, `PLAYER_SPEED = 6` — gerçek oynanış testinde onaylandı, kilitli.
- ✅ Bot hareketi yeterli bulundu ("gayet akıllı") — bot çekirdeği v1 kabul.
- ✅ Kapma mekaniği olduğu gibi kalıyor (kullanıcı "sorun yok" dedi).
- ✅ Topun söndüğü okunuyor — görsel ek iş yapılmadı.

## AÇIK KARARLAR (Code buraya yazar, kullanıcı kapatır)
- Gerçek müzik/ses kaynağı (dış kalem bütçesi)
- Diaspora doğruluk turu zamanlaması (G3 bitmeden başlamalı)
- İsim arama testi sonucu (SOBE vs alt başlık öne)
- Tempo: bot maçı ortalaması 38.7 → 60.7 sn'ye çıktı. Ölçüm maç başına 3-7 top
  sıfırlaması gösteriyor; kaldıraç `BALL_RESET_TIME` (6 sn). Kanepe kararı bekliyor.
- `MEZARLIK_RETURN` true/false — kanepe A/B'si henüz yapılmadı.
- **Mendil gerilimi (B1):** 1B koridorda yakalama matematiksel olarak zor. Seçenekler:
  (a) yakalama yalnız KENDİ ÇİZGİNE yakınken sayılsın (son 2 m savunma bölgesi),
  (b) kaçanın rakibin YANINDAN geçmesi gereksin (mendil rakip yarıda dursun),
  (c) taşıyan daha çok yavaşlasın (0.78 → 0.6).
  Hangisinin eğlenceli olduğunu ancak elle oynayarak anlarız.

# SOBE — Tasarım Dokümanı v1.1

> Önceki tüm sürümlerin yerine geçer. Yapı: **düello-önce parti oyunu → finalde co-op'a dönüşen hikâye.**
> **v1.1 revizyonu (kod incelemesi sonrası):** 1.0 kapsamı 4 ülke / 6 oyuna indirildi (§11a); online-uyumlu mimari kısıtı, bot bütçesi ve hile telegrafı eklendi; isim "kilitli"den "açık madde"ye alındı (SoBe içecek markasıyla arama çakışması kontrol edilecek).

---

## 1. Kimlik

- **İsim:** **SOBE** (küresel — kısa, telaffuzu evrensel, oyunun son sözü; *Sifu/Unpacking* gibi tek-kelime yabancı isim emsali). Alt başlık: *Son Çocuk / The Last Kid.*
- **Tek cümle:** Dört çocukluk arkadaşı "Eski Dünya"ya çekilir; kural "sadece biriniz çıkabilir"dir — dünyayı dolaşıp birbirlerine karşı sokak oyunları oynarlar, ta ki kuralın bir test, Ebe'nin ise terk ettikleri beşinci arkadaş olduğunu anlayana kadar.
- **Tür:** Parti / versus mini oyun turnuvası + anlatı; final perdesi co-op.
- **Oyuncu:** 1-4 yerel (boş koltuklar karakterli botlar) + Steam Remote Play Together.
- **Süre:** Hikâye Turnuvası ≈ 3 saat; sınırlarda kayıt; 4. ülkeden sonra işaretli "devre arası" (tek akşam veya iki oturum).
- **Platform/His:** PC (Godot 4), stilize low-poly 3D, paylaşımlı kamera, dönem: ~1975–1999.

## 2. Kilitli Kararlar

| Karar | Seçim |
|---|---|
| Kahramanlar | **Dört çocukluk arkadaşı** (baba-oğul kaldırıldı) |
| Yapı | **Versus-önce**; hikâye VHS kırpıntılarıyla sızar; reveal sonrası **oynanabilir co-op final** (B) |
| "Sobe" hakkı | **Puan lideri** söyler |
| Ebe | Terk edilen beşinci arkadaş — **Yusuf** (adı yalnız finalde açıklanır) |
| Ölümcüllük | Dört arkadaş için tehdit ölüm değil **kalmak** (kalan, zamanla maskeyi takar); infazlar dünyanın dokusunda (kural bozan Kayıplar) |
| Denge | **Ebe'nin Hileleri lideri hedefler** (lastik bant = hikâye motivasyonu) |
| Anlatım | Anılar **karakter bazlı**: her oyuncu yalnız kendi karakterinin suç parçasını görür → kanepede birleştirme sohbeti mecburi |
| Sanat disiplini | Kartpostal diorama (ülke başına tek kompakt sahne), VHS ev-videosu anıları, 3 kahraman + 5 modüler kaçış |
| Süre/solo | 3 saat hedef; solo'da 3 karakterli bot + reveal'da botlara yazılmış insan replikleri |

## 3. Hikâye

**Açılış:** Birbirini yıllardır aramayan dört eski mahalle arkadaşı aynı gece farklı evlerden çekilir; kendilerini aynı tebeşirli sahada bulurlar. İlk diyalog bile gergindir. Hakemler kuralı okur: *"Sadece biriniz çıkabilir."*

**Gövde:** 8 ülkelik kafile-turnuva. Birlikte seyahat eder, birbirine karşı oynarlar. Kamplarda buz yavaş çözülür; sınır kaçışlarında mecburen yardımlaşırlar (oyun, farkında olmadan co-op'u öğretir). Maç aralarında 10-15 saniyelik VHS kırpıntıları: bir mahalle, beş çocuk, bir sayışma, bir Atari tabelası...

**Suçun anatomisi (dört parça):** Atari salonunun açıldığı gün saklambaç oynanıyordu ve ebeyi sayışma belirledi — ama **Cenk sayışmayı hileyle Yusuf'a denk getirdi** (salona ilk giren olmak için). **Aslı gördü, sustu.** Herkes koşarken **Deniz'in attığı espriye gülerek gittiler.** Yusuf'un en yakını **Selim, arkasına bile bakmadı.** Her oyuncunun VHS hattı kendi karakterinin parçasını gösterir; gerçek, kanepede dört anlatının birleşmesiyle kurulur.

**Reveal (kapı):** Son damgayla resim tamamlanır. Ebe = Yusuf. Ve kural hiç kural değildi; **testti**: *"Beni bıraktınız — şimdi birbirinizi bırakın, görün bakalım."* Skor tablosu anlamını yitirir.

**Mod dönüşü:** Versus biter; dört kumanda aynı anda takım kumandasına döner. Son perde **co-op saklambaç**: tebeşir okları, sayış sesi, sallanan salıncak — izler birlikte sürülür. **Kapı yalnız kimse geride kalmazsa açılır.** (Squid Game'in tersyüzü: kazanmak = birlikte çıkmak.)

**Son:** Yusuf'u puan lideri bulur ve zaferini masaya bırakır: *"Sobe... Çıkabilirsin Yusuf."* Dördü kendi evlerinde uyanır. Telefonda yeni bir grup kurulur: *"pazar sahada?"* — ve beşinci bir numara eklenir.

## 4. Karakterler

| Karakter | Arketip | Nesnesi (pasif ailesi) | Suç parçası | Yay |
|---|---|---|---|---|
| **Cenk** | Sporcu/lider | Mahalle topu ("topu olan çocuk"; top oyunları: yakan top + istop) | Sayışmayı hileledi | Kazanmanın bedelini öğrenir |
| **Aslı** | Kurnaz | Misket torbası (nişan) — kumar masası kraliçesi | Gördü, sustu | Susmanın suç olduğunu kabul eder |
| **Deniz** | Şakacı | Seksek taşı (ritim) | Herkesi güldürüp götürdü | Şakanın örttüğünü açar |
| **Selim** | Sessiz | Topaç (hassasiyet) | En yakınıydı, dönüp bakmadı | Tek cümlelik özrü finalde söyler |
| **Yusuf / EBE** | — | Duvar tebeşiri | — | Bulunmayı bekleyen çocuk; sokağın kendisi |

Pasifler hafiftir (%10-15 bandı) ve karakter seçimini taktikleştirir. Botlar bu dört karakteri "okunabilir kusurlarla" oynar (Aslı-bot damgaya koşar, Cenk-bot lidere çelme takar).

## 5. Modlar

1. **Hikâye Turnuvası** (ana mod): aşağıdaki 8 ülke, 12 oyun, kamplar, kaçışlar, VHS, final. 1-4 oyuncu.
2. **Serbest Maç** (baştan açık): hikâyesiz hızlı parti — oyun seç ya da 5/8/12 oyunluk turnuva; aynı içerik, sıfır ek maliyet.
3. **Uzun Koşu** (hikâye bitince): roguelite kural seti — tek can, "yanan çıkar", rastgele Sokak Kuralı build'leri, sertleşen Ebe Hileleri.

## 6. Hikâye Turnuvası Yapısı

**Bölüm ritmi:** Varış (kartpostal sahne, kısa sohbet) → **Hakem Brifingi** → Oyun(lar) → Skor → **Kamp** → VHS kırpıntısı → **Kaçış** → sınır kaydı.

- **Skor ekonomisi:** her oyun sıralamaya göre **misket** dağıtır (4/2/1/0). Her ülkenin tek **damgası**, o ülkede en çok misket toplayana. Puan lideri = en çok damga (eşitlikte misket). Lider olmak hem hedeftir hem yük: Ebe'nin Hileleri onu izler.
- **2v2 rotasyonu:** takım oyunlarında eşleşme her ülkede değişir — turnuva bitiminde herkes herkesle takım olmuştur. (Finalin co-op'una gizli zemin.)
- **Kamp diyalog yayı:** ülke 1-3 iğneleme ve eski hesap → 4-6 "hatırlıyor musun" → 7-8 itiraflar. Kumar masası (aşık, mangala, dokuz taş) misket bahisli mini PvP.
- **Kaçış = gizli co-op okulu:** damga basılınca Hakemler saldırır; zorunlu iş bölümü (biri savuşturur, biri mekanizma çevirir). Üç kahraman sahne: İstanbul çatıları, Şōwa gar peronu, Bogota funiküleri; kalan beşi modüler kovalamaca sisteminin ülke kaplamaları.
- **Brifing standardı:** "Kurallar 15 saniyede, ustalık saatlerce." Rol bazlı 3 satırlık Kural Karesi (AMAÇ/YANMA/ŞİDDET — 1v3'te ebenin kartı farklı), Hakem'in ölü sesli anlatımı + 15 sn'lik gösterim, 20 sn ölümsüz deneme, düdük.

## 7. ÜLKELER VE OYUNLAR (Hikâye Turnuvası — 8 ülke, 12 oyun)

| # | Ülke | Oyun | Format | Fiil | Kısa büküm | Şiddet |
|---|---|---|---|---|---|---|
| 1 | 🇹🇷 Türkiye | **Yakan Top** | 2v2 | Koş/kaç/tut | Top değen yanar → mezarlıktan atmaya devam eder (yanan bile oynar); topu havada kapan yakma hakkı kazanır | 🟡 |
| 2 | 🇹🇷 Türkiye | **Mendil Kapmaca** | 1v1 ağacı (yarı finaller + final; kaybedenler 3.lük maçı) | Düello/blöf | Kapıp kaçarken dokunulursan ikisi de yanar → blöf ve vazgeçme taktiği | 🟡 |
| 3 | 🇮🇹 İtalya | **Ruba Bandiera** | FFA | Oku/fırla | Hakem sayı değil **hesap** söyler ("7×8!") — yanlış fırlayan yanar | 🟡 |
| 4 | 🇮🇹 İtalya | **Seksek (Campana)** | FFA yarış | Zıpla/zamanla | Basınç plakalı zemin; yanlış kare çöker | 🔵 |
| 5 | 🇯🇵 Japonya | **Daruma-san** | **1v3 Ebe Eli** — bir oyuncu dönen ebedir | Koş/don | Japon kuralı: yakalananlar zincirlenir, kalanlar zinciri keserek kurtarabilir | 🔵 |
| 6 | 🇯🇵 Japonya | **Beigoma (Topaç)** | 4'lü çanak — son dönen kazanır | Fırlat/it | İp sarma kalitesi = fırlatma gücü; Beyblade'in atası | 🟡 |
| 7 | 🇻🇳 Vietnam | **Bambu Dansı** | FFA hayatta kalma | Zıpla/zamanla | Ritimle kapanan çubuklar; tempo sürekli artar | 🔵 |
| 8 | 🇵🇭 Filipinler | **Patintero** | 2v2 (geçenler vs çizgi bekçileri, devre arası rol değişimi) | Koş/sız | Çizgide devriye bekçilere değmeden ızgarayı geç | 🟡 |
| 9 | 🇬🇭 Gana | **Ampe** | FFA çemberi — eleme serisi | Oku/blöf | El çırpma ritmi + ayak tahmini; hızlandıkça pencere daralır | 🔵 |
| 10 | 🇨🇴 Kolombiya | **Tejo** | 2v2 sıralı atış | Nişan/fırlat | Diskler **barut kapsüllerine** — gerçek folklor; isabet = patlama | 🟡 |
| 11 | 🇧🇷 Brezilya | **Queimada** | 2v2 | Koş/kaç/fırlat | Yakan topun Brezilya kuralı: mezarlık şeridi derinleşir — "aynı oyun, farklı kural" ters köşesi | 🟡 |
| 12 | 🇧🇷 Brezilya | **Luta de Galo** | FFA son-ayakta (4 kişi 4 mendil) | Sek/kap | Tek ayak, tek kol bağlı; mendilini kaptıran yanar | 🔴 |
| — | 🏚 Son Kapı | **Saklambaç** | **Co-op final (mod dönüşü)** | Ara/bul | Saklanan Ebe'dir; kapı kimse geride kalmazsa açılır; "Sobe"yi puan lideri söyler | — |

**Aile sohbet katmanı:** aynı oyunun ülke versiyonları karakter ağzından bağlanır (*"Biz buna yakan top derdik ama bizde mezarlık yoktu!"*) — kültür atlası, ansiklopedi kartlarıyla desteklenir (gerçek tarihçe + kaynak; ülke başına diaspora oyuncularıyla doğruluk testi).

**Mendil Kapmaca 1.0'dan çıkarıldı** → 2. dalga (kaçış düellosu tasarım kartıyla
birlikte, ileride Mahalle Kupası 1v1 modu için hazır). Gerekçe: İstop doğuştan
4 kişilik FFA (seyirci yok), icat edilmiş meta-sistem gerektirmiyor, top+kaçma+
nişan tekniğini yeniden kullanıyor; duel-AI ertelenip 1v1 ağacı siliniyor.

**Güncelleme havuzu (2. dalga ülke/oyunlar):** 🇹🇷 Mendil Kapmaca (kaçış düellosu) • 🇬🇧 British Bulldog & Conkers • 🇺🇸 Red Rover & Sandalye Kapmaca • 🇰🇷 Mugunghwa & Gonggi • 🇮🇳 Kabaddi & Gulli Danda • 🇲🇽 Piñata & Lotería • 🇷🇺 Kazaki (sade) & Gorodki • 🇪🇬 Yedi Taş • 🇨🇳 Kartal-Civciv • 🇸🇪 Kubb • Antik Katman: Aşık, Çember (+ kampta zaten: mangala, dokuz taş). Şehir kural paketleri ("İzmir/Trabzon kuralları") canlı hattın omurgası.

## 8. Ebe'nin Hileleri (lastik bant)

Rastgele değil — **hep puan liderini** hedefler; mekanik dengeleyici = hikâye motivasyonu ("çıkmaya en yakın olandan nefret eder"). Örnekler: liderin sıradaki oyununda top onu takip eder • damgası bir ülke ileri kaçar • sayışma "yanlış sayar" ve lider dezavantajlı başlar • liderin Sokak Kuralı bir tur mühürlenir. Sıklık: ülke başına en fazla 1; şiddeti farkla ölçeklenir.

## 9. Dünya ve Sanat

- **Dönem kilidi (~1975–1999):** ekransız evren; tebeşir, tüplü TV, kasetçalar; telefon/modern araç asla. Tek istisna: hikâyenin kırılma imgesi **Atari salonu** — tehditkâr çekilir. Arayüz VHS dokulu.
- **Kartpostal diorama:** ülke başına tek kompakt sahne (arena + fon + kamp köşesi); gezilebilir mahalle yok.
- **Ton çapası:** mizah fizikte, hüzün kampta, dehşet Hakemlerde — aynı sahnede ikisi zirve yapmaz.
- **Hakemler:** her ülkenin geleneksel maskesi (Karagöz-Hacivat, oni, lucha libre...); maskelerin altından sayış sızar. Şiddet varsayılanı boya/piksel dağılması; sert mod ayarı.
- **Ölümcüllük çerçevesi:** dört arkadaşa silah doğrultulmaz; kural bozan **Kayıplar'ın** infazı sahnede görülür — tehdidin kanıtı. Dört arkadaşın bahsi: kaybeden **kalır**, kalan maskeyi takar.

## 10. Teknoloji ve Üretim

- Godot 4; her oyun izole sahne + `IRound` sözleşmesi; **7 paylaşımlı AI çekirdeği** (dodge/duel/patrol/pattern/race/aim/ebe) — kural: bu çekirdeklerle oynanamayan format havuza giremez.
- Paylaşımlı tek kamera (hepsi arena); bölünmüş ekran yok. Yerel 1-4 + RPT; gerçek netcode ancak 1.0 sonrası araştırma.
- `CLAUDE.md`: sahne sözleşmesi, fizik sabitleri, 4-gamepad test senaryoları. Üretim döngüsü: tasarım kartı → gri kutu (4 kişi test) → sanat → ansiklopedi kartı.

## 11. Yol Haritası (Erken Erişim planı)

### 11a. 1.0 Kapsam Revizyonu — 4 ülke / 6 oyun
§7 tablosu **tam atlas** olarak kalır (güncelleme havuzu); 1.0 seçkisi şudur ve dört karakterin nesne-ailesiyle birebir hizalıdır — **4 ülke = 4 suç parçası:**

| Ülke | Oyun(lar) | Format | Açılan anı |
|---|---|---|---|
| 🇹🇷 Türkiye | Yakan Top + **İstop** | 2v2 + FFA | **Cenk** (sayışma hilesi) |
| 🇮🇹 İtalya | Seksek (Campana) | FFA yarış | **Deniz** (gülüşle gidiş) |
| 🇯🇵 Japonya | Beigoma + Daruma-san | FFA çanak + **1v3 Ebe Eli** | **Selim** (dönüp bakmama) |
| 🇨🇴 Kolombiya | Tejo | 2v2 | **Aslı** (görüp susma) |
| 🏚 Son Kapı | Saklambaç | Co-op final | Reveal + "Sobe" |

Dört format (2v2 / 1v1 / FFA / 1v3) ve dört nesne-ailesi (mendil, ritim, topaç, nişan) korunur; AI çekirdeği 7'den 5'e iner. Brezilya (queimada ters köşesi), Gana, Vietnam, Filipinler → 1. güncelleme dalgasının yıldızları ("aynı oyun geri döndü" anı DLC'de daha sert vurur).

| Faz | İçerik | Çıktı |
|---|---|---|
| 1 — Dikey Dilim | Türkiye uçtan uca: brifing → yakan top (2v2) → mendil ağacı → kamp → VHS → çatı kaçışı; 4 gamepad | 20 dk demo + fragman |
| 2 — EA Çıkışı | **Serbest Maç: 6 oyun** + Hikâye ülke 1-2 + Ebe Hileleri v1 (telegraflı) | Erken Erişim |
| 3 — 1.0 | Ülke 3-4 + reveal + co-op saklambaç finali + kamp yayı (ücretsiz güncellemeler) | 1.0 |
| 4 — Canlı | Uzun Koşu + 2. dalga ülkeler (Brezilya öncelikli) + şehir paketleri + netcode | İçerik hattı |

### 11b. Revizyon kararları (kod incelemesi sonrası)
- **Online-uyumlu mimari, bugünden kısıt:** otorite tek yerde (round node), oyuncular olay raporlar, simülasyon girdiden türer. Netcode şimdi yazılmaz ama mimari onu asla imkânsızlaştırmaz — RPT köprü, gerçek online Faz 4 hedefi (bu türde tavanı belirleyen özellik).
- **Bot bütçesi resmî kalem:** çekirdek başına ayar süresi = kod süresi; "okunabilir kusurlu" kişilikler Faz 2. Solo alıcı çoğunluk — botlar projenin en iyi şeyi olmak zorunda.
- **Ebe'nin Hileleri telegraflı:** hile gelmeden önce "EBE SENİ İZLİYOR" uyarısı — zar değil baskı gibi okunsun (mavi kabuk sendromu panzehiri).
- **Mezarlıktan dönüş** gri kutuda bayraklı test: tek dönüş hakkı ("vuran kurtulur") vs saf eleme — kanepe testi karar verir.
- **Diaspora doğruluk turu**, sanat kilitlenmeden ÖNCE bütçelenir.
- **İsim açık madde:** SOBE + kalıcı alt başlık ("SOBE: The Last Kid") ile Steam/Google arama testi; gerekirse alt başlık öne geçer.

## 12. Riskler ve Panzehirler

- **Ara sahne atlanır** → VHS kırpıntıları 10-15 sn, maç arasına gömülü, karakter bazlı (merak motoru: "seninkinde ne vardı?").
- **Spoiler** → pazarlama sonu saklar; fragman versus'u satar, son 15 saniyede tek tedirgin edici VHS karesi.
- **Solo'da reveal zayıflar** → botlara reveal anı için yazılmış üçer insan repliği; suç parçalarının tamamı solo'da otomatik birleşir.
- **Kültürel hata** → ülke başına yerel/diaspora test turu + ansiklopedide kaynak.
- **Kapsam** → format matrisi tek-birincil-format kuralı, kartpostal sanat, 3+5 kaçış, EA sıralaması. Bu dokümandaki her sistem bu dört bıçaktan geçmiştir.

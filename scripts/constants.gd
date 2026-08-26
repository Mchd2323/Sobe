class_name Cfg
extends RefCounted
# SOBE fizik/oyun sabitleri — CLAUDE.md tablosuyla senkron. His ayarı burada.

const PLAYER_SPEED := 6.0        # m/sn koşu hızı
const THROW_SPEED := 14.0        # atış hızı (yatay)
const THROW_UP := 3.0            # atışa eklenen dikey hız
const PICKUP_RADIUS := 1.5       # yerden top alma menzili
const CATCH_RADIUS := 1.6        # havada kapma menzili (beceri penceresi)
const BALL_BOUNCE := 0.45        # duvardan/zeminden geri gelme (0 = ölü top, köşede kalır)
const BALL_RESET_TIME := 6.0     # topa bu kadar sn dokunulmazsa ortaya döner

# SAYIŞMA: top ortada doğmaz, bir takıma VERİLİR. Geri sayım boyunca iki taraf da
# orta çizgiden uzak durur; sıfırda top sahibi oyuncunun elinde oyun başlar.
# KANEPE KARARI (revize): deneme atışı 10 sn ve ATIŞ tuşuyla erken bitirilebilir.
# Kullanıcı: "geri sayım olmasın, oyuncular hazır olunca başlasın. 20 sn yerine 10 sn."
# Yani 10 sn bir ÜST SINIR, zorunlu bekleme değil.
const PRACTICE_TIME := 10.0

const DROP_COUNTDOWN := 1.5      # geri sayım süresi (sn)
const DROP_KEEPOUT := 3.0        # sayım boyunca orta çizgiye yaklaşma yasağı (m)

# TOP HAKKI
const POSSESSION_START_TEAM := 0   # maç başında top kimde (0 = MAVİ)
# Yanma sonrası top hakkı:
#   false = YANAN takım alır (varsayılan) — 2v2'de kartopunu engeller. Yakan taraf
#           topu da tutsaydı, tek kalan rakibi anında yakar, maç saniyelerde biterdi.
#           Böylece geride kalan taraf elinde topla karşılık verebilir.
#   true  = YAKAN takım alır ("sokakta yakan devam eder").
# Kapma bunun dışında: kapan oyuncu topu elinde tutar (zor ve riskli hamlenin ödülü).
const POSSESSION_TO_SCORER := false

# Mezarlıktan atmanın bedeli: yanık atıcının topu havada kapılırsa dönüş hakkı yanar.
const MEZARLIK_CATCH_PENALTY := true
const BOT_THROW_COOLDOWN := 1.2
const BOT_CATCH_CHANCE := 0.3

# GRİ KUTUNUN 1 NUMARALI TEST SORUSU:
# Mezarlıktan rakip vuran oyuna geri dönsün mü? (tek dönüş hakkıyla)
const MEZARLIK_RETURN := true
const MEZARLIK_RETURN_LIMIT := 1   # koşu başına dönüş hakkı; 2. yanış kesindir

# Saha (metre): x uzun kenar, orta çizgi x=0.
const FIELD_X := 8.0
const FIELD_Z := 5.0
const MEZARLIK_W := 1.2

const TEAM_COLORS := [Color(0.30, 0.52, 1.0), Color(1.0, 0.36, 0.30)]
const TEAM_NAMES := ["MAVİ", "KIRMIZI"]

# GDD §4 dört arkadaş. Koltuk sırası takımı belirler: 0,2 = MAVİ | 1,3 = KIRMIZI
# Ekranda gösterilen yapı etiketi. TEK YER — elle başka yere yazma.
const BUILD_LABEL := "v0.16"

# --- MENDİL KAPMACA (B1) ---
# Karakter kişilikleri (GDD §4): koltuk sırasına göre tepki gecikmesi ve blöf.
# Cenk sporcu/lider → tez canlı, az blöf. Aslı kurnaz → sabırlı, çok blöf.
# Deniz şakacı → ortada. Selim sessiz → en sabırlı.
#            [tepki, blöf]      Cenk        Aslı        Deniz       Selim
const DUEL_PERSONA := [[0.22, 0.10], [0.42, 0.40], [0.30, 0.28], [0.48, 0.18]]
const MENDIL_HOME_X := 6.5        # kendi çizgin (mendil x=0'da)
const MENDIL_GRAB_R := 0.7        # mendili kapma menzili (tuş yok, otomatik)
# Yakalama menzilini büyütmek YANLIŞ çözümdü: 1.4'te kapan hiç kaçamadı,
# kimse sayı yapamadı, düello sonsuza gitti. Doğru mekanik şu —
# menzil dar kalır ama kapan KISA BİR DOKUNULMAZLIK alır; rakip yakalamak
# için gerçekten kovalamak zorundadır. Kapan yavaşladığı için (CARRY_SPEED)
# yakındaki kovalayan mesafeyi kapatabilir: blöf işte burada kazanç sağlar.
const MENDIL_TAG_R := 1.1         # taşıyanı yakalama menzili
const MENDIL_GRAB_GRACE := 0.15   # kapıştan sonra dokunulmazlık (sn)
# Hesap: kapan 6.5 m yolu 4.68 m/s ile 1.39 sn'de alır; kovalayan 1.32 m/s
# hız farkıyla o sürede 1.83 m kapatır. Dokunulmazlık bu bütçeden düşülür —
# 0.4 sn (1.9 m avans) bütçenin tamamını yiyordu ve kimse yakalanamıyordu.
const MENDIL_FEINT_STOP := 1.0    # blöfte mendile bu kadar yaklaşıp durur (< TAG_R)
# BEKLERKEN nerede durulur? Gerçek mendil kapmacada iki oyuncu çizginin
# DİBİNDE birbirini kollar. Botlar beklerken kendi çizgilerine dönüyordu;
# mendile 6.5 m uzakta bekleyen kimse ne kapışa yetişir ne yakalar — ölçümde
# 30 düelloda "ikisi de yandı" hiç çıkmamasının sebebi buydu.
const MENDIL_HOVER := 2.2         # beklerken mendile bu mesafede durulur
const MENDIL_TARGET_POINTS := 3   # tur bu puana ilk ulaşanın
const MENDIL_RESET_TIME := 1.2    # puandan sonra yeniden diziliş sayımı
# A5 bulgusuna cevap: eşit hızda mendili kapan HER ZAMAN kaçıyordu ve
# "ikisi de yanar" kuralı hiç işlemiyordu. Taşıyan yavaşlarsa kovalayanın
# gerçek bir kesme şansı olur — blöf de o zaman anlam kazanır.
# Taşıyan hafif yavaşlar — ama tehlike mesafeden GELMEZ (aşağıya bak).
const MENDIL_CARRY_SPEED := 0.78

# KOVALAMA PENCERESİ — B1'in çekirdek mekaniği.
# Ölçüm şunu gösterdi: 1B koridorda tekdüze daha hızlı kovalayanla sonuç baştan
# bellidir. 0.78'de kapan HİÇ yakalanmadı (50 düello), 0.68'de HİÇ kaçamadı
# (tur bitmedi). Gradyan yok, bıçak sırtı var — çünkü uzun kovalamada karar
# anı yoktur, sadece aritmetik vardır.
# Gerçek mendil kapmacada gerilim mesafeden değil KAPIŞ ANINDAKİ refleksten
# gelir. Bu yüzden yakalama yalnız kapıştan sonraki kısa pencerede mümkündür:
# rakip o anda dibindeyse yakalar, uzaktaysa kaçarsın. Blöfün işlevi de budur —
# rakibi sen yakındayken kapmaya kandırmak.
const MENDIL_CHASE_WINDOW := 1.1  # kapıştan sonra yakalamanın mümkün olduğu süre

const CHARACTERS := ["Cenk", "Aslı", "Deniz", "Selim"]

# Aynı takımın iki oyuncusu ayırt edilebilsin: ikincisi açık ton.
static func seat_color(index: int) -> Color:
	var base: Color = TEAM_COLORS[index % 2]
	return base if index < 2 else base.lightened(0.35)

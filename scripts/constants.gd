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
# KANEPE KARARI: 20 sn deneme atışı onaylandı ("20 sn iyi aslında").
const PRACTICE_TIME := 20.0

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
const BUILD_LABEL := "v0.12"

const CHARACTERS := ["Cenk", "Aslı", "Deniz", "Selim"]

# Aynı takımın iki oyuncusu ayırt edilebilsin: ikincisi açık ton.
static func seat_color(index: int) -> Color:
	var base: Color = TEAM_COLORS[index % 2]
	return base if index < 2 else base.lightened(0.35)

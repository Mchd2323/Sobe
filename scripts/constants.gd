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
const BUILD_LABEL := "v0.28"

# --- İSTOP (B1) ---
# Kural: ebe topu dikine atıp isim çağırır; çağrılan yere düşmeden yakalar ve
# "İSTOP!" der; herkes donar; top sahibi en fazla 3 adım yürüyüp donmuş birini
# vurmaya çalışır. İsabet = hedefe ceza, ıska = atana ceza. Ceza harf toplar.
const STEP_BUDGET := 3            # atıştan önce yürünebilecek adım
const ISTOP_STEP_LEN := 0.9       # bir adımın metre karşılığı
const FREEZE_GRACE := 0.15        # donma sonrası tolerans (refleks testi)
const THROW_SPEED_ISTOP := 12.0
const CALL_UI_TIME := 2.0         # çağrı ekranda bu kadar durur
const PENALTY_LETTERS := 5        # İ-S-T-O-P; 5 ceza = yandın
const ROUND_CAP := 8              # el sınırı
const ISTOP_TOSS_UP := 9.0        # topun dikine fırlatma hızı
const ISTOP_CATCH_R := 1.6        # havada yakalama menzili
const ISTOP_HIT_R := 0.9          # atışın isabet menzili
const ISTOP_LETTERS := ["İ", "S", "T", "O", "P"]

# --- MENDİL KAPMACA (B1 — kaçış düellosu) ---
# Diziliş: koşucu kendi grubunun TERS hizasında başlar; mendili kapınca rakibin
# üstünden geçerek kendi çizgisine koşar.
const MENDIL_HOME_X := 8.0
const MENDIL_CIRCLE_R := 1.5       # mendilcinin çemberi (resmi kural: 1.5-2 m)
const MENDIL_GRAB_R := 0.55
const MENDIL_FOUL_GRACE := 0.35    # çemberde kapmadan durulabilecek süre
const MENDIL_TARGET_POINTS := 3
const MENDIL_RESET_TIME := 1.2
const MENDIL_FEINT_STOP := 0.35
const MENDIL_TIMER := 10.0         # mendil alındıktan sonra karşılaşma olmazsa ortaya döner
const MENDIL_CARRY_SPEED := 0.92   # taşıyan hafif yavaşlar
const MENDIL_CHASER_SPEED := 1.08  # kovalayan daha hızlı: DÜZ koşuyla kaçış imkânsız,
                                   # düello mecburi. Çemberde oyalanmak da böylece
                                   # baskın strateji olmaktan çıkar.
# GDD bükümü "ikisi de yanar" 1v1 ağacında teşvikleri bozuyor: varsayılan KAPALI,
# klasik kural işliyor (temas = kovalayan sayı, çizgi = kaçan sayı).
const MENDIL_MUTUAL_BURN := false

# --- KARŞILAŞMA (kaçış düellosu) ---
const ENGAGE_RADIUS := 2.2         # bu mesafede düello tetiklenir
const ENGAGE_SLOWMO := 0.4         # karşılaşmada hız çarpanı (okunabilirlik)
const ENGAGE_WINDOW := 0.7         # yavaş çekim süresi
const JUKE_DIST := 1.4             # kırma: yana adım
const SLIDE_DIST := 2.2            # kayma: alçalarak ileri
const LUNGE_RECOVERY := 0.5        # ıskalayan kovalayanın toparlanması
const TELL_JUKE := 0.12            # tell süreleri: okunabilir ama bedava değil
const TELL_SLIDE := 0.18
const TELL_STUTTER := 0.10
const DUEL_REACTION := 0.17        # bot zorluk parametresi (ölçüldü: kaçış %51.5)

const DUEL_PERSONA := [[0.22, 0.10], [0.42, 0.40], [0.30, 0.28], [0.48, 0.18]]

const CHARACTERS := ["Cenk", "Aslı", "Deniz", "Selim"]

# Aynı takımın iki oyuncusu ayırt edilebilsin: ikincisi açık ton.
static func seat_color(index: int) -> Color:
	var base: Color = TEAM_COLORS[index % 2]
	return base if index < 2 else base.lightened(0.35)

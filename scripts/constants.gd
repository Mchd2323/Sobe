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
const BUILD_LABEL := "v0.17"

# --- MENDİL KAPMACA (B1 v2 — gerçek kurallara göre) ---
# Kaynak: resmi kurallar (mendilci ortada, 1.5-2 m çember, kapışmada çember
# sınırını aşmak yasak, rakibini kandırıp çembere sokarsan SAYI alırsın).
# Kullanıcı varyantı: çemberde dokunulmazlık, süre sınırı, ve koşucunun kendi
# grubunun TERS hizasında başlaması.
#
# Ters hiza kritik: kaçan, rakibin üstünden geçerek kendi grubuna koşar.
# 1B'de kovalayan hep geride kalıyordu ve hiç yakalayamıyordu; artık savunmacı
# doğal olarak yolun üstünde. Yedi ayar turunda çözülemeyen şey buydu.
const MENDIL_HOME_X := 6.5         # kendi dip çizgin
const MENDIL_CIRCLE_R := 1.5       # mendilcinin çemberi (resmi: 1.5-2 m)
const MENDIL_GRAB_R := 0.55        # mendili kapma menzili
const MENDIL_TAG_R := 1.0          # çember DIŞINDA yakalama menzili
const MENDIL_CIRCLE_MAX := 20.0    # çemberde en fazla bu kadar kalınır
# Bot bu oranı geçince yol kapalı olsa da kaçışa mecburdur. Sınırsız bekleyen
# bot süre aşımından kaybediyordu; oyuncu için de 20 sn ekranda ölü zaman.
const MENDIL_BREAK_AT := 0.55      # CIRCLE_MAX'in bu oranında kaçış zorunlu
# YANAL KAÇIŞ — B1'in çözülemeyen düğümünü açan şey.
# Tek eksende kaçan ile kovalayan arasında karar anı yoktur, sadece aritmetik
# vardır: ya hep yakalanır ya hiç yakalanmaz. Ölçümde ikisini de gördük.
# Kaçan bir ŞERİT seçip yana kırarsa, kovalayanın tahmin etmesi gerekir —
# işte gerilim oradan doğar. Savunmacı tepki gecikmesi kadar geç kalır.
const MENDIL_LANE := 1.35          # kaçış şeridinin yanal mesafesi
const MENDIL_LANE_READ := 0.30     # savunmacının şeridi okuma gecikmesi (sn)
const MENDIL_CARRY_SPEED := 0.82   # mendili taşıyan hafif yavaşlar
const MENDIL_TARGET_POINTS := 3    # tur bu puana ilk ulaşanın
const MENDIL_RESET_TIME := 1.2     # sayıdan sonra yeniden diziliş
const MENDIL_FEINT_STOP := 0.35    # blöfte çember sınırına bu kadar yaklaşılır
# Çembere girip mendili ALMADAN oyalanmak faul. Ama mendile koşarken de bir an
# içeridesin (1.5 m sınırdan 0.55 m kapma menziline ~0.16 sn). Tolerans o yüzden.
const MENDIL_FOUL_GRACE := 0.35    # çemberde kapmadan durulabilecek süre
# Karakter kişilikleri (GDD §4): [tepki gecikmesi, blöf olasılığı]
#            Cenk        Aslı        Deniz       Selim
const DUEL_PERSONA := [[0.22, 0.10], [0.42, 0.40], [0.30, 0.28], [0.48, 0.18]]

const CHARACTERS := ["Cenk", "Aslı", "Deniz", "Selim"]

# Aynı takımın iki oyuncusu ayırt edilebilsin: ikincisi açık ton.
static func seat_color(index: int) -> Color:
	var base: Color = TEAM_COLORS[index % 2]
	return base if index < 2 else base.lightened(0.35)

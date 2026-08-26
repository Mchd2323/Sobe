class_name Cfg
extends RefCounted
# SOBE fizik/oyun sabitleri — CLAUDE.md tablosuyla senkron. His ayarı burada.

const PLAYER_SPEED := 6.0        # m/sn koşu hızı
const THROW_SPEED := 14.0        # atış hızı (yatay)
const THROW_UP := 3.0            # atışa eklenen dikey hız
const PICKUP_RADIUS := 1.5       # yerden top alma menzili
const CATCH_RADIUS := 1.6        # havada kapma menzili (beceri penceresi)
const BALL_RESET_TIME := 6.0     # topa bu kadar sn dokunulmazsa ortaya döner
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

class_name MendilRound
extends RoundBase
# MENDİL KAPMACA 1v1 (B1 v2) — gerçek kurallara göre yeniden yazıldı.
#
# DİZİLİŞ (kritik): koşucu kendi grubunun TERS hizasında başlar. Yani mendili
# kapınca rakibin üstünden geçerek kendi dip çizgisine koşmak zorundadır.
# İlk sürümde ikisi de kendi tarafında başlıyordu; kovalayan hep geride kalıyor,
# yedi ayar turunda tek bir yakalama bile olmuyordu. Ters hiza bunu çözer.
#
#   [KIRMIZI dip]        (çember)        [MAVİ dip]
#      -6.5      MAVİ koşucu ● ○ KIRMIZI koşucu     +6.5
#                        mendil
#
# KURALLAR
#   • Mendili kapan ÇEMBER İÇİNDE dokunulmazdır (kullanıcı varyantı)
#   • Çemberde en fazla MENDIL_CIRCLE_MAX kalınır, sonra mendil rakibe geçer
#   • Çember DIŞINDA dokunulursan İKİSİ DE yanar (GDD §7 bükümü), puan yok
#   • Mendil kimsede değilken rakip çembere girerse SAYIYI SEN alırsın
#     (resmi kural: "rakibini kandırıp çembere sokarsan grubuna puan")

var players: Array = []
var duelists: Array = []
var carrier = null

var _game = null
var _mendil: Node3D = null
var _cember: Node3D = null
var _points := [0, 0]
var _resetting := false
var _reset_timer := 0.0
var _circle_time := 0.0
var _in_circle_t := [0.0, 0.0]   # kapmadan çemberde geçirilen süre
var escape_lane := 0.0           # kaçanın seçtiği şerit (+/- MENDIL_LANE)
var _lane_seen := 0.0            # savunmacının okuduğu şerit
var _lane_timer := 0.0
var _intents := {}
var _winner_idx := -1

var both_burned := 0      # ölçüm: çember dışında yakalama
var bluff_points := 0     # ölçüm: rakibi çembere sokarak alınan sayı

# --- sözleşme ---

func needs_ball() -> bool:
	return false

func get_hakem_line() -> String:
	return "Mendil çemberde. Kapan içeride dokunulmaz ama sonsuza kadar duramaz."

func get_rule_card(_role: String = "") -> Dictionary:
	return {
		"amac": "AMAÇ: Mendili KAP, rakibin üstünden geçip KENDİ çizgine dön. Önce %d sayı." % Cfg.MENDIL_TARGET_POINTS,
		"yanma": "YANMA: Çember dışında dokunulursan İKİSİ DE yanar. Çember içinde dokunulmazsın (en fazla %d sn)." % int(Cfg.MENDIL_CIRCLE_MAX),
		"siddet": "ŞİDDET: 🟡 Serbest — mendil yokken rakibi çembere sokarsan SAYI senin. Blöf burada kazanır.",
	}

func make_brain(player, game):
	var b := MendilBrain.new()
	b.player = player
	b.game = game
	b.round_ref = self
	var persona: Array = Cfg.DUEL_PERSONA[player.index % Cfg.DUEL_PERSONA.size()]
	b.core.reaction_delay = persona[0]
	b.core.bluff_chance = persona[1]
	b.core.seed_with(randi())
	return b

func setup(p_players: Array, root: Node3D) -> void:
	players = p_players
	_game = root
	duelists = [players[0], players[1]]
	_points = [0, 0]
	_winner_idx = -1
	both_burned = 0
	bluff_points = 0
	carrier = null
	_intents.clear()

	for pl in players:
		pl.reset_state()
		pl.round_ref = self
	for i in range(2, players.size()):
		players[i].global_position = Vector3(0, 1, Cfg.FIELD_Z - 0.8)

	if _cember == null:
		_cember = MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = Cfg.MENDIL_CIRCLE_R
		cm.bottom_radius = Cfg.MENDIL_CIRCLE_R
		cm.height = 0.04
		_cember.mesh = cm
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(0.95, 0.95, 0.95, 0.45)
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_cember.material_override = cmat
		root.add_child(_cember)
	_cember.global_position = Vector3(0, 0.03, 0)

	if _mendil == null:
		_mendil = MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.4, 0.06, 0.4)
		_mendil.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.97, 0.94, 0.72)
		_mendil.material_override = mat
		root.add_child(_mendil)
	_place_all()

func start() -> void:
	_begin_reset()

# TERS HİZA: koşucu kendi dip çizgisinin KARŞI tarafında başlar.
func home_x(player) -> float:
	return Cfg.MENDIL_HOME_X if duelists.find(player) == 0 else -Cfg.MENDIL_HOME_X

func start_x(player) -> float:
	return -signf(home_x(player)) * (Cfg.MENDIL_CIRCLE_R + 0.4)

func get_bounds(player) -> Vector4:
	var i: int = duelists.find(player)
	if i < 0:
		return Vector4(-0.6, 0.6, Cfg.FIELD_Z - 1.0, Cfg.FIELD_Z - 0.6)
	if _resetting:
		var sx: float = start_x(player)
		return Vector4(sx, sx, -0.9, 0.9)
	return Vector4(-Cfg.MENDIL_HOME_X, Cfg.MENDIL_HOME_X, -1.6, 1.6)

func get_countdown() -> float:
	return _reset_timer if _resetting else -1.0

func get_ranking() -> Array:
	var arr := players.duplicate()
	var w = duelists[_winner_idx] if _winner_idx >= 0 else null
	arr.sort_custom(func(a, b):
		if (a == w) != (b == w):
			return a == w
		var ai: int = duelists.find(a)
		var bi: int = duelists.find(b)
		var ap: int = _points[ai] if ai >= 0 else -1
		var bp: int = _points[bi] if bi >= 0 else -1
		if ap != bp:
			return ap > bp
		return a.index < b.index)
	return arr

# --- MendilBrain'in sorduklari ---

func mendil_x() -> float:
	return 0.0

func circle_r() -> float:
	return Cfg.MENDIL_CIRCLE_R

func opponent_of(player):
	var i: int = duelists.find(player)
	return null if i < 0 else duelists[1 - i]

# Kapan çemberde ne kadar kaldı (beyin buna göre kaçış anına karar verir).
func circle_time() -> float:
	return _circle_time

# Savunmacı şeridi anında göremez; MENDIL_LANE_READ kadar geç okur.
func read_lane() -> float:
	return _lane_seen

func in_circle(player) -> bool:
	return absf(player.global_position.x) <= Cfg.MENDIL_CIRCLE_R

func is_committed(player) -> bool:
	return _intents.get(player, DuelBrain.Intent.WAIT) == DuelBrain.Intent.COMMIT

func report_intent(player, intent: int) -> void:
	_intents[player] = intent

# --- tur döngüsü ---

func _place_all() -> void:
	for d in duelists:
		d.global_position = Vector3(start_x(d), 1, 0)
		d.speed_mul = 1.0
	if _mendil != null:
		_mendil.global_position = Vector3(0, 0.6, 0)

func _begin_reset() -> void:
	carrier = null
	_circle_time = 0.0
	_in_circle_t = [0.0, 0.0]
	escape_lane = 0.0
	_lane_seen = 0.0
	_lane_timer = 0.0
	_resetting = true
	_reset_timer = Cfg.MENDIL_RESET_TIME
	_place_all()

func _score(idx: int, sebep: String) -> void:
	_points[idx] += 1
	duelists[idx].burns_dealt += 1
	if sebep == "blof":
		bluff_points += 1
	if _points[idx] >= Cfg.MENDIL_TARGET_POINTS:
		_winner_idx = idx
		round_finished.emit(duelists[idx].team)
		return
	_begin_reset()

func _process(delta: float) -> void:
	if _game == null or not _game.round_active:
		return
	if _resetting:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			_resetting = false
			_reset_timer = 0.0
		return

	if carrier != null and _mendil != null:
		_mendil.global_position = carrier.global_position + Vector3.UP * 1.1

	if practice:
		_try_grab()
		return

	if carrier != null:
		_lane_timer += delta
		if _lane_timer >= Cfg.MENDIL_LANE_READ:
			_lane_seen = escape_lane
	_check_bluff_foul(delta)
	_try_grab()
	_check_circle_timer(delta)
	_check_tag()
	_check_score()

# Resmi kural: mendil kimsede değilken rakip çembere girerse sayı diğerinin.
func _check_bluff_foul(delta: float) -> void:
	if carrier != null:
		_in_circle_t = [0.0, 0.0]
		return
	for i in range(2):
		var d = duelists[i]
		if in_circle(d) and absf(d.global_position.x - mendil_x()) > Cfg.MENDIL_GRAB_R:
			_in_circle_t[i] += delta
			if _in_circle_t[i] > Cfg.MENDIL_FOUL_GRACE:
				# Çemberde kapmadan oyalandı: sayı rakibin.
				_score(1 - i, "blof")
				return
		else:
			_in_circle_t[i] = 0.0

func _try_grab() -> void:
	if carrier != null:
		return
	for d in duelists:
		if absf(d.global_position.x - mendil_x()) <= Cfg.MENDIL_GRAB_R:
			carrier = d
			carrier.speed_mul = Cfg.MENDIL_CARRY_SPEED
			_circle_time = 0.0
			# Kaçış şeridi kapış anında gizlice seçilir; savunmacı sonra okur.
			escape_lane = Cfg.MENDIL_LANE * (1.0 if randf() < 0.5 else -1.0)
			_lane_seen = 0.0
			_lane_timer = 0.0
			return

# Çemberde sonsuza kadar durulmaz: süre dolarsa mendil rakibe geçer.
func _check_circle_timer(delta: float) -> void:
	if carrier == null:
		return
	if in_circle(carrier):
		_circle_time += delta
		if _circle_time > Cfg.MENDIL_CIRCLE_MAX:
			_score(1 - duelists.find(carrier), "sure")
	else:
		_circle_time = 0.0

# Çember DIŞINDA dokunulursa ikisi de yanar (GDD bükümü), puan yok.
func _check_tag() -> void:
	if carrier == null or in_circle(carrier):
		return
	var opp = opponent_of(carrier)
	if opp != null and carrier.global_position.distance_to(opp.global_position) <= Cfg.MENDIL_TAG_R:
		both_burned += 1
		_begin_reset()

func _check_score() -> void:
	if carrier == null:
		return
	if absf(carrier.global_position.x - home_x(carrier)) <= 0.4:
		_score(duelists.find(carrier), "kacis")

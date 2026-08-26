class_name MendilRound
extends RoundBase
# MENDİL KAPMACA 1v1 (B1) — GDD §7 satır 2.
#   AMAÇ:  Mendili kap, kendi çizgine dön.
#   YANMA: Kapıp kaçarken dokunulursan İKİSİ DE yanar — puan kimseye yazılmaz.
#   ŞİDDET: 🟡 Serbest.
#
# Tur, MENDIL_TARGET_POINTS'e ilk ulaşanın. Böylece tek bir kapış turu bitirmez;
# blöf ve vazgeçme birden fazla denemede anlam kazanır.

var players: Array = []
var duelists: Array = []       # [0] ve [1]: düello edenler
var carrier = null

var _game = null
var _mendil: Node3D = null
var _points := [0, 0]          # duelists sırasına göre
var _resetting := false
var _reset_timer := 0.0
var _intents := {}             # player -> DuelBrain.Intent (blöf/dalış okuması için)
var _winner_idx := -1
var both_burned := 0     # ölçüm: kaç kez 'ikisi de yandı' oldu
var _grace := 0.0        # kapıştan hemen sonraki dokunulmazlık
var _since_grab := -1.0  # kapıştan bu yana geçen süre (kovalama penceresi)

# --- sözleşme ---

func get_hakem_line() -> String:
	return "Mendil ortada. Kapan çizgisine dönerse sayar. Dönerken dokunulursa ikisi de yanar."

func get_rule_card(_role: String = "") -> Dictionary:
	return {
		"amac": "AMAÇ: Mendili KAP, kendi çizgine DÖN. Önce %d sayı alan kazanır." % Cfg.MENDIL_TARGET_POINTS,
		"yanma": "YANMA: Kaçarken dokunulursan İKİSİ DE yanar — puan kimseye yazılmaz.",
		"siddet": "ŞİDDET: 🟡 Serbest — mendil sende yavaşlarsın, işte bütün mesele bu.",
	}

func needs_ball() -> bool:
	return false

func make_brain(player, game):
	var b := MendilBrain.new()
	b.player = player
	b.game = game
	b.round_ref = self
	# Kişilik koltuk sırasından: simetrik oyuncular simetrik oynar, düello olmaz.
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
	carrier = null
	_intents.clear()

	for pl in players:
		pl.reset_state()
		pl.round_ref = self
	_place_duelists()

	# İzleyiciler kenarda beklesin (B2'de ağaç sırası gelince oynayacaklar).
	for i in range(2, players.size()):
		players[i].global_position = Vector3(0, 1, Cfg.FIELD_Z - 0.8)

	if _mendil == null:
		_mendil = MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.5, 0.08, 0.5)
		_mendil.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.92, 0.75)
		_mendil.material_override = mat
		root.add_child(_mendil)
	_mendil.global_position = Vector3(0, 0.1, 0)

func start() -> void:
	_begin_reset()

func get_bounds(player) -> Vector4:
	var i: int = duelists.find(player)
	if i < 0:
		# İzleyici: kenara sabitlenir
		return Vector4(-0.6, 0.6, Cfg.FIELD_Z - 1.0, Cfg.FIELD_Z - 0.6)
	var koridor := 1.2
	if _resetting:
		# Yeniden diziliş: herkes kendi çizgisinde bekler
		var h: float = home_x(player)
		return Vector4(minf(h, h), maxf(h, h), -koridor, koridor)
	if i == 0:
		return Vector4(-0.2, Cfg.MENDIL_HOME_X, -koridor, koridor)
	return Vector4(-Cfg.MENDIL_HOME_X, 0.2, -koridor, koridor)

func get_countdown() -> float:
	return _reset_timer if _resetting else -1.0

func get_ranking() -> Array:
	var arr := players.duplicate()
	var w = duelists[_winner_idx] if _winner_idx >= 0 else null
	arr.sort_custom(func(a, b):
		var ai: int = duelists.find(a)
		var bi: int = duelists.find(b)
		var ap: int = _points[ai] if ai >= 0 else -1
		var bp: int = _points[bi] if bi >= 0 else -1
		if a == w and b != w:
			return true
		if b == w and a != w:
			return false
		if ap != bp:
			return ap > bp
		return a.index < b.index)
	return arr

# --- MendilBrain'in sorduklari ---

func mendil_x() -> float:
	return 0.0

func home_x(player) -> float:
	return Cfg.MENDIL_HOME_X if duelists.find(player) == 0 else -Cfg.MENDIL_HOME_X

func opponent_of(player):
	var i: int = duelists.find(player)
	if i < 0:
		return null
	return duelists[1 - i]

func is_committed(player) -> bool:
	return _intents.get(player, DuelBrain.Intent.WAIT) == DuelBrain.Intent.COMMIT

func report_intent(player, intent: int) -> void:
	_intents[player] = intent

# --- tur döngüsü ---

func _place_duelists() -> void:
	duelists[0].global_position = Vector3(Cfg.MENDIL_HOME_X, 1, 0)
	duelists[1].global_position = Vector3(-Cfg.MENDIL_HOME_X, 1, 0)
	for d in duelists:
		d.speed_mul = 1.0

func _begin_reset() -> void:
	carrier = null
	_resetting = true
	_grace = 0.0
	_since_grab = -1.0
	_reset_timer = Cfg.MENDIL_RESET_TIME
	_place_duelists()
	if _mendil != null:
		_mendil.global_position = Vector3(0, 0.1, 0)

func _process(delta: float) -> void:
	if _game == null or not _game.round_active:
		return
	if _resetting:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			_resetting = false
			_reset_timer = 0.0
		return
	if practice:
		# Deneme atışı: kapılır, taşınır ama puan yazılmaz, kimse yanmaz.
		_carry_follow()
		_try_grab()
		return

	_grace = maxf(0.0, _grace - delta)
	if _since_grab >= 0.0:
		_since_grab += delta
	_carry_follow()
	_try_grab()
	_check_tag()
	_check_score()

func _carry_follow() -> void:
	if carrier != null and _mendil != null:
		_mendil.global_position = carrier.global_position + Vector3.UP * 1.1

func _try_grab() -> void:
	if carrier != null:
		return
	var best = null
	var best_d := INF
	for d in duelists:
		var dist: float = absf(d.global_position.x - mendil_x())
		if dist <= Cfg.MENDIL_GRAB_R and dist < best_d:
			best_d = dist
			best = d
	if best != null:
		carrier = best
		carrier.speed_mul = Cfg.MENDIL_CARRY_SPEED   # taşıyan yavaşlar
		_grace = Cfg.MENDIL_GRAB_GRACE
		_since_grab = 0.0

func _check_tag() -> void:
	if carrier == null or _grace > 0.0:
		return
	# Yakalama yalnız kapıştan sonraki kısa pencerede mümkün: mesele mesafe
	# değil, rakibin kapış anında dibinde olup olmadığı.
	if _since_grab < 0.0 or _since_grab > Cfg.MENDIL_CHASE_WINDOW:
		return
	var opp = opponent_of(carrier)
	if opp == null:
		return
	if carrier.global_position.distance_to(opp.global_position) <= Cfg.MENDIL_TAG_R:
		# İkisi de yandı: puan kimseye yazılmaz, yeniden dizil.
		both_burned += 1
		_begin_reset()

func _check_score() -> void:
	if carrier == null:
		return
	var i: int = duelists.find(carrier)
	if absf(carrier.global_position.x - home_x(carrier)) <= 0.35:
		_points[i] += 1
		carrier.burns_dealt += 1
		if _points[i] >= Cfg.MENDIL_TARGET_POINTS:
			_winner_idx = i
			round_finished.emit(carrier.team)
			return
		_begin_reset()

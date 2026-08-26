class_name YakanTopRound
extends RoundBase
# YAKAN TOP 2v2 — Kural Karesi (3 satır):
#   AMAÇ:  Rakip takımın ikisini de yak.
#   YANMA: Havadaki top değerse. Seken top yakmaz — yananlar mezarlıktan oynar,
#          vuran geri döner (1 hak).
#   ŞİDDET: 🟡 Serbest — topu havada kaparsan atan yanar.

var players: Array = []

var _dropping := false
var _drop_timer := 0.0
var _ball = null
var _game = null
var _last_thrower_team := -1

func get_rule_card() -> Dictionary:
	var yanma := "YANMA: Havadaki top sana değerse. Seken top yakmaz — yananlar mezarlıktan oynar"
	if Cfg.MEZARLIK_RETURN:
		yanma += "; vuran geri döner (1 hak)."
	else:
		yanma += "."
	return {
		"amac": "AMAÇ: Rakip takımın ikisini de YAK.",
		"yanma": yanma,
		"siddet": "ŞİDDET: 🟡 Serbest — topu havada KAPARSAN atan yanar.",
	}

func setup(p_players: Array, root: Node3D) -> void:
	players = p_players
	_game = root
	var spots := {
		0: [Vector3(-4, 1, -1.6), Vector3(-4, 1, 1.6)],
		1: [Vector3(4, 1, -1.6), Vector3(4, 1, 1.6)],
	}
	var counts := [0, 0]
	for pl in players:
		pl.reset_state()
		pl.round_ref = self
		pl.global_position = spots[pl.team][counts[pl.team]]
		counts[pl.team] += 1

func start() -> void:
	# Açılış topu ortada doğmaz — bir takıma verilir.
	if _game != null and _game.balls.size() > 0:
		award_ball(_game.balls[0], Cfg.POSSESSION_START_TEAM)

# --- TOP HAKKI + SAYIŞMA ---
# Top ortada doğmaz; her yeniden başlatmada bir takıma VERİLİR ve o takımın
# oyuncusunun elinde sayışma başlar. Böylece "kim önce kaparsa" piyangosu biter.

func award_ball(ball, team: int) -> void:
	_ball = ball
	var holder = _nearest_alive(team, ball.global_position)
	if holder == null:
		# O takımda ayakta kimse yoksa tur zaten bitiyor; yine de topu ortada bırakma.
		holder = _nearest_alive(1 - team, ball.global_position)
	if holder != null:
		ball.pick_up(holder)
		holder.held_ball = ball
	ball.live = false
	_dropping = true
	_drop_timer = Cfg.DROP_COUNTDOWN

func _nearest_alive(team: int, pos: Vector3):
	var best = null
	var best_d := INF
	for pl in players:
		if pl.team == team and not pl.is_burned:
			var d: float = pl.global_position.distance_to(pos)
			if d < best_d:
				best_d = d
				best = pl
	return best

# Top uzun süre sahipsiz kaldı (ıskalanan atış): hakkı SON ATANIN RAKİBİNE ver,
# böylece ıskalayan taraf topu geri kazanmaz ve oyalanma ödüllenmez.
func on_ball_reset(ball) -> void:
	var team: int = Cfg.POSSESSION_START_TEAM
	if _last_thrower_team >= 0:
		team = 1 - _last_thrower_team
	award_ball(ball, team)

func get_countdown() -> float:
	return _drop_timer if _dropping else -1.0

func _process(delta: float) -> void:
	if not _dropping:
		return
	_drop_timer -= delta
	if _drop_timer <= 0.0:
		_dropping = false
		_drop_timer = 0.0
		if _ball != null:
			# Elde tutuluyorsa serbest bırakma; sadece oynanabilir yap.
			_ball.live = true
			if _ball.held_by == null:
				_ball.go_live()

func get_bounds(player) -> Vector4:
	var z0 := -Cfg.FIELD_Z + 0.4
	var z1 := Cfg.FIELD_Z - 0.4
	if player.is_burned:
		if player.team == 0:
			return Vector4(Cfg.FIELD_X + 0.2, Cfg.FIELD_X + Cfg.MEZARLIK_W, z0, z1)
		else:
			return Vector4(-Cfg.FIELD_X - Cfg.MEZARLIK_W, -Cfg.FIELD_X - 0.2, z0, z1)
	else:
		# Sayışma sürerken orta çizgiye yaklaşmak yasak (çizgide kamp = bedava top).
		var inner: float = Cfg.DROP_KEEPOUT if _dropping else 0.4
		if player.team == 0:
			return Vector4(-Cfg.FIELD_X + 0.4, -inner, z0, z1)
		else:
			return Vector4(inner, Cfg.FIELD_X - 0.4, z0, z1)

# --- Sözleşme kancaları (RoundBase) ---

func on_player_hit(player, ball) -> void:
	var thrower = ball.thrower  # disarm() null'lamadan önce yakala
	if thrower != null:
		_last_thrower_team = thrower.team
	ball.disarm()
	if practice:
		# Deneme atışı: isabet sayılır ama kimse yanmaz; top yanan tarafa geçsin
		# ki pratik akmaya devam etsin.
		award_ball(ball, player.team)
		return
	player.burn()
	# Mezarlıktan dönüş: yanık atıcı, rakip vurduysa geri gelir (tek hak).
	if Cfg.MEZARLIK_RETURN and thrower != null and thrower.is_burned \
			and thrower.returns_used < Cfg.MEZARLIK_RETURN_LIMIT:
		thrower.revive()
	if not _round_over():
		# Top ortada kalmaz: hakkı bir takıma verilir (bkz. Cfg.POSSESSION_TO_SCORER).
		var next_team: int = player.team
		if Cfg.POSSESSION_TO_SCORER and thrower != null:
			next_team = thrower.team
		award_ball(ball, next_team)
	_check_win()

func on_catch(catcher, ball) -> void:
	# Havada kapan yakma hakkı kazanır: atan yanar, top kapanın elinde.
	var thrower = ball.thrower
	if practice:
		award_ball(ball, catcher.team)
		return
	ball.pick_up(catcher)
	catcher.held_ball = ball
	if thrower != null:
		if not thrower.is_burned:
			thrower.burn()
		elif Cfg.MEZARLIK_CATCH_PENALTY:
			# Mezarlıktan atmanın bedeli: topun kapılırsa dönüş hakkın yanar.
			thrower.returns_used = Cfg.MEZARLIK_RETURN_LIMIT
	_last_thrower_team = catcher.team
	if not _round_over():
		# BİLEREK istisna: kapan oyuncu topu elinde tutar. Kapmak zor ve risklidir,
		# ödülü hem yakma hem top hakkıdır. (POSSESSION_TO_SCORER bunu etkilemez.)
		award_ball(ball, catcher.team)
	_check_win()

func _round_over() -> bool:
	for t in [0, 1]:
		var alive := 0
		for pl in players:
			if pl.team == t and not pl.is_burned:
				alive += 1
		if alive == 0:
			return true
	return false

func _check_win() -> void:
	for t in [0, 1]:
		var alive := 0
		for pl in players:
			if pl.team == t and not pl.is_burned:
				alive += 1
		if alive == 0:
			round_finished.emit(1 - t)
			return

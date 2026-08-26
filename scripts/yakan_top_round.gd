class_name YakanTopRound
extends RoundBase
# YAKAN TOP 2v2 — Kural Karesi (3 satır):
#   AMAÇ:  Rakip takımın ikisini de yak.
#   YANMA: Havadaki top değerse. Seken top yakmaz — yananlar mezarlıktan oynar,
#          vuran geri döner (1 hak).
#   ŞİDDET: 🟡 Serbest — topu havada kaparsan atan yanar.

var players: Array = []

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

func setup(p_players: Array, _root: Node3D) -> void:
	players = p_players
	var spots := {
		0: [Vector3(-4, 1, -1.6), Vector3(-4, 1, 1.6)],
		1: [Vector3(4, 1, -1.6), Vector3(4, 1, 1.6)],
	}
	var counts := [0, 0]
	for pl in players:
		pl.round_ref = self
		pl.global_position = spots[pl.team][counts[pl.team]]
		counts[pl.team] += 1

func get_bounds(player) -> Vector4:
	var z0 := -Cfg.FIELD_Z + 0.4
	var z1 := Cfg.FIELD_Z - 0.4
	if player.is_burned:
		if player.team == 0:
			return Vector4(Cfg.FIELD_X + 0.2, Cfg.FIELD_X + Cfg.MEZARLIK_W, z0, z1)
		else:
			return Vector4(-Cfg.FIELD_X - Cfg.MEZARLIK_W, -Cfg.FIELD_X - 0.2, z0, z1)
	else:
		if player.team == 0:
			return Vector4(-Cfg.FIELD_X + 0.4, -0.4, z0, z1)
		else:
			return Vector4(0.4, Cfg.FIELD_X - 0.4, z0, z1)

# --- Sözleşme kancaları (RoundBase) ---

func on_player_hit(player, ball) -> void:
	var thrower = ball.thrower  # disarm() null'lamadan önce yakala
	ball.disarm()
	player.burn()
	# Mezarlıktan dönüş: yanık atıcı, rakip vurduysa geri gelir (tek hak).
	if Cfg.MEZARLIK_RETURN and thrower != null and thrower.is_burned \
			and thrower.returns_used < Cfg.MEZARLIK_RETURN_LIMIT:
		thrower.revive()
	_check_win()

func on_catch(catcher, ball) -> void:
	# Havada kapan yakma hakkı kazanır: atan yanar, top kapanın elinde.
	var thrower = ball.thrower
	ball.pick_up(catcher)
	catcher.held_ball = ball
	if thrower != null and not thrower.is_burned:
		thrower.burn()
	_check_win()

func _check_win() -> void:
	for t in [0, 1]:
		var alive := 0
		for pl in players:
			if pl.team == t and not pl.is_burned:
				alive += 1
		if alive == 0:
			round_finished.emit(1 - t)
			return

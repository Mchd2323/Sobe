class_name BotBrain
extends RefCounted
# DODGE-AI ÇEKİRDEĞİ v0.1 — yakan top ailesinin (yakan top / queimada / völkerball)
# ortak beyni. Öncelik sırası: 1) gelen yanık toptan kaç  2) top yoksa topa git
# 3) top elindeyse rakibe at (öndeleme + isabetsizlik payı)  4) fırsat kapması.

var player = null       # YTPlayer
var game = null         # main.gd
var move := Vector2.ZERO

var _action_flag := false
var _throw_timer := 0.0
var _catch_roll_timer := 0.0

func think(delta: float) -> void:
	move = Vector2.ZERO
	_throw_timer = maxf(0.0, _throw_timer - delta)
	_catch_roll_timer = maxf(0.0, _catch_roll_timer - delta)

	var threat: YTBall = _incoming_ball()

	# 1) KAÇ: gelen topun yoluna dik hareket et
	if threat != null and player.held_ball == null:
		var v: Vector3 = threat.linear_velocity
		var perp := Vector3(-v.z, 0, v.x).normalized()
		# Hangi dik yön sahada kalıyorsa oraya
		var candidate: Vector3 = player.global_position + perp * 2.0
		if absf(candidate.z) > Cfg.FIELD_Z - 0.5:
			perp = -perp
		move = Vector2(perp.x, perp.z)
		# Fırsat kapması: top yakın ve şans tutarsa kapmayı dene
		if _catch_roll_timer <= 0.0:
			_catch_roll_timer = 0.4
			var d: float = player.global_position.distance_to(threat.global_position)
			if d < 2.2 and randf() < Cfg.BOT_CATCH_CHANCE:
				_action_flag = true
		return

	# 2) TOPA GİT
	if player.held_ball == null:
		var target_ball: YTBall = _reachable_free_ball()
		if target_ball != null:
			var to_b: Vector3 = target_ball.global_position - player.global_position
			move = Vector2(to_b.x, to_b.z).normalized()
			if to_b.length() <= Cfg.PICKUP_RADIUS * 0.9:
				_action_flag = true
		else:
			# Bekleme pozisyonu: kendi bölgende hafif salın
			move = Vector2(0, sin(Time.get_ticks_msec() / 600.0) * 0.4)
		return

	# 3) AT: öndelemeli nişan, ufak isabetsizlik
	if _throw_timer <= 0.0:
		var enemy = game.nearest_enemy(player)
		if enemy != null:
			var to_e: Vector3 = enemy.global_position - player.global_position
			var lead: Vector3 = enemy.velocity * (to_e.length() / Cfg.THROW_SPEED) * 0.5
			var aim: Vector3 = (to_e + lead).normalized()
			aim = aim.rotated(Vector3.UP, randf_range(-0.12, 0.12))
			player.facing = aim
			_action_flag = true
			_throw_timer = Cfg.BOT_THROW_COOLDOWN
	else:
		# Atış arası: rakiple z ekseninde hizalan
		var enemy2 = game.nearest_enemy(player)
		if enemy2 != null:
			var dz: float = enemy2.global_position.z - player.global_position.z
			move = Vector2(0, clampf(dz, -1, 1))

func consume_action() -> bool:
	var a := _action_flag
	_action_flag = false
	return a

func _incoming_ball() -> YTBall:
	for ball in game.balls:
		if ball.armed and ball.thrower != null and ball.thrower.team != player.team:
			var to_me: Vector3 = player.global_position - ball.global_position
			if to_me.length() < 7.0 and ball.linear_velocity.dot(to_me) > 0.0:
				return ball
	return null

func _reachable_free_ball() -> YTBall:
	var best: YTBall = null
	var best_d := INF
	var b: Vector4 = player.round_ref.get_bounds(player)
	for ball in game.balls:
		if ball.held_by == null and not ball.armed and ball.live:
			var p: Vector3 = ball.global_position
			if p.x >= b.x - Cfg.PICKUP_RADIUS and p.x <= b.y + Cfg.PICKUP_RADIUS:
				var d: float = player.global_position.distance_to(p)
				if d < best_d:
					best_d = d
					best = ball
	return best

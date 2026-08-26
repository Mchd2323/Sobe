class_name YTPlayer
extends CharacterBody3D
# Oyuncu gövdesi. İnsan girişi (prefix: p1..p4) ya da BotBrain aynı arayüzü besler.

var prefix := "p1"
var is_bot := false
var brain = null              # BotBrain
var team := 0
var index := 0
var is_burned := false
var returns_used := 0         # mezarlıktan dönüş hakkı sayacı
var held_ball: YTBall = null
var facing := Vector3(1, 0, 0)
var game = null               # main.gd
var round_ref = null          # RoundBase

var _mesh: MeshInstance3D
var _mat := StandardMaterial3D.new()

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	add_child(shape)

	_mesh = MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = 0.4
	m.height = 1.8
	_mesh.mesh = m
	_mesh.position.y = 0.9
	_mat.albedo_color = Cfg.TEAM_COLORS[team]
	_mesh.material_override = _mat
	add_child(_mesh)

func set_team(t: int) -> void:
	team = t
	_mat.albedo_color = Cfg.TEAM_COLORS[t]

func _physics_process(delta: float) -> void:
	if game == null or not game.round_active:
		velocity = Vector3.ZERO
		return

	var move := Vector2.ZERO
	var wants_action := false

	if is_bot:
		if brain != null:
			brain.think(delta)
			move = brain.move
			wants_action = brain.consume_action()
	else:
		move = Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")
		wants_action = Input.is_action_just_pressed(prefix + "_action")

	var dir := Vector3(move.x, 0, move.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	if dir.length() > 0.1:
		facing = dir.normalized()

	velocity.x = dir.x * Cfg.PLAYER_SPEED
	velocity.z = dir.z * Cfg.PLAYER_SPEED
	velocity.y = velocity.y - 20.0 * delta if not is_on_floor() else 0.0
	move_and_slide()

	var b: Vector4 = round_ref.get_bounds(self)
	global_position.x = clamp(global_position.x, b.x, b.y)
	global_position.z = clamp(global_position.z, b.z, b.w)

	# Sayışma sürerken atmak/almak yok — top sahibinin elinde bekler.
	if wants_action and round_ref.get_countdown() <= 0.0:
		_do_action()

func _do_action() -> void:
	# Öncelik: 1) havada kap  2) at  3) yerden al
	if held_ball == null:
		if _try_catch():
			return
		_try_pickup()
	else:
		_throw()

func _try_catch() -> bool:
	for ball in game.balls:
		if ball.armed and ball.thrower != null and ball.thrower.team != team:
			var d: float = global_position.distance_to(ball.global_position)
			var incoming: bool = ball.linear_velocity.dot(global_position - ball.global_position) > 0.0
			if d <= Cfg.CATCH_RADIUS and incoming:
				game.report_catch(self, ball)
				return true
	return false

func _try_pickup() -> void:
	for ball in game.balls:
		if not ball.armed and ball.held_by == null and ball.live:
			if global_position.distance_to(ball.global_position) <= Cfg.PICKUP_RADIUS:
				ball.pick_up(self)
				held_ball = ball
				return

func _throw() -> void:
	var dir := facing
	var target = game.nearest_enemy(self)
	if target != null:
		var to_t: Vector3 = target.global_position - global_position
		to_t.y = 0
		if facing.dot(to_t.normalized()) < 0.3:
			dir = to_t.normalized()
	var b := held_ball
	held_ball = null
	b.throw_at(dir, self)

func burn() -> void:
	is_burned = true
	if held_ball != null:
		var b := held_ball
		held_ball = null
		b.held_by = null   # ZORUNLU: temizlenmezse top yanık oyuncuya yapışır (çok toplu oyunda kilitlenme)
		b.freeze = false
		b.disarm()
	_mat.albedo_color = Cfg.TEAM_COLORS[team].darkened(0.55)
	# Mezarlığa geç (rakip yarının arkası)
	var strip_x: float = (Cfg.FIELD_X + 0.7) if team == 0 else -(Cfg.FIELD_X + 0.7)
	global_position = Vector3(strip_x, 1.0, randf_range(-2.0, 2.0))

# Yeni tur/faz: yanma durumunu ve elindeki topu temizle.
func reset_state() -> void:
	is_burned = false
	returns_used = 0
	if held_ball != null:
		held_ball.held_by = null
		held_ball = null
	_mat.albedo_color = Cfg.TEAM_COLORS[team]

func revive() -> void:
	# Mezarlıktan dönüş: "vuran kurtulur" — tek hak, ikinci yanış kesindir.
	is_burned = false
	returns_used += 1
	_mat.albedo_color = Cfg.TEAM_COLORS[team]
	var home_x: float = -4.0 if team == 0 else 4.0
	global_position = Vector3(home_x, 1.0, randf_range(-2.0, 2.0))

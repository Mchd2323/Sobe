class_name YTBall
extends RigidBody3D
# Yakan top topu.
# KURALLAR: atılan top "yanık"tır (armed); yere/duvara sektiği an söner —
# seken top yakmaz. Takım arkadaşına çarpan top da söner (perde).
# Havada kapılırsa atan yanar (turu yönetir).

signal hit_player(player, ball)
signal ball_reset(ball)          # sayışma başlatmak için tur'a haber

var armed := false
var live := true              # false = sayışma sürüyor, top alınamaz
var thrower = null            # YTPlayer
var held_by = null            # YTPlayer

var _grace := 0.0             # atıştan hemen sonra atıcıyla teması yok say
var _untouched := 0.0         # kimse dokunmadan geçen süre (kaybolma sigortası)
var _mesh: MeshInstance3D
var _mat := StandardMaterial3D.new()

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC  # elde taşıma titremesin
	body_entered.connect(_on_body_entered)

	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.3
	shape.shape = s
	add_child(shape)

	_mesh = MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.3
	m.height = 0.6
	_mesh.mesh = m
	_mat.albedo_color = Color(0.9, 0.85, 0.4)
	_mesh.material_override = _mat
	add_child(_mesh)

func _physics_process(delta: float) -> void:
	_grace = maxf(0.0, _grace - delta)

	if held_by != null:
		_untouched = 0.0
		var p = held_by
		global_position = p.global_position + p.facing * 0.7 + Vector3.UP * 1.0
		return

	# Sayışma sürerken top beklemede: ne sayaç işler ne de yeniden sıfırlanır.
	if not live:
		_untouched = 0.0
		return

	# Kaybolma sigortası: uzun süre sahipsiz kalan ya da sahadan düşen top ortaya döner.
	_untouched += delta
	if _untouched > Cfg.BALL_RESET_TIME or global_position.y < -3.0:
		request_restart()

# Top yeniden dağıtılsın: sahibi ve yeri tur'un kararı (on_ball_reset).
func request_restart() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	disarm()
	_untouched = 0.0
	live = false
	freeze = true
	ball_reset.emit(self)

# Sayışma bitti: top oyunda.
func go_live() -> void:
	live = true
	freeze = false
	_untouched = 0.0

func pick_up(player) -> void:
	held_by = player
	armed = false
	thrower = null
	freeze = true
	_untouched = 0.0
	_update_color()

func throw_at(dir: Vector3, by_player) -> void:
	held_by = null
	freeze = false
	thrower = by_player
	armed = true
	_grace = 0.25
	_untouched = 0.0
	var d := dir.normalized()
	linear_velocity = d * Cfg.THROW_SPEED + Vector3.UP * Cfg.THROW_UP
	angular_velocity = Vector3.ZERO
	_update_color()

func disarm() -> void:
	armed = false
	thrower = null
	_update_color()

func _update_color() -> void:
	if armed:
		_mat.albedo_color = Color(1.0, 0.45, 0.1)
		_mat.emission_enabled = true
		_mat.emission = Color(1.0, 0.3, 0.0)
	else:
		_mat.emission_enabled = false
		_mat.albedo_color = Color(0.9, 0.85, 0.4)

func _on_body_entered(body: Node) -> void:
	if body is YTPlayer:
		if not armed or thrower == null:
			return
		if body == thrower and _grace > 0.0:
			return  # elden yeni çıktı, atıcıya çarpmış sayma
		if body.team != thrower.team and not body.is_burned:
			hit_player.emit(body, self)   # yakma — turu yönetir
		else:
			disarm()                      # takım arkadaşı/yanık gövde perdeledi
	else:
		# Zemin/duvar teması: seken top yakmaz.
		if armed:
			disarm()

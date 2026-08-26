extends Node3D
# SOBE — Faz 1 gri kutu v0.2: Yakan Top 2v2
# Akış: KURAL KARESİ → OYUN → SONUÇ (R: tekrar)
#
# İNSAN OYUNCU SAYISI: 1-4 arası değiştir. Kalan koltuklar bot.
const HUMAN_PLAYERS := 1

enum State { BRIEFING, PLAYING, RESULT }
var state: int = State.BRIEFING
var round_active := false

var players: Array = []
var balls: Array = []
var current_round: RoundBase

var _rule_panel: PanelContainer
var _result_label: Label
var _score_label: Label
var _countdown_label: Label

func _ready() -> void:
	_setup_input()
	_build_arena()

	# Sıra önemli: tur önce kurulur, UI kural kartını AYNI turdan okur (yetim node yok).
	current_round = YakanTopRound.new()
	add_child(current_round)
	current_round.round_finished.connect(_on_round_finished)

	_build_ui()
	_spawn_players()
	_spawn_ball(Vector3(0, 0.5, 0))
	current_round.setup(players, self)
	_show_rule_card()

	# CI bot maçı kancası — YALNIZ bayrakla yüklenir, normal oyunda hiç dokunulmaz.
	if "--sobe-autotest" in OS.get_cmdline_user_args():
		var at: Node = load("res://scripts/autotest.gd").new()
		add_child(at)
		at.begin(self)

func _process(_delta: float) -> void:
	if state == State.PLAYING and _countdown_label != null:
		var c: float = current_round.get_countdown()
		if c > 0.0:
			_countdown_label.text = str(int(ceil(c)))
			_countdown_label.visible = true
		else:
			_countdown_label.visible = false

	match state:
		State.BRIEFING:
			for i in range(1, 5):
				if InputMap.has_action("p%d_action" % i) and Input.is_action_just_pressed("p%d_action" % i):
					_start_round()
					break
		State.RESULT:
			if Input.is_physical_key_pressed(KEY_R):
				get_tree().reload_current_scene()

# ---------- AKIŞ ----------

func _start_round() -> void:
	state = State.PLAYING
	round_active = true
	_rule_panel.visible = false
	current_round.start()
	# Açılış topu da sayışmayla iner — kimse çizgide bekleyip bedavaya alamaz.
	for b in balls:
		b.reset_to_center()

func _on_round_finished(winner_team: int) -> void:
	state = State.RESULT
	round_active = false
	_result_label.text = "%s TAKIM KAZANDI!\n\n[R] Tekrar oyna" % Cfg.TEAM_NAMES[winner_team]
	_result_label.visible = true

# Olay yönlendirme: Main yalnız RoundBase sözleşmesini çağırır.
func report_catch(catcher, ball: YTBall) -> void:
	current_round.on_catch(catcher, ball)

func nearest_enemy(player):
	var best = null
	var best_d := INF
	for pl in players:
		if pl.team != player.team and not pl.is_burned:
			var d: float = player.global_position.distance_to(pl.global_position)
			if d < best_d:
				best_d = d
				best = pl
	return best

# ---------- KURULUM ----------

func _spawn_players() -> void:
	for i in range(4):
		var p := YTPlayer.new()
		p.index = i
		p.game = self
		p.set_team(i % 2)          # 0,2 -> Mavi | 1,3 -> Kırmızı
		p.prefix = "p%d" % (i + 1)
		if i >= HUMAN_PLAYERS:
			p.is_bot = true
			var brain := BotBrain.new()
			brain.player = p
			brain.game = self
			p.brain = brain
		add_child(p)
		players.append(p)

func _spawn_ball(pos: Vector3) -> void:
	var b := YTBall.new()
	add_child(b)
	b.global_position = pos
	b.hit_player.connect(func(pl, ball): current_round.on_player_hit(pl, ball))
	b.ball_reset.connect(func(ball): current_round.on_ball_reset(ball))
	balls.append(b)

func _build_arena() -> void:
	var half_x := Cfg.FIELD_X + Cfg.MEZARLIK_W + 0.5   # 9.7
	# Zemin
	_make_box(Vector3(0, -0.5, 0), Vector3(half_x * 2, 1, Cfg.FIELD_Z * 2 + 1), Color(0.42, 0.42, 0.45), true)
	# Orta çizgi + mezarlık şeritleri (görsel)
	_make_box(Vector3(0, 0.02, 0), Vector3(0.15, 0.05, Cfg.FIELD_Z * 2), Color.WHITE, false)
	_make_box(Vector3(Cfg.FIELD_X + Cfg.MEZARLIK_W * 0.5, 0.02, 0), Vector3(Cfg.MEZARLIK_W, 0.05, Cfg.FIELD_Z * 2), Cfg.TEAM_COLORS[0].darkened(0.4), false)
	_make_box(Vector3(-Cfg.FIELD_X - Cfg.MEZARLIK_W * 0.5, 0.02, 0), Vector3(Cfg.MEZARLIK_W, 0.05, Cfg.FIELD_Z * 2), Cfg.TEAM_COLORS[1].darkened(0.4), false)

	# DUVARLAR: top sahadan çıkamaz (kilitlenme sigortası #1).
	var wall_c := Color(0.30, 0.30, 0.33)
	var wx := half_x - 0.2
	var wz := Cfg.FIELD_Z + 0.7
	_make_box(Vector3(wx, 0.6, 0), Vector3(0.4, 1.2, wz * 2), wall_c, true)
	_make_box(Vector3(-wx, 0.6, 0), Vector3(0.4, 1.2, wz * 2), wall_c, true)
	_make_box(Vector3(0, 0.6, wz), Vector3(wx * 2 + 0.4, 1.2, 0.4), wall_c, true)
	_make_box(Vector3(0, 0.6, -wz), Vector3(wx * 2 + 0.4, 1.2, 0.4), wall_c, true)

	# Kamera (paylaşımlı, sabit)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 15, 11)
	add_child(cam)
	cam.look_at(Vector3(0, 0, 0))
	cam.current = true

	# Işık
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	add_child(sun)

func _make_box(pos: Vector3, size: Vector3, color: Color, solid: bool) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		body.position = pos
		add_child(body)

# ---------- UI ----------

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	# CenterContainer + FULL_RECT: kutuyu gerçekten ortalar.
	# (PRESET_CENTER panelin SOL ÜST köşesini ortaya koyuyor, panel sağa taşıyordu.)
	var rule_center := CenterContainer.new()
	rule_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	rule_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rule_center)

	_rule_panel = PanelContainer.new()
	_rule_panel.custom_minimum_size = Vector2(860, 0)
	rule_center.add_child(_rule_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_rule_panel.add_child(vbox)
	var card: Dictionary = current_round.get_rule_card()
	for key in ["amac", "yanma", "siddet"]:
		var l := Label.new()
		l.text = card[key]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(840, 0)
		vbox.add_child(l)
	var start := Label.new()
	start.text = "\nBaşlamak için ATIŞ tuşuna bas  (P1: Boşluk | P2: Enter | Gamepad: A)"
	start.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start.custom_minimum_size = Vector2(840, 0)
	vbox.add_child(start)

	_score_label = Label.new()
	_score_label.text = "YAKAN TOP 2v2 — gri kutu v0.2 | MAVİ: P1 + P3  vs  KIRMIZI: P2 + P4"
	_score_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_score_label.offset_left = 16
	_score_label.offset_top = 12
	_score_label.offset_right = -16
	_score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	canvas.add_child(_score_label)

	# Geri sayım (sayışma)
	var cd_center := CenterContainer.new()
	cd_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	cd_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(cd_center)
	_countdown_label = Label.new()
	_countdown_label.add_theme_font_size_override("font_size", 96)
	_countdown_label.visible = false
	cd_center.add_child(_countdown_label)

	var res_center := CenterContainer.new()
	res_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	res_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(res_center)
	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 36)
	_result_label.visible = false
	res_center.add_child(_result_label)

func _show_rule_card() -> void:
	state = State.BRIEFING
	_rule_panel.visible = true

# ---------- GİRİŞ HARİTASI ----------
# Klavye: P1 = WASD + Boşluk, P2 = Ok tuşları + Enter
# Gamepad: P3 = cihaz 0, P4 = cihaz 1 (sol çubuk + A)

func _setup_input() -> void:
	var kb := {
		"p1": {"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D, "action": KEY_SPACE},
		"p2": {"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT, "action": KEY_ENTER},
	}
	for p in kb.keys():
		for a in kb[p].keys():
			var action: String = "%s_%s" % [p, a]
			if not InputMap.has_action(action):
				InputMap.add_action(action)
				var ev := InputEventKey.new()
				ev.physical_keycode = kb[p][a]
				InputMap.action_add_event(action, ev)

	for pi: int in [3, 4]:
		var device := pi - 3
		var pre := "p%d" % pi
		_add_axis_action(pre + "_left", device, JOY_AXIS_LEFT_X, -1.0)
		_add_axis_action(pre + "_right", device, JOY_AXIS_LEFT_X, 1.0)
		_add_axis_action(pre + "_up", device, JOY_AXIS_LEFT_Y, -1.0)
		_add_axis_action(pre + "_down", device, JOY_AXIS_LEFT_Y, 1.0)
		var action: String = pre + "_action"
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var btn := InputEventJoypadButton.new()
			btn.device = device
			btn.button_index = JOY_BUTTON_A
			InputMap.action_add_event(action, btn)

func _add_axis_action(action: String, device: int, axis: int, value: float) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.35)
	var ev := InputEventJoypadMotion.new()
	ev.device = device
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)

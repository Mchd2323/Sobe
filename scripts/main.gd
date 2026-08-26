extends Node3D
# SOBE — Faz 1 gri kutu v0.2: Yakan Top 2v2
# Akış: KURAL KARESİ → OYUN → SONUÇ (R: tekrar)
#
# Kim oynayacağı LOBİ'de belirlenir (A2): tuşa basan koltuk insan, kalanlar bot.
# Eski HUMAN_PLAYERS sabiti kaldırıldı.

var flow: GameFlow
var round_active := false   # oyuncular hareket edebilir mi (deneme atışı + oyun)

var players: Array = []
var balls: Array = []
var current_round: RoundBase
var score_board: ScoreBoard

var _rule_panel: PanelContainer
var _rule_label: Label
var oyun_idx := 0
var _tab_basili := false
const OYUNLAR := ["Yakan Top 2v2", "Mendil Kapmaca 1v1"]
var _result_label: Label
var _score_label: Label
var _countdown_label: Label
var _phase_label: Label
var _dim: ColorRect
var _phase_box: Control
var _banner_label: Label
var _banner_box: Control
var _result_box: Control

func _ready() -> void:
	_setup_input()
	_build_arena()

	# Sıra önemli: tur önce kurulur, UI kural kartını AYNI turdan okur (yetim node yok).
	score_board = ScoreBoard.new()
	add_child(score_board)

	flow = GameFlow.new()
	add_child(flow)
	flow.phase_changed.connect(_on_phase_changed)

	# Hangi oyun? (CI ve testler için; E3'te menüye dönüşecek)
	#   godot --headless --path . -- --sobe-round=mendil
	for a in OS.get_cmdline_user_args():
		if a == "--sobe-round=mendil":
			oyun_idx = 1
	_kur_tur()
	current_round.round_finished.connect(_on_round_finished)

	_build_ui()
	_spawn_players()

	current_round.setup(players, self)
	if _rule_label != null:
		_rule_label.text = Briefing.render(current_round)
	_on_phase_changed(flow.phase)   # LOBİ ekranını çiz

	# CI bot maçı kancası — YALNIZ bayrakla yüklenir, normal oyunda hiç dokunulmaz.
	if "--sobe-briefingtest" in OS.get_cmdline_user_args():
		var bt: Node = load("res://scripts/briefing_test.gd").new()
		add_child(bt)
		bt.begin(self)
	if "--sobe-dueltest" in OS.get_cmdline_user_args():
		var dt: Node = load("res://scripts/duel_test.gd").new()
		add_child(dt)
		dt.begin(self)
	if "--sobe-encountertest" in OS.get_cmdline_user_args():
		var et: Node = load("res://scripts/encounter_test.gd").new()
		add_child(et)
		et.begin(self)
	if "--sobe-autotest" in OS.get_cmdline_user_args():
		var at: Node = load("res://scripts/autotest.gd").new()
		add_child(at)
		at.begin(self)

func _process(_delta: float) -> void:
	# Sayışma sayacı (yalnız tur dönerken)
	if _countdown_label != null:
		var c: float = current_round.get_countdown() if flow.is_live() else -1.0
		_countdown_label.visible = c > 0.0
		if c > 0.0:
			_countdown_label.text = str(int(ceil(c)))

	# DENEME ATIŞI: beklemek zorunlu değil, hazır olan ATIŞ tuşuyla düdüğü çalar.
	if flow.phase == GameFlow.Phase.PRACTICE and _action_just_pressed():
		flow.set_phase(GameFlow.Phase.PLAYING)
		return

	# Üst şerit: deneme sayacı, sonra yanma uyarısı
	if _banner_box != null:
		if flow.phase == GameFlow.Phase.PRACTICE:
			_set_banner("DENEME ATIŞI — %d sn  (kimse yanmaz)   •   ATIŞ tuşu: HAZIRIM" % int(ceil(flow.practice_left)))
		elif flow.phase == GameFlow.Phase.PLAYING and _human_burned():
			# Mezarlık sahanın KARŞI ucundadır; oyuncu kendini kaybetmesin.
			_set_banner("YANDIN — mezarlıktasın: sahanın KARŞI ucunda, koyu renkli olansın")
		elif _banner_label.text.find("DENEME") != -1 or _banner_label.text.find("YANDIN") != -1:
			_set_banner("")

	# LOBİ: ilk basış koltuğa oturtur, ikinci basış maçı başlatır
	if flow.phase == GameFlow.Phase.LOBBY:
		if Input.is_physical_key_pressed(KEY_TAB) and not _tab_basili:
			_tab_basili = true
			_oyun_degistir()
			return
		if not Input.is_physical_key_pressed(KEY_TAB):
			_tab_basili = false
		for i in range(4):
			var a := "p%d_action" % (i + 1)
			if InputMap.has_action(a) and Input.is_action_just_pressed(a):
				if not flow.joined[i]:
					flow.join(i)
					_phase_label.text = _lobby_text()
				else:
					flow.advance()
				break
		return

	# Diğer bekleyen fazlarda ATIŞ tuşu ilerletir
	if not flow.is_live() and _action_just_pressed():
		flow.advance()

# ---------- AKIŞ ----------

# LOBİ kararını sahneye uygula: katılan koltuk insan, kalan bot.
func _apply_seats() -> void:
	for i in range(players.size()):
		var p = players[i]
		p.is_bot = not flow.joined[i]
		if p.is_bot:
			# Her seferinde turdan iste: tur değişince beyin de değişmeli.
			p.brain = current_round.make_brain(p, self)
		else:
			p.brain = null

func _lobby_text() -> String:
	var t := "SOBE\n\nOYUN:  %s      [TAB] oyunu değiştir\n\n" % OYUNLAR[oyun_idx]
	for i in range(4):
		var tag: String = "%s (%s)" % [Cfg.CHARACTERS[i], Cfg.TEAM_NAMES[i % 2]]
		if flow.joined[i]:
			t += "P%d  %s  ✔ KATILDI\n" % [i + 1, tag]
		else:
			t += "P%d  %s  — boş (bot)\n" % [i + 1, tag]
	t += "\nKatılmak için kendi ATIŞ tuşuna bas"
	if flow.joined_count() > 0:
		t += "\nBaşlatmak için katıldığın tuşa TEKRAR bas"
	return t

func _set_banner(t: String) -> void:
	_banner_label.text = t
	_banner_box.visible = (t != "")

func _human_burned() -> bool:
	for p in players:
		if not p.is_bot and p.is_burned:
			return true
	return false

# Turu kur / değiştir. Lobide oyun seçimi buradan geçer.
func _kur_tur() -> void:
	if current_round != null:
		current_round.queue_free()
	current_round = MendilRound.new() if oyun_idx == 1 else YakanTopRound.new()
	add_child(current_round)
	current_round.round_finished.connect(_on_round_finished)

	# Top gerekmeyen turda sahada top durmasın.
	if current_round.needs_ball():
		if balls.is_empty():
			_spawn_ball(Vector3(0, 0.5, 0))
	else:
		for b in balls:
			b.queue_free()
		balls.clear()

	if players.size() > 0:
		current_round.setup(players, self)
	if _rule_label != null:
		_rule_label.text = Briefing.render(current_round)
	score_board.reset()

func _oyun_degistir() -> void:
	oyun_idx = (oyun_idx + 1) % OYUNLAR.size()
	_kur_tur()
	_phase_label.text = _lobby_text()

func _action_just_pressed() -> bool:
	for i in range(1, 5):
		var a := "p%d_action" % i
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			return true
	return false

# Akış makinesinin tek çıkışı: faz değişince sahneyi ve arayüzü buna göre kur.
func _on_phase_changed(p: int) -> void:
	round_active = flow.is_live()
	_rule_panel.visible = (p == GameFlow.Phase.BRIEFING)
	_result_box.visible = (p == GameFlow.Phase.SCORE)
	# Faz kutusu yalnız yazacak bir şey varken görünsün (OYUN'da düdükten sonra boşalır).
	# Ortadaki büyük kutu YALNIZ lobide; oyun sırasında arenayı hiçbir şey kapatmaz.
	_phase_box.visible = (p == GameFlow.Phase.LOBBY)
	# Bekleme fazlarında saha karartılır ki metin okunsun.
	_dim.visible = not flow.is_live()

	match p:
		GameFlow.Phase.LOBBY:
			_phase_label.text = _lobby_text()
		GameFlow.Phase.BRIEFING:
			_apply_seats()   # lobi kararını sahneye yaz; kural kartı görünür
		GameFlow.Phase.PRACTICE:
			current_round.practice = true
			current_round.setup(players, self)
			current_round.start()
		GameFlow.Phase.PLAYING:
			_apply_seats()   # lobi atlandıysa (CI) da koltuklar tutarlı olsun
			current_round.practice = false
			current_round.setup(players, self)
			current_round.start()
			_set_banner("DÜDÜK! — MAÇ BAŞLADI")
			_clear_banner_soon()
		GameFlow.Phase.SCORE:
			_phase_label.text = ""

func _clear_banner_soon() -> void:
	await get_tree().create_timer(1.5).timeout
	if flow.phase == GameFlow.Phase.PLAYING and _banner_label.text.find("DÜDÜK") != -1:
		_set_banner("")

func _on_round_finished(winner_team: int) -> void:
	# Misket dağıtımı (4/2/1/0) turun sıralamasına göre, sonra tablo.
	score_board.award(current_round.get_ranking())
	flow.set_phase(GameFlow.Phase.SCORE)
	_result_label.text = "%s TAKIM KAZANDI\n\n%s\nDevam için ATIŞ tuşuna bas" % [
		Cfg.TEAM_NAMES[winner_team], score_board.table_text(players)]

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

# Arena üstündeki metinler için koyu zemin: gri kutuda okunabilirlik sanattan önce gelir.
func _text_backdrop() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.09, 0.88)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(22)
	return sb

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	# Bekleme fazlarında sahayı karart: yazılar arenanın üstünde okunsun.
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.62)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_dim)

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
	_rule_label = Label.new()
	var l := _rule_label
	l.text = Briefing.render(current_round)   # rol bazlı kart(lar) + Hakem satırı
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
	_score_label.text = "YAKAN TOP 2v2 — gri kutu %s | MAVİ: Cenk + Deniz  vs  KIRMIZI: Aslı + Selim" % Cfg.BUILD_LABEL
	_score_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_score_label.offset_left = 16
	_score_label.offset_top = 12
	_score_label.offset_right = -16
	_score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	canvas.add_child(_score_label)

	# Faz başlığı (lobi / deneme atışı / düdük)
	var ph_center := CenterContainer.new()
	ph_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ph_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ph_center.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ph_center.offset_top = 90
	canvas.add_child(ph_center)
	var ph_panel := PanelContainer.new()
	ph_panel.add_theme_stylebox_override("panel", _text_backdrop())
	ph_center.add_child(ph_panel)
	_phase_box = ph_panel
	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 30)
	ph_panel.add_child(_phase_label)

	# ÜST ŞERİT: oyun içi bildirimler (deneme sayacı, düdük, yandın uyarısı).
	# Arenanın ÜSTÜNE binmesin diye ortada değil, ekranın tepesinde.
	var bn_center := CenterContainer.new()
	bn_center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bn_center.offset_top = 52
	bn_center.offset_bottom = 150
	bn_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bn_center)
	var bn_panel := PanelContainer.new()
	bn_panel.add_theme_stylebox_override("panel", _text_backdrop())
	bn_center.add_child(bn_panel)
	_banner_box = bn_panel
	_banner_label = Label.new()
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 26)
	bn_panel.add_child(_banner_label)
	bn_panel.visible = false

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
	var res_panel := PanelContainer.new()
	res_panel.add_theme_stylebox_override("panel", _text_backdrop())
	res_center.add_child(res_panel)
	_result_box = res_panel
	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 36)
	res_panel.visible = false
	res_panel.add_child(_result_label)

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

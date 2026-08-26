class_name IstopRound
extends RoundBase
# İSTOP — FFA (B1). Kaynak: geleneksel kurallar + kullanıcı tasarım kartı.
#
#   ÇAĞRI    : top sahibi topu DİKİNE fırlatır ve bir isim çağırır
#   KAÇIŞMA  : çağrılan topa koşar, diğerleri dağılır
#   İSTOP!   : çağrılan topu havada yakalar → HERKES DONAR
#              (yere düşerse çağrılan ceza alır ve yeni çağırıcı olur)
#   ADIM+ATIŞ: top sahibi en fazla STEP_BUDGET adım yürür, donmuş birine atar
#              isabet = hedefe ceza, ıska = atana ceza
#   Vurulan (ıskada atan) yeni çağırıcı olur.
#
# Ceza harf toplar: İ-S-T-O-P. PENALTY_LETTERS harfe ulaşan yanar, el biter.
# Donmadan sonra FREEZE_GRACE'ten fazla kıpırdayan da ceza alır.

enum Faz { CAGRI, KACISMA, DONMA, ADIM, SONUC }

var players: Array = []
var faz: int = Faz.CAGRI
var cagirici = null       # topu fırlatıp isim çağıran
var cagrilan = null       # adı çağrılan
var topcu = null          # topu yakalayıp İSTOP diyen

var harf := [0, 0, 0, 0]  # ceza harfleri (oyuncu index'ine göre)
var el := 0               # kaçıncı el
var _game = null
var _t := 0.0
var _don_t := 0.0
var _adim_kalan := 0.0
var _son_poz := {}
var _olay := ""
var _olay_t := 0.0
var _winner_idx := -1

# ölçüm
var eller := 0
var cezalar := [0, 0, 0, 0]

# --- sözleşme ---

func needs_ball() -> bool:
	return true

func get_hakem_line() -> String:
	return "Top havada. Adı çağrılan yakalar ve İSTOP der. O anda kıpırdayan yanar."

func get_rule_card(_role: String = "") -> Dictionary:
	return {
		"amac": "AMAÇ: Adın çağrılınca topu KAP, İSTOP de, donmuş birini VUR.",
		"yanma": "CEZA: İstop'tan sonra kıpırdarsan ya da top sana değerse harf alırsın. %d harf = yandın." % Cfg.PENALTY_LETTERS,
		"siddet": "ŞİDDET: 🔵 Yasak — sadece top konuşur. Atarken en fazla %d adım yürüyebilirsin." % Cfg.STEP_BUDGET,
	}

func make_brain(player, game):
	var b := IstopBrain.new()
	b.player = player
	b.game = game
	b.round_ref = self
	# Kişilik: tepki gecikmesi koltuk sırasından (Cenk tez canlı, Selim sakin)
	b.reaction = Cfg.DUEL_PERSONA[player.index % Cfg.DUEL_PERSONA.size()][0] * 0.6
	return b

func setup(p_players: Array, root: Node3D) -> void:
	players = p_players
	_game = root
	harf = [0, 0, 0, 0]
	cezalar = [0, 0, 0, 0]
	el = 0
	eller = 0
	_winner_idx = -1
	_olay = ""
	for i in range(players.size()):
		players[i].reset_state()
		players[i].round_ref = self
		var a: float = TAU * float(i) / float(players.size())
		players[i].global_position = Vector3(cos(a) * 4.0, 1, sin(a) * 3.0)
	cagirici = players[0]

func start() -> void:
	_yeni_el()

func get_bounds(_player) -> Vector4:
	return Vector4(-Cfg.FIELD_X + 0.6, Cfg.FIELD_X - 0.6, -Cfg.FIELD_Z + 0.6, Cfg.FIELD_Z - 0.6)

func get_countdown() -> float:
	return _t if faz == Faz.CAGRI else -1.0

func get_status_text() -> String:
	var s := "EL %d/%d   " % [el, Cfg.ROUND_CAP]
	for p in players:
		s += "%s:%s  " % [p.char_name(), _harf_yazi(p.index)]
	match faz:
		Faz.CAGRI:
			if cagrilan != null:
				s += "\n▶ ÇAĞRI: %s!" % cagrilan.char_name()
		Faz.KACISMA:
			s += "\n▶ %s topa koşuyor — diğerleri dağılın!" % (cagrilan.char_name() if cagrilan != null else "?")
		Faz.DONMA:
			s += "\n▶ İSTOP! HERKES DONDU — kıpırdama!"
		Faz.ADIM:
			s += "\n▶ %s nişan alıyor (%d adım hakkı)" % [topcu.char_name() if topcu != null else "?", Cfg.STEP_BUDGET]
	if _olay != "":
		s += "\n" + _olay
	return s

func get_ranking() -> Array:
	var arr := players.duplicate()
	arr.sort_custom(func(a, b):
		if harf[a.index] != harf[b.index]:
			return harf[a.index] < harf[b.index]   # az harf = iyi
		return a.index < b.index)
	return arr

# --- IstopBrain'in sorduklari ---

func top():
	if _game == null or _game.balls.is_empty():
		return null
	return _game.balls[0]

func en_yakin_hedef(atan):
	var best = null
	var bd := INF
	for p in players:
		if p == atan or harf[p.index] >= Cfg.PENALTY_LETTERS:
			continue
		var d: float = atan.global_position.distance_to(p.global_position)
		if d < bd:
			bd = d
			best = p
	return best

# --- döngü ---

func _harf_yazi(idx: int) -> String:
	var t := ""
	for i in range(harf[idx]):
		t += Cfg.ISTOP_LETTERS[i]
	return t if t != "" else "-"

func _olay_yaz(t: String) -> void:
	_olay = t
	_olay_t = 2.2

func _ceza(p, sebep: String) -> void:
	harf[p.index] += 1
	cezalar[p.index] += 1
	_olay_yaz("%s ceza aldı (%s) → %s" % [p.char_name(), sebep, _harf_yazi(p.index)])
	if harf[p.index] >= Cfg.PENALTY_LETTERS:
		_bitir()

func _bitir() -> void:
	faz = Faz.SONUC
	var sirali := get_ranking()
	_winner_idx = sirali[0].index
	round_finished.emit(sirali[0].team)

func _yeni_el() -> void:
	if el >= Cfg.ROUND_CAP:
		_bitir()
		return
	el += 1
	eller += 1
	faz = Faz.CAGRI
	_t = Cfg.CALL_UI_TIME
	topcu = null
	# Çağrı seçimi: en yakın rakip ağırlıklı (kişilik sapması D3'te gelecek)
	var adaylar := []
	for p in players:
		if p != cagirici and harf[p.index] < Cfg.PENALTY_LETTERS:
			adaylar.append(p)
	if adaylar.is_empty():
		_bitir()
		return
	cagrilan = adaylar[randi() % adaylar.size()]
	var b = top()
	if b != null:
		b.held_by = null
		b.freeze = false
		b.live = true
		b.disarm()
		b.global_position = cagirici.global_position + Vector3.UP * 1.4
		b.linear_velocity = Vector3(0, Cfg.ISTOP_TOSS_UP, 0)
	_olay_yaz("%s topu havaya attı ve %s'i çağırdı!" % [cagirici.char_name(), cagrilan.char_name()])

func _process(delta: float) -> void:
	if _game == null or not _game.round_active or faz == Faz.SONUC:
		return
	if _olay_t > 0.0:
		_olay_t -= delta
		if _olay_t <= 0.0:
			_olay = ""

	match faz:
		Faz.CAGRI:
			_t -= delta
			if _t <= 0.0:
				faz = Faz.KACISMA
		Faz.KACISMA:
			_kacisma()
		Faz.DONMA:
			_donma(delta)
		Faz.ADIM:
			_adim(delta)

func _kacisma() -> void:
	var b = top()
	if b == null:
		return
	# Çağrılan havada yakalarsa İSTOP
	if cagrilan != null and b.global_position.y > 0.6:
		if cagrilan.global_position.distance_to(b.global_position) <= Cfg.ISTOP_CATCH_R:
			topcu = cagrilan
			b.pick_up(topcu)
			topcu.held_ball = b
			faz = Faz.DONMA
			_don_t = 0.0
			_son_poz.clear()
			for p in players:
				_son_poz[p] = p.global_position
			_olay_yaz("İSTOP! %s yakaladı — herkes dondu" % topcu.char_name())
			return
	# Yere düştüyse çağrılan ceza alır ve yeni çağırıcı olur
	if b.global_position.y < 0.45:
		var suclu = cagrilan
		_olay_yaz("%s topu tutamadı!" % suclu.char_name())
		cagirici = suclu
		_ceza(suclu, "topu tutamadı")
		if faz != Faz.SONUC:
			_yeni_el()

func _donma(delta: float) -> void:
	_don_t += delta
	# Donma toleransı: bu süreden sonra kıpırdayan ceza alır
	if _don_t <= Cfg.FREEZE_GRACE:
		for p in players:
			_son_poz[p] = p.global_position
		return
	for p in players:
		if p == topcu or harf[p.index] >= Cfg.PENALTY_LETTERS:
			continue
		var onceki: Vector3 = _son_poz.get(p, p.global_position)
		if p.global_position.distance_to(onceki) > 0.35:
			_ceza(p, "istop'ta kıpırdadı")
			if faz == Faz.SONUC:
				return
			_son_poz[p] = p.global_position
	# Donma bitti, atış fazı
	if _don_t > Cfg.FREEZE_GRACE + 0.8:
		faz = Faz.ADIM
		_adim_kalan = Cfg.STEP_BUDGET * Cfg.ISTOP_STEP_LEN
		_son_poz[topcu] = topcu.global_position

func _adim(delta: float) -> void:
	if topcu == null:
		_yeni_el()
		return
	# Adım bütçesi: yürüdükçe azalır, bitince atmak zorunda
	var onceki: Vector3 = _son_poz.get(topcu, topcu.global_position)
	_adim_kalan -= topcu.global_position.distance_to(onceki)
	_son_poz[topcu] = topcu.global_position
	_t += delta
	if _adim_kalan > 0.0 and _t < 2.5:
		return
	_atis()

func _atis() -> void:
	var hedef = en_yakin_hedef(topcu)
	var b = top()
	if hedef == null or b == null:
		_yeni_el()
		return
	var isabet: bool = topcu.global_position.distance_to(hedef.global_position) <= 4.5 and randf() < 0.65
	b.held_by = null
	topcu.held_ball = null
	b.freeze = false
	b.global_position = topcu.global_position + Vector3.UP * 1.2
	var d: Vector3 = (hedef.global_position - topcu.global_position).normalized()
	b.linear_velocity = d * Cfg.THROW_SPEED_ISTOP
	if isabet:
		_olay_yaz("%s → %s: İSABET!" % [topcu.char_name(), hedef.char_name()])
		cagirici = hedef
		_ceza(hedef, "top değdi")
	else:
		_olay_yaz("%s → %s: ISKA!" % [topcu.char_name(), hedef.char_name()])
		cagirici = topcu
		_ceza(topcu, "ıskaladı")
	_t = 0.0
	if faz != Faz.SONUC:
		_yeni_el()

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
#   • Karşılaşma olmadan MENDIL_TIMER geçerse mendil ortaya döner (anti-stall)
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
var _in_circle_t := [0.0, 0.0]   # kapmadan çemberde geçirilen süre
var _intents := {}
var _winner_idx := -1

var both_burned := 0      # ölçüm (MUTUAL_BURN açıkken)
var encounters := 0       # ölçüm: kaç karşılaşma yaşandı
var escapes := 0          # ölçüm: kaçanın düelloyu kazanma sayısı

# Karşılaşma durumu
var engaged := false
var _eng_t := 0.0
var _eng_runner_move := -1
var _eng_tell := 0.0
var _insan_hamle_t := -1.0   # insan kovalayan hamlesini KAÇINCI saniyede verdi
var _insan_ilk_hamle := -1   # ve HANGİ hamleyi verdi (sonra fikir değiştiremez)
# HATA: kaçanın hamlesi karşılaşmanın BAŞINDA okunuyordu — oyuncu daha hiçbir
# tuşa basmamışken. 0.7 sn boyunca bastıkları hiç okunmuyordu ("rakamlar işe
# yaramıyor"). Artık pencere boyunca örnekleniyor ve ilk basış kilitleniyor.
var _insan_kacan_secim := -1
var _recovery := 0.0      # ıskalayan kovalayanın toparlanma süresi
var _mendil_timer := 0.0  # anti-stall
var _olay := ""          # son olayın ekrandaki karşılığı
var _cozum_t := 0.0      # çözüm gösterimi: temas/ıska ekranda görünsün
var _bekleyen_sayi := -1 # gösterim bitince verilecek sayı
# Hamleler IŞINLANMAZ, kayarak yapılır: kullanıcı "sağdan giderken aniden
# solda beliriyor" dedi. Hedefler burada tutulur, gösterim boyunca lerp edilir.
var _hedef_kacan := Vector3.ZERO
var _hedef_kov := Vector3.ZERO
var _cozum_toplam := 0.0
var _olay_t := 0.0
var _kacan_bot := DuelEncounter.KacanBot.new()
var _kov_bot := DuelEncounter.KovalayanBot.new()
var bluff_points := 0     # ölçüm: rakibi çembere sokarak alınan sayı

# --- sözleşme ---

func needs_ball() -> bool:
	return false

func get_hakem_line() -> String:
	return "Mendil çemberde. Kapan içeride dokunulmaz ama sonsuza kadar duramaz."

func get_rule_card(_role: String = "") -> Dictionary:
	return {
		"amac": "AMAÇ: Mendili KAP, rakibin üstünden geçip KENDİ çizgine dön. Önce %d sayı." % Cfg.MENDIL_TARGET_POINTS,
		"yanma": "YANMA: Kovalayan sana DOKUNURSA sayı onun. Çember içinde dokunulmazsın.",
		"siddet": "ŞİDDET: 🟡 Mendil sendeyken YAVAŞSIN ve kovalayan daha hızlıdır — bilerek. Kaçış koşuyla değil, KARŞILAŞMADA kazanılır.",
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
		m.size = Vector3(0.75, 0.12, 0.75)     # gri kutuda görünmeyen nesne yok sayılır
		_mendil.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.95, 0.35)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.85, 0.2)
		mat.emission_energy_multiplier = 1.6
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
	var w = null
	if _winner_idx >= 0:
		w = duelists[_winner_idx]
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
	if i < 0:
		return null
	return duelists[1 - i]

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
	_in_circle_t = [0.0, 0.0]
	_cozum_t = 0.0
	_cozum_toplam = 0.0
	_bekleyen_sayi = -1
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

# Hamle adları tek yerde: sözlükten okunan yerlerde eksik anahtar hatası
# çıkmasın diye (ÇALIM böyle atlanmıştı).
func _hamle_adi(m: int, kacan: bool) -> String:
	if kacan:
		match m:
			DuelEncounter.Kacan.KIRMA_SOL: return "SOLA KIR"
			DuelEncounter.Kacan.KIRMA_SAG: return "SAĞA KIR"
			DuelEncounter.Kacan.KAYMA: return "KAYMA"
			DuelEncounter.Kacan.DURAKLAMA: return "DURAKLAMA"
			DuelEncounter.Kacan.CALIM: return "ÇALIM"
		return "?"
	match m:
		DuelEncounter.Kovalayan.LUNGE_L: return "SOLA ATIL"
		DuelEncounter.Kovalayan.LUNGE_R: return "SAĞA ATIL"
		DuelEncounter.Kovalayan.LUNGE_DUZ: return "DÜZ ATIL"
		DuelEncounter.Kovalayan.POZISYON: return "BEKLE"
	return "?"

func _insan_duellocu():
	for d in duelists:
		if not d.is_bot:
			return d
	return null

func _olay_yaz(t: String) -> void:
	_olay = t
	_olay_t = 2.0

func get_status_text() -> String:
	if _resetting:
		return "HAZIRLAN...   %d - %d" % [_points[0], _points[1]]
	var kim := "ORTADA"
	if carrier != null:
		kim = carrier.char_name()
	var s := "MENDİL: %s      %s %d - %d %s" % [kim,
		duelists[0].char_name(), _points[0], _points[1], duelists[1].char_name()]
	if engaged:
		s += "\n\u25b6 KARŞILAŞMA!"
		var ins = _insan_duellocu()
		if ins != null:
			if ins == carrier:
				s += "\nKAÇAN:  W/S = yana KIR  •  [1] KAY  •  [2] DURAKLA  •  [3] ÇALIM"
				s += "\nSEÇTİĞİN: %s" % _hamle_adi(_eng_runner_move, true)
			else:
				s += "\nKOVALAYAN:  W/S = yana ATIL  •  [1] DÜZ atıl  •  boş bırak = BEKLE"
				var se := DuelEncounter.Kovalayan.POZISYON
				if _insan_ilk_hamle >= 0:
					se = _insan_ilk_hamle
				s += "\nSEÇTİĞİN: %s" % _hamle_adi(se, false)
	if _olay != "":
		s += "\n" + _olay
	return s

func _process(delta: float) -> void:
	if _game == null or not _game.round_active:
		return
	if _olay_t > 0.0:
		_olay_t -= delta
		if _olay_t <= 0.0:
			_olay = ""

	# Mendil HER DURUMDA taşıyanı izler — çözüm gösterimi sırasında da.
	# Aksi halde gösterim boyunca havada asılı kalıp sonra ortaya ışınlanıyordu
	# ("mendil yere düşüyor, sonra tekrar başına geliyor").
	if carrier != null and _mendil != null:
		_mendil.global_position = carrier.global_position + Vector3.UP * 1.45

	# Çözüm gösterimi: temas ya da ıska ekranda dursun, sonra sayı yazılsın.
	if _cozum_t > 0.0:
		_cozum_t -= delta
		for d in duelists:
			d.speed_mul = 0.0
		# Hamleyi GÖZLE GÖRÜLÜR yap: hedefe yumuşak kay.
		if _cozum_toplam > 0.0 and carrier != null:
			var k: float = clampf(1.0 - (_cozum_t / _cozum_toplam), 0.0, 1.0)
			var o = opponent_of(carrier)
			carrier.global_position = carrier.global_position.lerp(_hedef_kacan, k * 0.35)
			if o != null:
				o.global_position = o.global_position.lerp(_hedef_kov, k * 0.35)
		if _cozum_t <= 0.0:
			for d in duelists:
				d.speed_mul = 1.0
			if _bekleyen_sayi >= 0:
				var idx: int = _bekleyen_sayi
				_bekleyen_sayi = -1
				_score(idx, "temas")
		return
	if _resetting:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			_resetting = false
			_reset_timer = 0.0
		return

	if carrier != null and _mendil != null:
		_mendil.global_position = carrier.global_position + Vector3.UP * 1.45

	if practice:
		_try_grab()
		return

	if _recovery > 0.0:
		_recovery = maxf(0.0, _recovery - delta)

	_check_bluff_foul(delta)
	_try_grab()

	if carrier != null:
		_mendil_timer += delta
		if _mendil_timer > Cfg.MENDIL_TIMER:
			_olay_yaz("SÜRE DOLDU — mendil ortaya döndü")
			_begin_reset()
			return
		_hiz_ayarla()
		if engaged:
			_karsilasma(delta)
		else:
			_karsilasma_tetikle()
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
				_olay_yaz("FAUL: %s mendili almadan çemberde kaldı → sayı rakibin" % d.char_name())
				_score(1 - i, "blof")
				return
		else:
			_in_circle_t[i] = 0.0

func _try_grab() -> void:
	if carrier != null:
		return
	for d in duelists:
		# 3B mesafe: sadece x'e bakmak yanlıştı — yandan geçen de kapıyordu.
		var mp := Vector3(mendil_x(), d.global_position.y, 0.0)
		if d.global_position.distance_to(mp) <= Cfg.MENDIL_GRAB_R:
			carrier = d
			_olay_yaz("%s MENDİLİ KAPTI — çizgine koş!" % d.char_name())
			carrier.speed_mul = Cfg.MENDIL_CARRY_SPEED
			# Kaçış şeridi kapış anında gizlice seçilir; savunmacı sonra okur.
			_mendil_timer = 0.0
			_kacan_bot.rng.seed = randi()
			_kov_bot.rng.seed = randi()
			_kov_bot.reaction_delay = Cfg.DUEL_REACTION
			return

# Çemberde sonsuza kadar durulmaz: süre dolarsa mendil rakibe geçer.
func _check_score() -> void:
	if carrier == null:
		return
	if absf(carrier.global_position.x - home_x(carrier)) <= 0.4:
		_score(duelists.find(carrier), "kacis")

# --- KARŞILAŞMA (kaçış düellosu) ---

func _hiz_ayarla() -> void:
	var opp = opponent_of(carrier)
	if engaged:
		carrier.speed_mul = Cfg.ENGAGE_SLOWMO
		if opp != null:
			opp.speed_mul = Cfg.ENGAGE_SLOWMO
		return
	carrier.speed_mul = Cfg.MENDIL_CARRY_SPEED
	if opp != null:
		# Kovalayan daha hızlı: düz koşuyla kaçış imkânsız, düello mecburi.
		opp.speed_mul = 0.0 if _recovery > 0.0 else Cfg.MENDIL_CHASER_SPEED

func _karsilasma_tetikle() -> void:
	if in_circle(carrier) or _recovery > 0.0:
		return
	var opp = opponent_of(carrier)
	if opp == null:
		return
	if carrier.global_position.distance_to(opp.global_position) > Cfg.ENGAGE_RADIUS:
		return
	engaged = true
	_eng_t = 0.0
	encounters += 1
	# Kaçan hamlesini karşılaşmanın başında gizlice seçer; tell'i sonra görünür.
	_insan_hamle_t = -1.0
	_insan_ilk_hamle = -1
	_insan_kacan_secim = -1
	if carrier.is_bot:
		_eng_runner_move = _kacan_bot.sec()
	else:
		_eng_runner_move = DuelEncounter.Kacan.DURAKLAMA   # basmazsa fren
	_eng_tell = _tell_of(_eng_runner_move)

func _tell_of(m: int) -> float:
	match m:
		DuelEncounter.Kacan.KAYMA: return Cfg.TELL_SLIDE
		DuelEncounter.Kacan.DURAKLAMA: return Cfg.TELL_STUTTER
	return Cfg.TELL_JUKE

# KIRMA YANAL bir hamledir: koşu ekseni x, kırma ekseni z. Önce x'ten
# okuyordum, yani kovalarken ileri basan oyuncu "kırdı" sayılıyordu.
# Hamleler ayrı tuşlarda: niyet açık olsun, kazara blöf yapılmasın.
func _insan_kacan_hamle() -> int:
	var p: String = carrier.prefix
	if Input.is_action_pressed(p + "_m1"):
		return DuelEncounter.Kacan.KAYMA
	if Input.is_action_pressed(p + "_m2"):
		return DuelEncounter.Kacan.DURAKLAMA
	if Input.is_action_pressed(p + "_m3"):
		return DuelEncounter.Kacan.CALIM
	var m := Input.get_vector(p + "_left", p + "_right", p + "_up", p + "_down")
	if m.y < -0.4:
		return DuelEncounter.Kacan.KIRMA_SOL
	if m.y > 0.4:
		return DuelEncounter.Kacan.KIRMA_SAG
	return DuelEncounter.Kacan.DURAKLAMA

func _insan_kovalayan_hamle(p) -> Array:
	if Input.is_action_pressed(p.prefix + "_m1"):
		return [DuelEncounter.Kovalayan.LUNGE_DUZ, false]
	var m := Input.get_vector(p.prefix + "_left", p.prefix + "_right",
		p.prefix + "_up", p.prefix + "_down")
	if m.y < -0.4:
		return [DuelEncounter.Kovalayan.LUNGE_L, false]
	if m.y > 0.4:
		return [DuelEncounter.Kovalayan.LUNGE_R, false]
	return [DuelEncounter.Kovalayan.POZISYON, false]

func _karsilasma(delta: float) -> void:
	_eng_t += delta
	# İnsan kovalayan hamlesini NE ZAMAN verdi? Duraklamanın (blöfün) insana
	# karşı işlemesi buna bağlı: erken atılan blöfe yenilir, sabırlı olan yenmez.
	# İNSAN KAÇAN: pencere boyunca dinle, ilk gerçek basışı kilitle.
	if carrier != null and not carrier.is_bot and _insan_kacan_secim < 0:
		var sec_k: int = _insan_kacan_hamle()
		if sec_k != DuelEncounter.Kacan.DURAKLAMA:
			_insan_kacan_secim = sec_k
			_eng_runner_move = sec_k
			_eng_tell = _tell_of(sec_k)

	var opp0 = null
	if carrier != null:
		opp0 = opponent_of(carrier)
	if opp0 != null and not opp0.is_bot and _insan_hamle_t < 0.0:
		var h: Array = _insan_kovalayan_hamle(opp0)
		if h[0] != DuelEncounter.Kovalayan.POZISYON:
			_insan_hamle_t = _eng_t
			_insan_ilk_hamle = h[0]
	if _eng_t < Cfg.ENGAGE_WINDOW:
		return
	engaged = false
	var opp = opponent_of(carrier)
	if opp == null:
		return

	var hm: int
	var erken := false
	if opp.is_bot:
		var sec: Array = _kov_bot.sec(_eng_tell)
		hm = sec[0]
		erken = sec[1]
		# Tell'i okuyabildiyse doğru karşılık — ama garanti değil.
		if _eng_tell >= _kov_bot.reaction_delay and _kov_bot.rng.randf() < _kov_bot.read_accuracy:
			hm = DuelEncounter.dogru_karsilik(_eng_runner_move)
			erken = false
		_kov_bot.ogren(_eng_runner_move)
	else:
		var ins: Array = _insan_kovalayan_hamle(opp)
		hm = ins[0]
		# Pencerenin ilk yarısında atıldıysa ERKEN sayılır: duraklama onu yener.
		erken = _insan_hamle_t >= 0.0 and _insan_hamle_t < Cfg.ENGAGE_WINDOW * 0.5
		if _insan_hamle_t >= 0.0:
			if _insan_ilk_hamle >= 0:
				hm = _insan_ilk_hamle

	var sonuc: int = DuelEncounter.resolve(_eng_runner_move, hm, erken)
	# CALIM buraya eklenmemisti: her calim hamlesinde
	# "Out of bounds get index '4' (on base: 'Dictionary')" hatasi firliyordu.
	var ad := {
		DuelEncounter.Kacan.KIRMA_SOL: "SOLA KIRDI", DuelEncounter.Kacan.KIRMA_SAG: "SAĞA KIRDI",
		DuelEncounter.Kacan.KAYMA: "KAYDI", DuelEncounter.Kacan.DURAKLAMA: "DURAKLADI",
		DuelEncounter.Kacan.CALIM: "ÇALIM ATTI"}
	var kad := {
		DuelEncounter.Kovalayan.LUNGE_L: "SOLA ATILDI", DuelEncounter.Kovalayan.LUNGE_R: "SAĞA ATILDI",
		DuelEncounter.Kovalayan.LUNGE_DUZ: "DÜZ ATILDI", DuelEncounter.Kovalayan.POZISYON: "BEKLEDİ"}
	var sonuc_ad := {
		DuelEncounter.Sonuc.YAKALANDI: "YAKALANDI!",
		DuelEncounter.Sonuc.KACTI: "KAÇTI!", DuelEncounter.Sonuc.CEKISME: "çekişme"}
	_olay_yaz("%s %s  ↔  %s %s  →  %s" % [
		carrier.char_name(), ad[_eng_runner_move], opp.char_name(), kad[hm], sonuc_ad[sonuc]])
	match sonuc:
		DuelEncounter.Sonuc.YAKALANDI:
			# Kovalayan fiilen DOKUNUR: ekranda temas görünsün, sonra sayı.
			_hedef_kacan = carrier.global_position
			_hedef_kov = carrier.global_position + Vector3(
				signf(carrier.global_position.x - opp.global_position.x) * -0.7, 0, 0)
			_olay_yaz("DOKUNDU! %s yakaladı → sayı %s'in" % [opp.char_name(), opp.char_name()])
			_cozum_t = 0.9
			_cozum_toplam = 0.9
			if Cfg.MENDIL_MUTUAL_BURN:
				both_burned += 1
				_bekleyen_sayi = -1
				_begin_reset()
			else:
				_bekleyen_sayi = 1 - duelists.find(carrier)
		DuelEncounter.Sonuc.KACTI:
			escapes += 1
			# Kovalayan ıskalar: hamlesinin hızıyla kaçanın YANINDAN geçer.
			var yon: float = signf(home_x(carrier) - carrier.global_position.x)
			var mesafe := Cfg.JUKE_DIST
			if _eng_runner_move == DuelEncounter.Kacan.KAYMA:
				mesafe = Cfg.SLIDE_DIST
			_hedef_kacan = carrier.global_position + Vector3(
				yon * mesafe, 0, clampf(_ayril_yanal() * Cfg.JUKE_DIST * 0.6, -1.6, 1.6))
			_hedef_kov = opp.global_position + Vector3(
				signf(carrier.global_position.x - opp.global_position.x) * 1.8, 0,
				-signf(_ayril_yanal()) * 0.8)
			_olay_yaz("ISKA! %s geçti — çizgine koş!" % carrier.char_name())
			_cozum_t = 0.6
			_cozum_toplam = 0.6
			_recovery = Cfg.LUNGE_RECOVERY
		_:
			# Çekişme: küçük ayrılma, ikisi de yerinde durmasın
			var y2: float = signf(home_x(carrier) - carrier.global_position.x)
			_hedef_kacan = carrier.global_position + Vector3(y2 * 0.7, 0, 0)
			_hedef_kov = opp.global_position
			_cozum_t = 0.35
			_cozum_toplam = 0.35

func _ayril_yanal() -> float:
	if _eng_runner_move == DuelEncounter.Kacan.KIRMA_SOL:
		return -1.0
	if _eng_runner_move == DuelEncounter.Kacan.KIRMA_SAG:
		return 1.0
	if _eng_runner_move == DuelEncounter.Kacan.CALIM:
		return 1.0 if randf() < 0.5 else -1.0   # çalım: gösterdiğinin tersi
	return 0.0

# Kaçan mesafe kazanır; ıskalayan kovalayan toparlanır.
func _ayril(_opp, olcek := 1.0) -> void:
	var yon: float = signf(home_x(carrier) - carrier.global_position.x)
	var mesafe: float = Cfg.JUKE_DIST if _eng_runner_move != DuelEncounter.Kacan.KAYMA else Cfg.SLIDE_DIST
	carrier.global_position.x += yon * mesafe * olcek
	var yanal: float = 0.0
	if _eng_runner_move == DuelEncounter.Kacan.KIRMA_SOL:
		yanal = -Cfg.JUKE_DIST * 0.6
	elif _eng_runner_move == DuelEncounter.Kacan.KIRMA_SAG:
		yanal = Cfg.JUKE_DIST * 0.6
	carrier.global_position.z = clampf(carrier.global_position.z + yanal, -1.6, 1.6)
	if olcek >= 1.0:
		_recovery = Cfg.LUNGE_RECOVERY

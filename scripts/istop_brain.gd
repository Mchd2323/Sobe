class_name IstopBrain
extends RefCounted
# İstop bot beyni. Fazlara göre davranır; yeni çekirdek icat etmez:
#   KAÇIŞMA  -> dodge çekirdeğinin kaçış modu (çağırıcıdan ve duvardan uzak)
#   ÇAĞRILAN -> mevcut "topa koş"
#   DONMA    -> kıpırdamaz (bot her zaman uyar; zorluk tepki gecikmesinde)
#   ADIM     -> hedefe yaklaş (aim çekirdeğinin ilk kullanımı)

var player = null
var game = null
var round_ref = null
var move := Vector2.ZERO
var reaction := 0.12      # donma tepkisi: zorluk parametresi

var _don_gecikme := 0.0

func consume_action() -> bool:
	return false

func think(delta: float) -> void:
	move = Vector2.ZERO
	if round_ref == null or player == null:
		return

	match round_ref.faz:
		round_ref.Faz.KACISMA:
			_don_gecikme = reaction
			if round_ref.cagrilan == player:
				_topa_kos()
			else:
				_dagil()
		round_ref.Faz.DONMA:
			# Tepki gecikmesi kadar hâlâ hareket hâlinde olabilir (insanlık payı)
			if _don_gecikme > 0.0:
				_don_gecikme -= delta
				_dagil()
		round_ref.Faz.ADIM:
			if round_ref.topcu == player:
				_hedefe_yaklas()

func _topa_kos() -> void:
	var b = round_ref.top()
	if b == null:
		return
	var d: Vector3 = b.global_position - player.global_position
	move = Vector2(d.x, d.z).normalized()

func _dagil() -> void:
	# Çağırıcıdan uzaklaş, ama duvara sıkışma.
	var c = round_ref.cagirici
	if c == null:
		return
	var kac: Vector3 = player.global_position - c.global_position
	if kac.length() < 0.1:
		kac = Vector3(1, 0, 0)
	var hedef: Vector3 = player.global_position + kac.normalized() * 3.0
	hedef.x = clampf(hedef.x, -Cfg.FIELD_X + 1.0, Cfg.FIELD_X - 1.0)
	hedef.z = clampf(hedef.z, -Cfg.FIELD_Z + 1.0, Cfg.FIELD_Z - 1.0)
	var d: Vector3 = hedef - player.global_position
	move = Vector2(d.x, d.z).normalized()

func _hedefe_yaklas() -> void:
	var h = round_ref.en_yakin_hedef(player)
	if h == null:
		return
	var d: Vector3 = h.global_position - player.global_position
	if d.length() > 2.0:
		move = Vector2(d.x, d.z).normalized()

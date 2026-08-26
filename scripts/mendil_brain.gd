class_name MendilBrain
extends RefCounted
# Mendil kapmaca bot beyni (B1 v2). DuelBrain çekirdeğini yeni geometriye çevirir.
# Beyin arayüzü (BotBrain ile aynı): think(delta) + .move + consume_action()
#
# Dört durum var ve her biri farklı bir soru sorar:
#   1. Mendil bende, çemberdeyim   -> ne zaman çıkayım? (rakip yolumdan çekildi mi)
#   2. Mendil bende, dışarıdayım   -> eve koş
#   3. Mendil rakipte              -> kes (çembere GİRME, faul olur)
#   4. Mendil ortada               -> dal / blöf / bekle (DuelBrain karar verir)

var player = null
var game = null
var round_ref = null
var core := DuelBrain.new()
var move := Vector2.ZERO

func consume_action() -> bool:
	return false

func think(delta: float) -> void:
	move = Vector2.ZERO
	if round_ref == null or player == null:
		return
	var opp = round_ref.opponent_of(player)
	if opp == null:
		return

	var my_x: float = player.global_position.x
	var home: float = round_ref.home_x(player)
	var r: float = round_ref.circle_r()

	# 1-2) Mendil bende: doğrudan eve. Kovalayan daha hızlı olduğu için kaçış
	# düz koşuyla kazanılmaz; iş karşılaşmada (DuelEncounter) çözülür.
	if round_ref.carrier == player:
		_go(home)
		return

	# 3) Mendil rakipte: kesme noktasına git ama çembere girme (faul).
	if round_ref.carrier == opp:
		var kesme: float = opp.global_position.x + signf(round_ref.home_x(opp)) * 1.2
		if absf(kesme) < r + 0.25:
			kesme = signf(kesme) * (r + 0.25)   # çemberin dibinde bekle
		_go(kesme)   # kesme noktasına git; düello karşılaşmada çözülür
		return

	# 4) Mendil ortada: kararı çekirdek verir.
	var intent: int = core.think(delta, {
		"my_dist": absf(my_x),
		"opp_dist": absf(opp.global_position.x),
		"opp_committed": round_ref.is_committed(opp),
		"carrying": false,
		"home_dist": absf(my_x - home),
	})
	round_ref.report_intent(player, intent)
	match intent:
		DuelBrain.Intent.COMMIT:
			_go(round_ref.mendil_x())                      # doğrudan mendile
		DuelBrain.Intent.FEINT:
			_go(signf(my_x) * (r + Cfg.MENDIL_FEINT_STOP)) # sınıra yanaş, girme
		_:
			_go(signf(my_x) * (r + 0.9), 0.5)              # kolla

func _go(hedef: float, hiz := 1.0, hedef_z := 0.0) -> void:
	var dx: float = hedef - player.global_position.x
	var dz: float = hedef_z - player.global_position.z
	var v := Vector2(dx, dz)
	if v.length() > 0.06:
		move = v.normalized() * hiz

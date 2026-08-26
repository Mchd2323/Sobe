class_name MendilBrain
extends RefCounted
# Mendil kapmaca bot beyni: DuelBrain çekirdeğini oyuncu hareketine çevirir.
# Beyin arayüzü (BotBrain ile aynı): think(delta) + .move + consume_action()

var player = null
var game = null
var round_ref = null
var core := DuelBrain.new()
var move := Vector2.ZERO

func consume_action() -> bool:
	return false   # mendil kapmacada tuş yok: yaklaşınca otomatik kapılır

func think(delta: float) -> void:
	move = Vector2.ZERO
	if round_ref == null or player == null:
		return
	var opp = round_ref.opponent_of(player)
	if opp == null:
		return

	var mendil_x: float = round_ref.mendil_x()
	var intent: int = core.think(delta, {
		"my_dist": absf(player.global_position.x - mendil_x),
		"opp_dist": absf(opp.global_position.x - mendil_x),
		"opp_committed": round_ref.is_committed(opp),
		"carrying": round_ref.carrier == player,
		"home_dist": absf(player.global_position.x - round_ref.home_x(player)),
	})
	round_ref.report_intent(player, intent)

	var hedef := 0.0
	var hiz := 1.0
	match intent:
		DuelBrain.Intent.COMMIT:
			# Mendil rakipte ise onu kes; değilse mendile dal.
			hedef = opp.global_position.x if round_ref.carrier == opp else mendil_x
		DuelBrain.Intent.FEINT:
			hedef = mendil_x + signf(round_ref.home_x(player)) * Cfg.MENDIL_FEINT_STOP
			hiz = 0.7
		DuelBrain.Intent.RETREAT:
			hedef = round_ref.home_x(player)
		_:
			# BEKLE: eve kaçma, çizginin dibinde kolla. Düello burada başlar.
			hedef = mendil_x + signf(round_ref.home_x(player)) * Cfg.MENDIL_HOVER
			hiz = 0.5
	var dx: float = hedef - player.global_position.x
	if absf(dx) > 0.05:
		move = Vector2(signf(dx) * hiz, 0.0)

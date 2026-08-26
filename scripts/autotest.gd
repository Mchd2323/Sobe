extends Node
# SOBE — CI bot maçı testi.
# YALNIZ `--sobe-autotest` bayrağıyla yüklenir; bayrak yoksa bu dosya hiç okunmaz.
#
#   godot --headless --path . -- --sobe-autotest
#
# Çıktı: "SONUC: kazanan=<takım> sure=<sn>" + çıkış kodu 0
#        kilitlenirse "SONUC: KILITLENDI ..." + çıkış kodu 1

# Watchdog'un işi KİLİTLENMEYİ yakalamak, yavaş maçı cezalandırmak değil.
# Gerçek bir kilitlenme hiç bitmez; yavaş bir maç biter. Sınır, en uzun meşru
# maçın belirgin şekilde üstünde olmalı — yoksa CI tempo değişiminde yanlış alarm
# verir (120 sn sınırıyla tam da bu oldu: 116 sn'lik meşru maçlar sınıra dayandı).
const WATCHDOG := 180.0

var _game = null
var _elapsed := 0.0
var _done := false

func begin(game) -> void:
	_game = game
	# Tüm koltukları bota çevir: insan girdisi olmadan da maç yürüsün.
	for p in game.players:
		if not p.is_bot:
			p.is_bot = true
			var b := BotBrain.new()
			b.player = p
			b.game = game
			p.brain = b
	game.current_round.round_finished.connect(_on_finished)
	# Lobi → brifing → deneme atışı adımlarını atla, doğrudan maça gir.
	game.flow.call_deferred("skip_to_playing")

func _process(delta: float) -> void:
	if _done or _game == null or not _game.round_active:
		return
	_elapsed += delta
	if _elapsed > WATCHDOG:
		_done = true
		print("SONUC: KILITLENDI - %.0f sn'de bitmedi" % WATCHDOG)
		get_tree().quit(1)

func _on_finished(winner_team: int) -> void:
	if _done:
		return
	_done = true
	print("SONUC: kazanan=%d sure=%.1fs" % [winner_team, _elapsed])
	get_tree().quit(0)

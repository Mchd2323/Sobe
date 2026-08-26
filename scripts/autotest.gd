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
const MATCHES := 2        # A3: ardışık iki oyun koşulur, toplam misket doğrulanır

var _game = null
var _elapsed := 0.0
var _done := false
var _played := 0

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
	_played += 1
	var sb = _game.score_board
	print("SONUC: mac=%d kazanan=%d sure=%.1fs misket=%s" % [
		_played, winner_team, _elapsed, str(sb.marbles)])

	if _played < MATCHES:
		_elapsed = 0.0
		_game.flow.call_deferred("skip_to_playing")   # sonraki oyun
		return

	_done = true
	# Her oyun 4+2+1+0 = 7 misket dağıtır. İki oyun sonunda toplam 14 olmalı.
	var beklenen: int = 7 * MATCHES
	if sb.total() != beklenen or sb.games_played != MATCHES:
		print("SONUC: SKOR HATASI - toplam=%d (beklenen %d), oyun=%d" % [
			sb.total(), beklenen, sb.games_played])
		get_tree().quit(1)
	print("SONUC: SKOR OK - %d oyun, toplam %d misket" % [sb.games_played, sb.total()])
	get_tree().quit(0)

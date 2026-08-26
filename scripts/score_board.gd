class_name ScoreBoard
extends Node
# Misket ekonomisi (GDD §6): "her oyun sıralamaya göre misket dağıtır (4/2/1/0)".
# Skor oyunlar arası taşınır; turnuva boyunca biriken misket damgayı belirleyecek.

const AWARDS := [4, 2, 1, 0]

var marbles := [0, 0, 0, 0]
var games_played := 0
var last_award := [0, 0, 0, 0]

# ranking: en iyiden en kötüye sıralı oyuncu dizisi. Dönen: bu oyunda kimin kaç aldığı.
func award(ranking: Array) -> Array:
	last_award = [0, 0, 0, 0]
	for rank in range(ranking.size()):
		var pl = ranking[rank]
		var pts: int = AWARDS[rank] if rank < AWARDS.size() else 0
		marbles[pl.index] += pts
		last_award[pl.index] = pts
	games_played += 1
	return last_award

func total() -> int:
	var t := 0
	for m in marbles:
		t += m
	return t

func reset() -> void:
	marbles = [0, 0, 0, 0]
	last_award = [0, 0, 0, 0]
	games_played = 0

# Sıralama tablosu: en çok miskete göre.
func table_text(players: Array) -> String:
	var order := players.duplicate()
	order.sort_custom(func(a, b): return marbles[a.index] > marbles[b.index])
	var t := "SIRALAMA  (oyun %d)\n\n" % games_played
	for pl in order:
		t += "%-6s %s   %2d misket" % [pl.char_name(), Cfg.TEAM_NAMES[pl.team], marbles[pl.index]]
		if last_award[pl.index] > 0:
			t += "   (+%d)" % last_award[pl.index]
		t += "\n"
	return t

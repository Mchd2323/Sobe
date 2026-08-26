class_name GameFlow
extends Node
# SOBE akış makinesi (A1).
# LOBİ → BRİFİNG → DENEME ATIŞI → OYUN → SKOR
#
# Faz otoritesi burada; tur kuralları RoundBase'de kalır. Main yalnız fazı
# dinler ve arayüzü çizer. Yeni mini oyun eklemek bu akışı değiştirmez.

signal phase_changed(phase: int)

enum Phase { LOBBY, BRIEFING, PRACTICE, PLAYING, SCORE }

# Süre Cfg.PRACTICE_TIME'da (kanepede onaylandı).

var phase: int = Phase.LOBBY
var practice_left := 0.0

# LOBİ: hangi koltuklara insan oturdu. Boş kalanlar bot olur.
var joined := [false, false, false, false]

func join(seat: int) -> void:
	if seat >= 0 and seat < joined.size():
		joined[seat] = true

func joined_count() -> int:
	var n := 0
	for j in joined:
		if j:
			n += 1
	return n

func _process(delta: float) -> void:
	if phase != Phase.PRACTICE:
		return
	practice_left = maxf(0.0, practice_left - delta)
	if practice_left <= 0.0:
		set_phase(Phase.PLAYING)

# Oyuncu ATIŞ tuşuna bastı: bekleyen fazlarda ileri git.
func advance() -> void:
	match phase:
		Phase.LOBBY:
			set_phase(Phase.BRIEFING)
		Phase.BRIEFING:
			set_phase(Phase.PRACTICE)
		Phase.SCORE:
			set_phase(Phase.LOBBY)

# CI/otomatik test: lobi-brifing-deneme adımlarını atla.
func skip_to_playing() -> void:
	set_phase(Phase.PLAYING)

func set_phase(p: int) -> void:
	phase = p
	if p == Phase.PRACTICE:
		practice_left = Cfg.PRACTICE_TIME
	phase_changed.emit(p)

# Oyuncuların hareket edebildiği, turun döndüğü fazlar.
func is_live() -> bool:
	return phase == Phase.PRACTICE or phase == Phase.PLAYING

func phase_name() -> String:
	match phase:
		Phase.LOBBY: return "LOBİ"
		Phase.BRIEFING: return "BRİFİNG"
		Phase.PRACTICE: return "DENEME ATIŞI"
		Phase.PLAYING: return "OYUN"
		Phase.SCORE: return "SKOR"
	return "?"

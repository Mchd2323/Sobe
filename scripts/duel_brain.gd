class_name DuelBrain
extends RefCounted
# DUEL-AI ÇEKİRDEĞİ (A5) — mendil kapmaca / ruba bandiera ailesinin ortak beyni.
#
# Düellonun tamamı üç sayıdan ibarettir:
#   reaction_delay : rakibin hamlesini fark etme gecikmesi (insanlık payı)
#   bluff_chance   : dalıyormuş gibi yapıp geri çekilme olasılığı
#   commit_window  : bir kez daldıktan sonra kararlı kalma süresi
#
# Sahneden bağımsızdır: girdi bir Dictionary, çıktı bir niyet. Bu sayede
# oyunu çalıştırmadan, tohumla (deterministik) test edilebilir.
#
# Beklenen durum sözlüğü:
#   my_dist       : benim hedefe uzaklığım
#   opp_dist      : rakibin hedefe uzaklığı
#   opp_committed : rakip daldı mı
#   carrying      : hedef bende mi
#   home_dist     : kendi çizgime uzaklığım

enum Intent { WAIT, FEINT, COMMIT, RETREAT }

var reaction_delay := 0.35
var bluff_chance := 0.25
var commit_window := 0.9
var decision_period := 0.45

var _rng := RandomNumberGenerator.new()
var _intent: int = Intent.WAIT
var _intent_left := 0.0
var _until_decision := 0.0
var _opp_seen_at := -1.0
var _t := 0.0

# Aynı tohum = aynı düello. Testlerin tekrarlanabilir olması buna bağlı.
func seed_with(s: int) -> void:
	_rng.seed = s

func think(delta: float, state: Dictionary) -> int:
	_t += delta
	_intent_left = maxf(0.0, _intent_left - delta)
	_until_decision = maxf(0.0, _until_decision - delta)

	# 1) Mendil bende: soluğu kendi çizgimde al. Tartışmasız.
	if state.get("carrying", false):
		_intent = Intent.RETREAT
		return _intent

	# 2) Rakip daldı: tepki gecikmem dolduysa ben de dalarım (yakalamaya).
	if state.get("opp_committed", false):
		if _opp_seen_at < 0.0:
			_opp_seen_at = _t
		if _t - _opp_seen_at >= reaction_delay:
			_intent = Intent.COMMIT
			_intent_left = commit_window
			return _intent
	else:
		_opp_seen_at = -1.0

	# 3) Süren bir hamlenin ortasındaysam sözümde dururum (commit_window).
	if _intent_left > 0.0 and _intent != Intent.WAIT:
		return _intent

	# 4) Karar anı: blöf mü, dalış mı, bekleyiş mi?
	if _until_decision <= 0.0:
		_until_decision = decision_period
		var my_d: float = float(state.get("my_dist", 1.0))
		var opp_d: float = float(state.get("opp_dist", 1.0))
		if _rng.randf() < bluff_chance:
			_intent = Intent.FEINT
			_intent_left = commit_window * 0.4
		elif my_d <= opp_d:
			# Yakınsam dalmak mantıklı; fark açıldıkça cesaret artar.
			var avantaj: float = clampf((opp_d - my_d) / maxf(opp_d, 0.001), 0.0, 1.0)
			if _rng.randf() < 0.20 + 0.45 * avantaj:
				_intent = Intent.COMMIT
				_intent_left = commit_window
			else:
				_intent = Intent.WAIT
		else:
			_intent = Intent.WAIT
	return _intent

static func intent_name(i: int) -> String:
	match i:
		Intent.WAIT: return "BEKLE"
		Intent.FEINT: return "BLÖF"
		Intent.COMMIT: return "DAL"
		Intent.RETREAT: return "KAÇ"
	return "?"

extends Node
# B1 revizyonu doğrulaması: kaçış düellosu DENGELİ mi?
# Kart şartı: 16 deterministik düello, kaçış başarı oranı %35-65 bandında.
# YALNIZ --sobe-encountertest bayrağıyla yüklenir. Sahne gerektirmez.

const TELL := {
	DuelEncounter.Kacan.KIRMA_SOL: 0.12,
	DuelEncounter.Kacan.KIRMA_SAG: 0.12,
	DuelEncounter.Kacan.KAYMA: 0.18,
	DuelEncounter.Kacan.DURAKLAMA: 0.10,
	DuelEncounter.Kacan.CALIM: 0.15,      # çalımın tell'i orta: okunabilir ama zor
}
const MAX_EL := 8      # bu kadar çekişmeden sonra kovalayan (daha hızlı) yetişir

func _duello(tohum: int, reaction: float) -> int:
	var kacan := DuelEncounter.KacanBot.new()
	kacan.rng.seed = tohum
	var kov := DuelEncounter.KovalayanBot.new()
	kov.rng.seed = tohum * 7919 + 13
	kov.reaction_delay = reaction

	for el in range(MAX_EL):
		var km: int = kacan.sec()
		var tell: float = TELL[km]
		var sec: Array = kov.sec(tell)
		var hm: int = sec[0]
		var erken: bool = sec[1]
		# Tell'i okuyabildiyse doğru karşılığı verir — ama hep değil.
		if tell >= kov.reaction_delay and kov.rng.randf() < kov.read_accuracy:
			hm = DuelEncounter.dogru_karsilik(km)
			erken = false
		kov.ogren(km)
		var r: int = DuelEncounter.resolve(km, hm, erken)
		if r == DuelEncounter.Sonuc.KACTI:
			return 1
		if r == DuelEncounter.Sonuc.YAKALANDI:
			return 0
	return 0   # sürekli çekişme: hızlı olan kovalayan sonunda yetişir

func begin(_game) -> void:
	var ok := true

	# 1) Matris doğru mu? (elle birkaç kilit vaka)
	var K = DuelEncounter.Kacan
	var V = DuelEncounter.Kovalayan
	var S = DuelEncounter.Sonuc
	var vakalar := [
		[K.KIRMA_SOL, V.LUNGE_L, false, S.YAKALANDI, "sola kırmayı sol hamle yakalar"],
		[K.KIRMA_SOL, V.LUNGE_R, false, S.KACTI, "sola kırma sağ hamleden kaçar"],
		[K.KAYMA, V.LUNGE_DUZ, false, S.KACTI, "kayma düz hamlenin altından geçer"],
		[K.KAYMA, V.POZISYON, false, S.KACTI, "kayma dengeli duranı geçer"],
		[K.KAYMA, V.LUNGE_L, false, S.YAKALANDI, "yönlü hamle kaymayı yakalar"],
		[K.DURAKLAMA, V.LUNGE_DUZ, true, S.KACTI, "duraklama erken hamleyi boşa düşürür"],
		[K.DURAKLAMA, V.LUNGE_DUZ, false, S.CEKISME, "duraklama geç hamleyi boşa düşürmez"],
		[K.DURAKLAMA, V.POZISYON, false, S.YAKALANDI, "sabır frenleyeni YAKALAR"],
		[K.CALIM, V.LUNGE_L, false, S.KACTI, "çalım yana atılanı yener"],
		[K.CALIM, V.LUNGE_R, false, S.KACTI, "çalım öbür yana atılanı da yener"],
		[K.CALIM, V.LUNGE_DUZ, false, S.YAKALANDI, "düz giden çalıma kanmaz"],
		[K.CALIM, V.POZISYON, false, S.YAKALANDI, "sabırlı çalıma kanmaz"],
	]
	for v in vakalar:
		var g: int = DuelEncounter.resolve(v[0], v[1], v[2])
		if g != v[3]:
			print("[HATA] matris: %s (beklenen %d, çıkan %d)" % [v[4], v[3], g])
			ok = false
	print("[MATRIS] %d vaka kontrol edildi" % vakalar.size())

	# 2) DENGE KAPISI — varsayılan zorlukta kaçış oranı %35-65 bandında olmalı.
	# NOT: kart 16 düello diyordu ama bu istatistiksel olarak yetersiz.
	# Gerçek oran %51.5 iken 16 düello %75 gösterdi (12/16) — sırf gürültü.
	# %65 tavanını ayırt edebilmek için 400 düello kullanılıyor; saf mantık
	# olduğu için maliyeti yok.
	var VARSAYILAN := 0.17
	var kacis := 0
	for i in range(400):
		kacis += _duello(1000 + i * 37, VARSAYILAN)
	var oran: float = 100.0 * kacis / 400.0
	print("[DENGE] varsayilan zorluk (%.2f sn) -> kacis %%%.1f (400 duello)" % [VARSAYILAN, oran])
	if oran < 35.0 or oran > 65.0:
		print("[HATA] kacis orani %35-65 bandi disinda")
		ok = false

	# 2b) Zorluk parametresi CANLI mı? Yavaş bot daha çok kaçırmalı.
	var egri := []
	for reaction in [0.30, 0.17, 0.11]:
		var k := 0
		for i in range(400):
			k += _duello(90000 + i * 13, reaction)
		var o: float = 100.0 * k / 400.0
		egri.append(o)
		print("[ZORLUK] tepki %.2f sn -> kacis %%%.1f" % [reaction, o])
	if not (egri[0] > egri[1] and egri[1] > egri[2]):
		print("[HATA] zorluk parametresi olu: yavas bot daha cok kacirmali")
		ok = false

	# 3) Determinizm
	var a := _duello(4242, 0.28)
	var b := _duello(4242, 0.28)
	if a != b:
		print("[HATA] determinizm bozuk")
		ok = false
	print("[DETERMINIZM] ayni tohum -> ayni sonuc: TAMAM")

	print("[SONUC] KACIS DUELLOSU ", "GECTI" if ok else "KALDI")
	get_tree().quit(0 if ok else 1)

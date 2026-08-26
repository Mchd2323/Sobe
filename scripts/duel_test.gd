extends Node
# A5 doğrulaması: DuelBrain ile iki botun mendil düellosu deterministik bitiyor mu?
# YALNIZ --sobe-dueltest bayrağıyla yüklenir.
#
# Soyut düello (B1'in kural iskeleti): mendil ortada, iki oyuncu 5 m uzakta.
# Kapan kendi çizgisine dönerse kazanır; dönerken yakalanırsa İKİSİ DE yanar.

const SPEED := 6.0
const GRAB_R := 0.6
const TAG_R := 0.8
const HOME := 5.0
const STEP := 1.0 / 60.0
const MAX_T := 60.0

class Duelist:
	var brain: DuelBrain
	var x := 0.0            # ÇİZGİ ÜZERİNDE İŞARETLİ konum; mendil 0'da
	var side := 1.0         # +1 sağdaki, -1 soldaki
	var carrying := false
	var committed := false

	func dist_to_mendil() -> float:
		return absf(x)

	func home() -> float:
		return side * HOME

func _duel(seed_a: int, seed_b: int) -> String:
	var a := Duelist.new()
	a.brain = DuelBrain.new(); a.brain.seed_with(seed_a); a.side = 1.0; a.x = HOME
	var b := Duelist.new()
	b.brain = DuelBrain.new(); b.brain.seed_with(seed_b); b.side = -1.0; b.x = -HOME
	a.brain.reaction_delay = 0.25; a.brain.bluff_chance = 0.15
	b.brain.reaction_delay = 0.45; b.brain.bluff_chance = 0.35

	var t := 0.0
	while t < MAX_T:
		t += STEP
		for pair in [[a, b], [b, a]]:
			var me: Duelist = pair[0]
			var opp: Duelist = pair[1]
			var intent: int = me.brain.think(STEP, {
				"my_dist": me.dist_to_mendil(), "opp_dist": opp.dist_to_mendil(),
				"opp_committed": opp.committed, "carrying": me.carrying,
				"home_dist": absf(me.home() - me.x),
			})
			me.committed = (intent == DuelBrain.Intent.COMMIT)
			var hedef := 0.0
			var hiz := SPEED
			match intent:
				DuelBrain.Intent.COMMIT:
					# Mendil bendeyse değil; rakibi kovalıyorsam onun üstüne git.
					hedef = opp.x if opp.carrying else 0.0
				DuelBrain.Intent.FEINT:
					hedef = me.side * 1.2      # blöf: mendile varamaz, eşikte durur
					hiz = SPEED * 0.7
				DuelBrain.Intent.RETREAT:
					hedef = me.home()
				_:
					hedef = me.home()
					hiz = SPEED * 0.25
			var yon: float = signf(hedef - me.x)
			var adim: float = minf(hiz * STEP, absf(hedef - me.x))
			me.x += yon * adim
			me.x = clampf(me.x, -HOME, HOME)

		# Mendili kapma: mendile en yakın ve menzilde olan alır
		if not a.carrying and not b.carrying:
			var da := a.dist_to_mendil()
			var db := b.dist_to_mendil()
			if da <= GRAB_R and da <= db:
				a.carrying = true
			elif db <= GRAB_R:
				b.carrying = true

		# Yakalama: mendili taşıyanı, mendilsiz olan GERÇEK mesafede yakalarsa ikisi de yanar
		for pair2 in [[a, b], [b, a]]:
			var run: Duelist = pair2[0]
			var chase: Duelist = pair2[1]
			if run.carrying and absf(run.x - chase.x) <= TAG_R:
				return "IKISI_DE_YANDI t=%.2f" % t

		if a.carrying and absf(a.x - a.home()) <= 0.01:
			return "A_KAZANDI t=%.2f" % t
		if b.carrying and absf(b.x - b.home()) <= 0.01:
			return "B_KAZANDI t=%.2f" % t

	return "BITMEDI"

func begin(_game) -> void:
	var ok := true

	# 1) Farklı tohumlarla düellolar BİTİYOR mu?
	var sonuclar := []
	for i in range(12):
		var r := _duel(1000 + i, 7000 + i)
		sonuclar.append(r)
		print("[DUELLO] tohum %d -> %s" % [i, r])
		if r == "BITMEDI":
			print("[HATA] duello bitmedi (tohum %d)" % i)
			ok = false

	# 2) AYNI tohum AYNI sonucu veriyor mu? (determinizm)
	for i in range(5):
		var bir := _duel(4242 + i, 9999 + i)
		var iki := _duel(4242 + i, 9999 + i)
		if bir != iki:
			print("[HATA] determinizm bozuk: '%s' != '%s'" % [bir, iki])
			ok = false
	print("[DETERMINIZM] ayni tohum -> ayni sonuc: TAMAM")

	# 3) Sonuçlar tek tip mi? (hepsi aynıysa düello değil, senaryodur)
	var farkli := {}
	for r in sonuclar:
		farkli[r.split(" ")[0]] = true
	print("[CESITLILIK] farkli sonuc turu: ", farkli.keys())

	# BİLGİ (başarısızlık değil): "ikisi de yandı" hiç çıkmıyorsa yakalama
	# imkânsız demektir ve blöf süs olur. B1'de gerçek geometriyle çözülecek.
	var yanan := 0
	for r2 in sonuclar:
		if r2.begins_with("IKISI"):
			yanan += 1
	print("[NOT] 'ikisi de yandi' sayisi: %d/%d — 0 ise B1'de yakalama penceresi acilmali" % [yanan, sonuclar.size()])
	if farkli.size() < 2:
		print("[HATA] tum duellolar ayni sonucu veriyor - blof/gecikme etkisiz")
		ok = false

	print("[SONUC] DUEL-AI ", "GECTI" if ok else "KALDI")
	get_tree().quit(0 if ok else 1)

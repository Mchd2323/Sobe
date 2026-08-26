extends Node
# A4 doğrulaması: brifing modülü hem tek rollü (yakan top) hem 1v3 (ebe/koşucu)
# turları çizebiliyor mu? YALNIZ --sobe-briefingtest bayrağıyla yüklenir.
#
#   godot --headless --path . -- --sobe-briefingtest

# Daruma-san'ın (D3) yerine geçen sahte tur: yalnız sözleşmeyi doldurur.
class StubEbeRound extends RoundBase:
	func get_hakem_line() -> String:
		return "Ebe döner. Kımıldayan yanar."

	func get_roles() -> Array:
		return ["ebe", "koşucu"]

	func get_rule_card(role: String = "") -> Dictionary:
		if role == "ebe":
			return {
				"amac": "AMAÇ: Dönünce KIMILDAYANI yakala.",
				"yanma": "YANMA: Kimseyi yakalayamadan çizgiye varılırsa sen yanarsın.",
				"siddet": "ŞİDDET: 🔵 Temassız.",
			}
		return {
			"amac": "AMAÇ: Ebeye DOKUN.",
			"yanma": "YANMA: Ebe dönerken kımıldarsan zincire girersin.",
			"siddet": "ŞİDDET: 🔵 Temassız — zinciri keserek arkadaşını kurtar.",
		}

func begin(game) -> void:
	var ok := true

	# 1) Tek rollü tur: rol başlığı ÇIKMAMALI
	var tek: String = Briefing.render(game.current_round)
	print("--- TEK ROL (yakan top) ---\n" + tek)
	if tek.find("—") != -1 and tek.find("HAKEM") == -1:
		print("[HATA] tek rollu turda rol basligi var"); ok = false
	if tek.find("HAKEM:") == -1:
		print("[HATA] Hakem satiri yok"); ok = false
	if tek.find("YAK") == -1:
		print("[HATA] amac satiri yok"); ok = false

	# 2) İki rollü tur: HER İKİ kart da çıkmalı ve metinleri FARKLI olmalı
	var stub := StubEbeRound.new()
	var cift: String = Briefing.render(stub)
	print("--- IKI ROL (sahte 1v3) ---\n" + cift)
	for beklenen in ["— EBE —", "— KOŞUCU —", "KIMILDAYANI", "Ebeye DOKUN"]:
		if cift.find(beklenen) == -1:
			print("[HATA] eksik: %s" % beklenen); ok = false
	if stub.get_rule_card("ebe")["amac"] == stub.get_rule_card("koşucu")["amac"]:
		print("[HATA] iki rolun karti ayni"); ok = false
	stub.free()

	print("[SONUC] BRIFING ", "GECTI" if ok else "KALDI")
	get_tree().quit(0 if ok else 1)

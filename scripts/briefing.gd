class_name Briefing
extends RefCounted
# Brifing modülü (A4) — GDD §6 "Brifing standardı".
#
# Kural Karesi ROL BAZLIDIR: 1v3 formatında ebenin kartı koşucununkinden farklıdır.
# Tek rollü oyunlar (yakan top) tek kart döndürür, hiçbir şey değişmez.
#
# Tur şu üçünü doldurur:
#   get_hakem_line()          -> Hakem'in ölü sesli tek cümlesi
#   get_roles()               -> bu turdaki roller ("" = tek rol)
#   get_rule_card(role)       -> o role ait AMAÇ / YANMA / ŞİDDET
#
# Bu sınıf sahneden bağımsızdır: test edilebilmesi için saf metin üretir.

const CARD_KEYS := ["amac", "yanma", "siddet"]

static func render(tur) -> String:
	var out := ""
	var hakem: String = str(tur.get_hakem_line())
	if hakem != "":
		out += "HAKEM: %s\n\n" % hakem

	var roles: Array = tur.get_roles()
	if roles.is_empty():
		roles = [""]

	for role in roles:
		var card: Dictionary = tur.get_rule_card(role)
		if roles.size() > 1:
			out += "— %s —\n" % str(role).to_upper()
		for key in CARD_KEYS:
			var line: String = str(card.get(key, ""))
			if line != "":
				out += line + "\n"
		out += "\n"
	return out.strip_edges()

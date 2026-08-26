class_name DuelEncounter
extends RefCounted
# KAÇIŞ DÜELLOSU ÇEKİRDEĞİ (B1 revizyonu — tasarım kartı).
#
# Kovalamacayı pozisyon savaşından OKUMA savaşına çevirir. Sahneden tamamen
# bağımsızdır: girdi iki hamle, çıktı bir sonuç. Bu sayede denge (kaçış oranı)
# 3B'ye hiç bağlanmadan ölçülebilir.
#
# İLKE (proje geneli): hiçbir kovalamaca saf 1B bırakılmaz. Tek eksende
# kovalayan ya hep yakalar ya hiç yakalayamaz — ara yoktur. Yanal blöf katmanı
# mendil, bulldog ve patintero için de şarttır.
#
# ÇÖZÜM MATRİSİ
#              LUNGE_L  LUNGE_R  LUNGE_DUZ  POZISYON
#   KIRMA_SOL   YAKALA   kaçar    kaçar      çekişme
#   KIRMA_SAG   kaçar    YAKALA   kaçar      çekişme
#   KAYMA       YAKALA   YAKALA   kaçar      kaçar     (düz hamlenin altından)
#   DURAKLAMA   kaçar*   kaçar*   kaçar*     çekişme   (*erken hamle boşa düşer)
#
# ÇEKİŞME = ne yakalama ne kaçış; karşılaşma yeniden kurulur, süre işler.

enum Kacan { KIRMA_SOL, KIRMA_SAG, KAYMA, DURAKLAMA }
enum Kovalayan { LUNGE_L, LUNGE_R, LUNGE_DUZ, POZISYON }
enum Sonuc { YAKALANDI, KACTI, CEKISME }

static func resolve(kacan: int, kovalayan: int, hamle_erken: bool) -> int:
	# DURAKLAMA yalnız ERKEN yapılmış hamleyi boşa düşürür.
	if kacan == Kacan.DURAKLAMA:
		if kovalayan == Kovalayan.POZISYON:
			return Sonuc.CEKISME
		return Sonuc.KACTI if hamle_erken else Sonuc.CEKISME

	if kacan == Kacan.KAYMA:
		if kovalayan == Kovalayan.LUNGE_DUZ or kovalayan == Kovalayan.POZISYON:
			return Sonuc.KACTI          # altından geçer / dengeli duranı geçer
		return Sonuc.YAKALANDI          # yönlü hamle kaymayı yakalar

	# KIRMA: yalnız aynı yöne yapılan hamle yakalar
	if kovalayan == Kovalayan.POZISYON:
		return Sonuc.CEKISME
	if kacan == Kacan.KIRMA_SOL and kovalayan == Kovalayan.LUNGE_L:
		return Sonuc.YAKALANDI
	if kacan == Kacan.KIRMA_SAG and kovalayan == Kovalayan.LUNGE_R:
		return Sonuc.YAKALANDI
	return Sonuc.KACTI

# --- Kaçan botu: dağılım + alışkanlık izleme ---
class KacanBot:
	var rng := RandomNumberGenerator.new()
	var _son := -1
	var _ust_uste := 0

	func sec() -> int:
		var m: int = rng.randi_range(0, 3)
		# Kendi alışkanlığını kır: aynı hamleyi üçüncü kez yapma (okunur).
		if m == _son:
			_ust_uste += 1
			if _ust_uste >= 2:
				m = (m + 1 + rng.randi_range(0, 2)) % 4
				_ust_uste = 0
		else:
			_ust_uste = 0
		_son = m
		return m

# --- Kovalayan botu: tell'i gecikmeyle okur, yetişemezse alışkanlıktan tahmin ---
class KovalayanBot:
	var rng := RandomNumberGenerator.new()
	var reaction_delay := 0.17       # zorluk parametresi (tell'lerin etrafında)
	# Tell'i okumak AVANTAJ olmalı, garanti değil. %100 okuma kusursuz karşılık
	# demek olur ve hızlı bot düelloyu bitirir (ölçüm: 0.11 sn'de kaçış %8.8).
	var read_accuracy := 0.8
	var _gecmis := [0, 0, 0, 0]     # rakibin hamle alışkanlığı

	func sec(tell_suresi: float) -> Array:
		# tell_suresi: hamlenin tell'i ne kadar süre görünür kaldı.
		var okudu: bool = tell_suresi >= reaction_delay
		var erken := false
		var m: int
		if okudu:
			m = Kovalayan.LUNGE_DUZ   # doğru karşılık dışarıdan verilir
		else:
			# Okuyamadı: alışkanlığa göre tahmin, biraz da sabır.
			if rng.randf() < 0.25:
				m = Kovalayan.POZISYON
			else:
				m = _tahmin()
				erken = rng.randf() < 0.5   # erken atılma riski
		return [m, erken]

	# Alışkanlık okuma ORANLA yapılır, argmax'la değil.
	# argmax dejenere: sayaçlar 517/483/498/502 iken %1'lik fark botu sonsuza
	# kadar aynı yöne atılmaya kilitliyordu (ölçüm: 1779 hamlenin 1223'ü sola,
	# 23'ü sağa). Oranla seçim hem sömürür hem tahmin edilemez kalır.
	func _tahmin() -> int:
		var agirlik := []
		var toplam := 0.0
		for i in range(4):
			var w: float = 1.0 + float(_gecmis[i])   # +1 yumuşatma
			agirlik.append(w)
			toplam += w
		var r: float = rng.randf() * toplam
		var secilen := 0
		for i in range(4):
			r -= agirlik[i]
			if r <= 0.0:
				secilen = i
				break
		match secilen:
			DuelEncounter.Kacan.KIRMA_SOL: return Kovalayan.LUNGE_L
			DuelEncounter.Kacan.KIRMA_SAG: return Kovalayan.LUNGE_R
			DuelEncounter.Kacan.KAYMA: return Kovalayan.LUNGE_L if rng.randf() < 0.5 else Kovalayan.LUNGE_R
		return Kovalayan.LUNGE_DUZ

	func ogren(kacan_hamle: int) -> void:
		_gecmis[kacan_hamle] += 3
		# Eski alışkanlık solar: rakip taktik değiştirirse bot da değişsin.
		for i in range(4):
			_gecmis[i] = maxi(0, _gecmis[i] - 1)

# Okunan hamleye doğru karşılık (tell yakalandığında kullanılır).
static func dogru_karsilik(kacan: int) -> int:
	match kacan:
		Kacan.KIRMA_SOL: return Kovalayan.LUNGE_L
		Kacan.KIRMA_SAG: return Kovalayan.LUNGE_R
		Kacan.KAYMA: return Kovalayan.LUNGE_L      # yönlü hamle kaymayı yakalar
		Kacan.DURAKLAMA: return Kovalayan.POZISYON # sabır duraklamayı boşa çıkarır
	return Kovalayan.LUNGE_DUZ

class_name RoundBase
extends Node
# SOBE tur sözleşmesi (IRound).
# Main YALNIZCA bu arayüzü bilir ve çağırır. Tur-özel metod çağrısı yasak.

signal round_finished(winner_team: int)  # -1 = berabere

# DENEME ATIŞI (GDD §6: "20 sn ölümsüz deneme, düdük"). Kurallar işler, kimse yanmaz.
# Akış makinesi (GameFlow) açıp kapatır; kuralı uygulamak turun işidir.
var practice := false

# Kural Karesi: 3 satır, fiil-önce. Sığmıyorsa oyun sadeleştirilir.
# ROL BAZLI (A4): 1v3'te ebenin kartı koşucununkinden farklıdır.
func get_rule_card(_role: String = "") -> Dictionary:
	return {"amac": "", "yanma": "", "siddet": ""}

# Bu turdaki roller. Tek rollü oyunlar [""] döner.
func get_roles() -> Array:
	return [""]

# Hakem'in ölü sesli anlatımı (GDD §6). Tek cümle.
func get_hakem_line() -> String:
	return ""

func setup(_players: Array, _root: Node3D) -> void:
	pass

func start() -> void:
	pass

# Oyuncunun izin verilen alanı: Vector4(x_min, x_max, z_min, z_max)
func get_bounds(_player) -> Vector4:
	return Vector4(-Cfg.FIELD_X, Cfg.FIELD_X, -Cfg.FIELD_Z, Cfg.FIELD_Z)

# --- Olay kancaları (Main bunları yönlendirir; tur isterse doldurur) ---

func on_player_hit(_player, _ball) -> void:
	pass

func on_catch(_catcher, _ball) -> void:
	pass

# Top ortaya döndü (sayışma başlatılabilir).
func on_ball_reset(_ball) -> void:
	pass

# Süren sayışmanın kalan saniyesi; sayışma yoksa -1.
func get_countdown() -> float:
	return -1.0

# Misket dağıtımı için oyun sonu sıralaması: en iyiden en kötüye oyuncu dizisi.
# Her tur kendi sıralama ölçütünü tanımlar (2v2'de takım sonucu, FFA'da bitiş sırası).
func get_ranking() -> Array:
	return []

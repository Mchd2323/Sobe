class_name RoundBase
extends Node
# SOBE tur sözleşmesi (IRound).
# Main YALNIZCA bu arayüzü bilir ve çağırır. Tur-özel metod çağrısı yasak.

signal round_finished(winner_team: int)  # -1 = berabere

# Kural Karesi: 3 satır, fiil-önce. Sığmıyorsa oyun sadeleştirilir.
func get_rule_card() -> Dictionary:
	return {"amac": "", "yanma": "", "siddet": ""}

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

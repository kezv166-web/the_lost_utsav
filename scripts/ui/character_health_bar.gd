extends Control

@onready var texture_rect: TextureRect = $BarTexture

var tex_1_full = preload("res://assets/character/health_bar/processed/char_bar_1_full.png")
var tex_2_high = preload("res://assets/character/health_bar/processed/char_bar_2_high.png")
var tex_3_mid = preload("res://assets/character/health_bar/processed/char_bar_3_mid.png")
var tex_4_half = preload("res://assets/character/health_bar/processed/char_bar_4_half.png")
var tex_5_low = preload("res://assets/character/health_bar/processed/char_bar_5_low.png")
var tex_6_critical = preload("res://assets/character/health_bar/processed/char_bar_6_critical.png")
var tex_7_defeated = preload("res://assets/character/health_bar/processed/char_bar_7_defeated.png")

var max_hp: int = 3
var current_hp: int = 3

func _ready() -> void:
	if texture_rect:
		texture_rect.texture = tex_1_full
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func set_player(player_node: Node) -> void:
	if not player_node:
		return
	if "max_health" in player_node:
		max_hp = player_node.max_health
	if "health" in player_node:
		current_hp = player_node.health
		
	if player_node.has_signal("health_changed"):
		player_node.health_changed.connect(update_health)
	if player_node.has_signal("player_damaged"):
		player_node.player_damaged.connect(func(hp): update_health(hp, max_hp))
	if player_node.has_signal("player_died"):
		player_node.player_died.connect(func(): update_health(0, max_hp))
		
	update_health(current_hp, max_hp)

func update_health(hp: int, max_val: int = -1) -> void:
	var prev_hp = current_hp
	current_hp = hp
	if max_val > 0:
		max_hp = max_val
	var ratio = clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	
	var chosen_tex = tex_1_full
	if ratio >= 0.90:
		chosen_tex = tex_1_full
	elif ratio >= 0.72:
		chosen_tex = tex_2_high
	elif ratio >= 0.54:
		chosen_tex = tex_3_mid
	elif ratio >= 0.36:
		chosen_tex = tex_4_half
	elif ratio >= 0.18:
		chosen_tex = tex_5_low
	elif ratio > 0.0:
		chosen_tex = tex_6_critical
	else:
		chosen_tex = tex_7_defeated
		
	if texture_rect:
		texture_rect.texture = chosen_tex
		
	# Damage punch feedback if hp decreased
	if current_hp < prev_hp:
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.06)
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
		if texture_rect:
			tw.parallel().tween_property(texture_rect, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.08)
			tw.tween_property(texture_rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)

extends Control

@onready var texture_rect: TextureRect = $BarTexture

var tex_full = preload("res://assets/asur/heath-bar/processed/asur_bar_1_full.png")
var tex_high = preload("res://assets/asur/heath-bar/processed/asur_bar_2_high.png")
var tex_mid = preload("res://assets/asur/heath-bar/processed/asur_bar_3_mid.png")
var tex_low = preload("res://assets/asur/heath-bar/processed/asur_bar_4_low.png")
var tex_critical = preload("res://assets/asur/heath-bar/processed/asur_bar_5_critical.png")
var tex_defeated = preload("res://assets/asur/heath-bar/processed/asur_bar_6_defeated.png")
var tex_damage = preload("res://assets/asur/heath-bar/processed/asur_bar_7_damage.png")

var max_hp: int = 5
var current_hp: int = 5
var is_flashing_damage: bool = false
var flash_timer: float = 0.0
var target_tex: Texture2D = null

func _ready() -> void:
	target_tex = tex_full
	if texture_rect:
		texture_rect.texture = tex_full
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func set_boss(asur_node: Node) -> void:
	if not asur_node:
		return
	if "max_health" in asur_node:
		max_hp = asur_node.max_health
	if "health" in asur_node:
		current_hp = asur_node.health
	
	if asur_node.has_signal("boss_damaged"):
		asur_node.boss_damaged.connect(_on_boss_damaged)
	if asur_node.has_signal("boss_defeated"):
		asur_node.boss_defeated.connect(_on_boss_defeated)
		
	update_health(current_hp, max_hp)

func _process(delta: float) -> void:
	if is_flashing_damage:
		flash_timer -= delta
		if flash_timer <= 0.0:
			is_flashing_damage = false
			if texture_rect and target_tex:
				texture_rect.texture = target_tex

func _on_boss_damaged(new_hp: int) -> void:
	current_hp = new_hp
	_trigger_damage_feedback()
	update_health(current_hp, max_hp)

func _trigger_damage_feedback() -> void:
	is_flashing_damage = true
	flash_timer = 0.18
	if texture_rect:
		texture_rect.texture = tex_damage
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector2(1.05, 1.05), 0.06)
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)

func update_health(hp: int, max_val: int) -> void:
	current_hp = hp
	max_hp = max(1, max_val)
	var ratio = float(current_hp) / float(max_hp)
	
	if ratio >= 0.85:
		target_tex = tex_full
	elif ratio >= 0.65:
		target_tex = tex_high
	elif ratio >= 0.45:
		target_tex = tex_mid
	elif ratio >= 0.20:
		target_tex = tex_low
	elif ratio > 0.0:
		target_tex = tex_critical
	else:
		target_tex = tex_defeated
		
	if not is_flashing_damage and texture_rect:
		texture_rect.texture = target_tex

func _on_boss_defeated() -> void:
	is_flashing_damage = false
	target_tex = tex_defeated
	if texture_rect:
		texture_rect.texture = tex_defeated
		var tw = create_tween()
		tw.tween_interval(3.0)
		tw.tween_property(self, "modulate:a", 0.0, 1.5)

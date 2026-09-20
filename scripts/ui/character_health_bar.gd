extends Control

@onready var texture_rect: TextureRect = $BarTexture

var tex_1_full = preload("res://assets/character/health_bar/processed/char_bar_1_full.png")
var tex_2_high = preload("res://assets/character/health_bar/processed/char_bar_2_high.png")
var tex_3_mid = preload("res://assets/character/health_bar/processed/char_bar_3_mid.png")
var tex_4_half = preload("res://assets/character/health_bar/processed/char_bar_4_half.png")
var tex_5_low = preload("res://assets/character/health_bar/processed/char_bar_5_low.png")
var tex_6_critical = preload("res://assets/character/health_bar/processed/char_bar_6_critical.png")
var tex_7_defeated = preload("res://assets/character/health_bar/processed/char_bar_7_defeated.png")

var max_hp: int = 250
var current_hp: int = 250
var displayed_hp: float = 250.0
var hp_label: Label = null
var anim_tween: Tween = null

func _ready() -> void:
	if texture_rect:
		texture_rect.texture = tex_1_full
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	hp_label = get_node_or_null("HPText")
	if not hp_label:
		hp_label = Label.new()
		hp_label.name = "HPText"
		hp_label.position = Vector2(8, 48)
		hp_label.add_theme_font_size_override("font_size", 14)
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
		hp_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.04, 0.95))
		hp_label.add_theme_constant_override("outline_size", 4)
		add_child(hp_label)
	_update_text()

func _process(_delta: float) -> void:
	if hp_label:
		hp_label.text = "HP: %d / %d" % [int(round(displayed_hp)), max_hp]

func set_player(player_node: Node) -> void:
	if not player_node:
		return
	if "max_health" in player_node:
		max_hp = player_node.max_health
	if "health" in player_node:
		current_hp = player_node.health
		displayed_hp = float(current_hp)
		
	if player_node.has_signal("health_changed"):
		player_node.health_changed.connect(func(h): update_health(h, max_hp))
	if player_node.has_signal("player_damaged"):
		player_node.player_damaged.connect(func(hp): update_health(hp, max_hp))
	if player_node.has_signal("player_died"):
		player_node.player_died.connect(func(): update_health(0, max_hp))
		
	update_health(current_hp, max_hp)

func _update_text() -> void:
	if hp_label:
		hp_label.text = "HP: %d / %d" % [int(round(displayed_hp)), max_hp]

func update_health(hp: int, max_val: int = 250) -> void:
	var prev_hp = current_hp
	current_hp = hp
	max_hp = max(1, max_val)
	var ratio = float(current_hp) / float(max_hp)
	
	var chosen_tex = tex_1_full
	if ratio >= 0.86:
		chosen_tex = tex_1_full
	elif ratio >= 0.70:
		chosen_tex = tex_2_high
	elif ratio >= 0.52:
		chosen_tex = tex_3_mid
	elif ratio >= 0.35:
		chosen_tex = tex_4_half
	elif ratio >= 0.18:
		chosen_tex = tex_5_low
	elif ratio > 0.0:
		chosen_tex = tex_6_critical
	else:
		chosen_tex = tex_7_defeated

	# Smooth ticker animation for numeric text
	if anim_tween:
		anim_tween.kill()
	anim_tween = create_tween().set_parallel(true)
	anim_tween.tween_property(self, "displayed_hp", float(current_hp), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Smooth crossfade/swap if texture stage changes
	if texture_rect and texture_rect.texture != chosen_tex:
		anim_tween.tween_property(texture_rect, "modulate:a", 0.6, 0.08)
		anim_tween.chain().tween_callback(func():
			if texture_rect:
				texture_rect.texture = chosen_tex
		)
		anim_tween.tween_property(texture_rect, "modulate:a", 1.0, 0.14)
	elif texture_rect:
		texture_rect.texture = chosen_tex
		
	# Damage punch feedback with smooth elastic easing
	if current_hp < prev_hp:
		anim_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		anim_tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if texture_rect:
			anim_tween.tween_property(texture_rect, "modulate", Color(2.4, 0.5, 0.5, 1.0), 0.08)
			anim_tween.chain().tween_property(texture_rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.20)

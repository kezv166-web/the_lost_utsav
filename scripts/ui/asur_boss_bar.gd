extends Control

@onready var texture_rect: TextureRect = $BarTexture

var tex_full = preload("res://assets/asur/heath-bar/processed/asur_bar_1_full.png")
var tex_high = preload("res://assets/asur/heath-bar/processed/asur_bar_2_high.png")
var tex_mid = preload("res://assets/asur/heath-bar/processed/asur_bar_3_mid.png")
var tex_low = preload("res://assets/asur/heath-bar/processed/asur_bar_4_low.png")
var tex_critical = preload("res://assets/asur/heath-bar/processed/asur_bar_5_critical.png")
var tex_defeated = preload("res://assets/asur/heath-bar/processed/asur_bar_6_defeated.png")
var tex_damage = preload("res://assets/asur/heath-bar/processed/asur_bar_7_damage.png")

var max_hp: int = 1000
var current_hp: int = 1000
var displayed_hp: float = 1000.0
var target_tex: Texture2D = null
var hp_label: Label = null
var anim_tween: Tween = null

func _ready() -> void:
	target_tex = tex_full
	if texture_rect:
		texture_rect.texture = tex_full
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	hp_label = get_node_or_null("BossHPText")
	if not hp_label:
		hp_label = Label.new()
		hp_label.name = "BossHPText"
		hp_label.anchor_right = 1.0
		hp_label.offset_top = -24.0
		hp_label.offset_bottom = 0.0
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 15)
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 1.0))
		hp_label.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.04, 0.95))
		hp_label.add_theme_constant_override("outline_size", 4)
		add_child(hp_label)
	_update_text()

func _process(_delta: float) -> void:
	if hp_label:
		hp_label.text = "ASUR: %d / %d HP" % [int(round(displayed_hp)), max_hp]

func _update_text() -> void:
	if hp_label:
		hp_label.text = "ASUR: %d / %d HP" % [int(round(displayed_hp)), max_hp]

func set_boss(asur_node: Node) -> void:
	if not asur_node:
		return
	if "max_health" in asur_node:
		max_hp = asur_node.max_health
	if "health" in asur_node:
		current_hp = asur_node.health
		displayed_hp = float(current_hp)
	
	if asur_node.has_signal("boss_damaged"):
		asur_node.boss_damaged.connect(_on_boss_damaged)
	if asur_node.has_signal("boss_defeated"):
		asur_node.boss_defeated.connect(_on_boss_defeated)
		
	update_health(current_hp, max_hp)

func _on_boss_damaged(new_hp: int) -> void:
	update_health(new_hp, max_hp)

func update_health(hp: int, max_val: int) -> void:
	var prev_hp = current_hp
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

	if anim_tween:
		anim_tween.kill()
	anim_tween = create_tween().set_parallel(true)
	
	# Smooth numeric ticker
	anim_tween.tween_property(self, "displayed_hp", float(current_hp), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Damage punch & texture flash
	if current_hp < prev_hp:
		anim_tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		anim_tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if texture_rect:
			texture_rect.texture = tex_damage
			anim_tween.tween_property(texture_rect, "modulate", Color(2.5, 1.3, 0.6, 1.0), 0.06)
			anim_tween.chain().tween_callback(func():
				if texture_rect and target_tex:
					texture_rect.texture = target_tex
			)
			anim_tween.tween_property(texture_rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.22)
	elif texture_rect:
		texture_rect.texture = target_tex

func _on_boss_defeated() -> void:
	target_tex = tex_defeated
	if texture_rect:
		texture_rect.texture = tex_defeated
		var tw = create_tween()
		tw.tween_interval(3.0)
		tw.tween_property(self, "modulate:a", 0.0, 1.5)

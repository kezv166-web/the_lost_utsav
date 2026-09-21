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

var divine_bar: ProgressBar = null
var divine_label: Label = null
var divine_pulse_tween: Tween = null
var current_divine: int = 0
var max_divine: int = 3

func _ready() -> void:
	if texture_rect:
		texture_rect.texture = tex_1_full
		texture_rect.anchors_preset = Control.PRESET_TOP_LEFT
		texture_rect.anchor_right = 0.0
		texture_rect.anchor_bottom = 0.0
		texture_rect.position = Vector2(0, 0)
		texture_rect.size = Vector2(360, 42)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	hp_label = get_node_or_null("HPText")
	if not hp_label:
		hp_label = Label.new()
		hp_label.name = "HPText"
		hp_label.position = Vector2(12, 48)
		hp_label.add_theme_font_size_override("font_size", 13)
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
		hp_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.04, 0.95))
		hp_label.add_theme_constant_override("outline_size", 4)
		add_child(hp_label)
	_update_text()
	_setup_divine_energy_bar()

func _setup_divine_energy_bar() -> void:
	divine_bar = ProgressBar.new()
	divine_bar.name = "DivineEnergyBar"
	divine_bar.position = Vector2(12, 72)
	divine_bar.custom_minimum_size = Vector2(220, 10)
	divine_bar.size = Vector2(220, 10)
	divine_bar.min_value = 0.0
	divine_bar.max_value = 3.0
	divine_bar.value = 0.0
	divine_bar.show_percentage = false
	
	# Dark obsidian background with antique gold border
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.06, 0.09, 0.92)
	bg_style.border_color = Color(0.85, 0.72, 0.32, 0.95)
	bg_style.set_border_width_all(1)
	bg_style.set_corner_radius_all(3)
	bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	bg_style.shadow_size = 2
	divine_bar.add_theme_stylebox_override("background", bg_style)
	
	# Radiant golden amber fill
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(1.0, 0.80, 0.22, 1.0)
	fill_style.set_corner_radius_all(2)
	divine_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Segment tick dividers for the 3 combo charges
	for pip_idx in range(1, 3):
		var divider = ColorRect.new()
		divider.name = "Divider%d" % pip_idx
		divider.color = Color(0.12, 0.09, 0.05, 0.85)
		divider.position = Vector2(round((220.0 / 3.0) * pip_idx), 0)
		divider.size = Vector2(1.5, 10)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		divine_bar.add_child(divider)

	add_child(divine_bar)
	
	divine_label = Label.new()
	divine_label.name = "DivineText"
	divine_label.position = Vector2(12, 88)
	divine_label.add_theme_font_size_override("font_size", 11)
	divine_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1.0))
	divine_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.04, 0.95))
	divine_label.add_theme_constant_override("outline_size", 3)
	divine_label.text = "DIVINE ENERGY  [ ◇ ◇ ◇ ]  0 / 3"
	add_child(divine_label)

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
	if player_node.has_signal("divine_energy_changed"):
		player_node.divine_energy_changed.connect(func(energy, max_e): update_divine_energy(energy, max_e))
		
	if "combo_hits" in player_node and "COMBO_MAX" in player_node:
		update_divine_energy(player_node.combo_hits, player_node.COMBO_MAX)
		
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

func update_divine_energy(energy: int, max_val: int = 3) -> void:
	current_divine = energy
	max_divine = max(1, max_val)
	if not divine_bar or not divine_label:
		return
		
	divine_bar.max_value = float(max_divine)
	var tw = create_tween()
	tw.tween_property(divine_bar, "value", float(current_divine), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if current_divine >= max_divine:
		# Pasa Special Ready!
		divine_label.text = "★ PASA SPECIAL READY! ★  [Press G to Grab]"
		divine_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.45, 1.0))
		
		# Pulsing radiant golden glow
		if divine_pulse_tween:
			divine_pulse_tween.kill()
		divine_pulse_tween = create_tween().set_loops()
		divine_pulse_tween.tween_property(divine_bar, "modulate", Color(1.45, 1.25, 0.55, 1.0), 0.35)
		divine_pulse_tween.tween_property(divine_bar, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)
	else:
		if divine_pulse_tween:
			divine_pulse_tween.kill()
			divine_pulse_tween = null
		divine_bar.modulate = Color(1.0, 1.0, 1.0, 1.0)
		divine_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1.0))
		
		# Build elegant 3-pip indicator
		var pips = ""
		for i in range(max_divine):
			if i < current_divine:
				pips += "◆ "
			else:
				pips += "◇ "
		divine_label.text = "DIVINE ENERGY  [ %s]  %d / %d" % [pips.strip_edges(), current_divine, max_divine]


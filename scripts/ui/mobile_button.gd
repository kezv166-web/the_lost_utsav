class_name MobileButton
extends Control

## Ornate Mythological Touch Button for Mobile Controls
## Displays custom weapon/action icon, golden border, and dynamic special glow.

@export var action_name: String = ""
@export var button_label: String = ""
@export var icon_texture: Texture2D = null
@export var button_radius: float = 38.0
@export var theme_color: Color = Color(0.9, 0.72, 0.25) # Golden default
@export var is_special_glow: bool = false:
	set(val):
		is_special_glow = val
		set_process(is_special_glow)
		queue_redraw()
@export var special_badge_text: String = "SPECIAL!"
@export var cooldown_seconds: float = 0.0
@export var cooldown_ratio: float = 0.0:
	set(val):
		var clamped = clampf(val, 0.0, 1.0)
		if clamped > 0.001:
			_was_on_cooldown = true
			modulate.a = 0.50
		elif _was_on_cooldown and clamped <= 0.001:
			_was_on_cooldown = false
			_flash_timer = 0.22 # Trigger golden ready pulse!
			set_process(true)
			modulate.a = 1.0
			queue_redraw()
		if abs(cooldown_ratio - clamped) > 0.005:
			cooldown_ratio = clamped
			queue_redraw()

var _touch_index: int = -1
var _is_pressed: bool = false
var _press_scale: float = 1.0
var _glow_phase: float = 0.0
var _was_on_cooldown: bool = false
var _flash_timer: float = 0.0
var _synth: UISoundSynth = null

const COLOR_BG_NORMAL := Color(0.12, 0.08, 0.05, 0.78)
const COLOR_BG_PRESSED := Color(0.28, 0.18, 0.08, 0.92)
const COLOR_RIM_OUTER := Color(0.92, 0.78, 0.32, 0.9)
const COLOR_RIM_INNER := Color(1.0, 0.9, 0.55, 0.6)
const COLOR_GLOW_AURA := Color(1.0, 0.85, 0.2, 0.85)

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	pivot_offset = size * 0.5
	set_process(is_special_glow)
	_synth = UISoundSynth.get_instance(self)

func _process(delta: float) -> void:
	var needs_process = false
	if is_special_glow:
		needs_process = true
		_glow_phase += delta * 4.5
		if _glow_phase > TAU:
			_glow_phase -= TAU
		queue_redraw()

	if _flash_timer > 0.0:
		needs_process = true
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_flash_timer = 0.0
		queue_redraw()

	if not needs_process:
		set_process(false)

func set_cooldown_ratio(ratio: float) -> void:
	cooldown_ratio = ratio

func set_cooldown(remaining_sec: float, ratio: float) -> void:
	cooldown_seconds = maxf(0.0, remaining_sec)
	cooldown_ratio = ratio
	if cooldown_seconds > 0.001 or cooldown_ratio > 0.001:
		modulate.a = 0.50
	elif not _was_on_cooldown:
		modulate.a = 1.0

func is_on_cooldown() -> bool:
	return cooldown_seconds > 0.001 or cooldown_ratio > 0.001

func _gui_input(event: InputEvent) -> void:
	# Make button completely unclickable during active cooldown
	if is_on_cooldown():
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
			_mark_input_handled()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_press_button(event.index)
			_mark_input_handled()
		elif event.index == _touch_index or _touch_index == -1:
			_release_button()
			_mark_input_handled()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_mark_input_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press_button(-1)
				_mark_input_handled()
			else:
				_release_button()
				_mark_input_handled()

func _mark_input_handled() -> void:
	accept_event()
	var vp = get_viewport()
	if vp:
		vp.set_input_as_handled()

func set_button_visuals(label: String, icon: Texture2D, glow: bool, badge: String = "", color: Color = Color(0.9, 0.72, 0.25)) -> void:
	var changed = false
	if button_label != label:
		button_label = label
		changed = true
	if icon_texture != icon:
		icon_texture = icon
		changed = true
	if is_special_glow != glow:
		is_special_glow = glow
		changed = true
	if special_badge_text != badge:
		special_badge_text = badge
		changed = true
	if theme_color != color:
		theme_color = color
		changed = true
	if changed:
		queue_redraw()

func _press_button(index: int) -> void:
	if is_on_cooldown():
		return
	_is_pressed = true
	_touch_index = index
	if action_name != "":
		# Release then press ensures every tap generates a brand new just_pressed event
		Input.action_release(action_name)
		Input.action_press(action_name)
		var ev = InputEventAction.new()
		ev.action = action_name
		ev.pressed = true
		Input.parse_input_event(ev)
		
	# Haptic visual bounce
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(0.91, 0.91), 0.05)
	
	if _synth:
		_synth.play_click()
		
	queue_redraw()

func _release_button() -> void:
	_is_pressed = false
	_touch_index = -1
	if action_name != "":
		Input.action_release(action_name)
		var ev = InputEventAction.new()
		ev.action = action_name
		ev.pressed = false
		Input.parse_input_event(ev)
		
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)
	
	queue_redraw()

func release_now() -> void:
	if _is_pressed:
		_release_button()

func _draw() -> void:
	var center = size * 0.5
	pivot_offset = center

	# 1. Special Divine Glow Aura (when active)
	if is_special_glow:
		var pulse_val = (sin(_glow_phase) + 1.0) * 0.5 # 0.0 to 1.0
		var aura_radius = button_radius + 8.0 + pulse_val * 8.0
		var aura_col = theme_color
		aura_col.a = 0.45 + pulse_val * 0.4
		draw_arc(center, aura_radius, 0, TAU, 36, aura_col, 4.5 + pulse_val * 2.0, true)
		
		# Second subtle halo
		var halo_col = Color(theme_color.r * 1.1, theme_color.g * 0.6, 0.1, 0.35 + pulse_val * 0.3)
		draw_arc(center, aura_radius + 5.0, 0, TAU, 36, halo_col, 2.0, true)

	# 2. Base Disc
	var bg_color = COLOR_BG_PRESSED if _is_pressed else COLOR_BG_NORMAL
	draw_circle(center, button_radius, bg_color)

	# 3. Outer Ornate Golden Rim
	var rim_color = COLOR_RIM_OUTER if not is_special_glow else theme_color.lightened(0.25)
	var rim_width = 3.5 if not is_special_glow else 4.5
	draw_arc(center, button_radius, 0, TAU, 36, rim_color, rim_width, true)
	draw_arc(center, button_radius - 3.5, 0, TAU, 32, COLOR_RIM_INNER, 1.5, true)

	# 4. Quad Golden Rivets
	for i in range(4):
		var angle = i * (TAU / 4.0) + PI / 4.0
		var rivet_pos = center + Vector2(cos(angle), sin(angle)) * (button_radius - 6.0)
		draw_circle(rivet_pos, 2.2, Color(1.0, 0.85, 0.4, 0.9))

	# 5. Icon Texture
	if icon_texture:
		var tex_size = icon_texture.get_size()
		var target_diam = button_radius * 1.25
		var icon_scale = target_diam / max(tex_size.x, tex_size.y)
		var dest_size = tex_size * icon_scale
		var dest_rect = Rect2(center - dest_size * 0.5, dest_size)
		var icon_mod = Color(1.0, 1.0, 1.0, 1.0 if not _is_pressed else 0.85)
		if is_special_glow:
			icon_mod = Color(1.2, 1.15, 0.9, 1.0)
		elif cooldown_ratio > 0.001:
			icon_mod = Color(0.65, 0.65, 0.65, 0.72)
		draw_texture_rect(icon_texture, dest_rect, false, icon_mod)

	# 5.5. Radial Cooldown Sweep Overlay
	if cooldown_ratio > 0.001:
		var start_angle = -PI * 0.5
		var sweep_angle = cooldown_ratio * TAU
		var end_angle = start_angle + sweep_angle
		
		# Translucent dark mythological shroud over remaining cooldown
		var num_pts = max(6, int(32 * cooldown_ratio))
		var poly_pts = PackedVector2Array()
		poly_pts.append(center)
		for i in range(num_pts + 1):
			var a = start_angle + sweep_angle * (float(i) / float(num_pts))
			poly_pts.append(center + Vector2(cos(a), sin(a)) * (button_radius - 2.0))
		draw_polygon(poly_pts, PackedColorArray([Color(0.04, 0.03, 0.02, 0.62)]))
		
		# Glowing golden leading-edge clock hand
		var edge_pos = center + Vector2(cos(end_angle), sin(end_angle)) * (button_radius - 2.0)
		draw_line(center, edge_pos, Color(1.0, 0.88, 0.4, 0.92), 2.5, true)
		
		# Active amber arc along the rim
		draw_arc(center, button_radius - 1.5, start_angle, end_angle, 28, Color(1.0, 0.75, 0.25, 0.85), 2.2, true)
		
		# Center pivot jewel
		draw_circle(center, 3.5, Color(1.0, 0.88, 0.35, 0.95))

		# Cooldown countdown text in seconds (e.g. 0.8s, 0.4s)
		if cooldown_seconds > 0.04:
			var sec_str = String.num(cooldown_seconds, 1) + "s"
			var font = ThemeDB.fallback_font
			var font_size = 15
			var text_sz = font.get_string_size(sec_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos = center + Vector2(-text_sz.x * 0.5, text_sz.y * 0.35)
			# Crisp drop shadow
			draw_string(font, text_pos + Vector2(1.5, 1.5), sec_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.95))
			# Bold golden countdown font
			draw_string(font, text_pos, sec_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.95, 0.72, 1.0))

	# 5.6. Golden Ready Pulse Flash (when cooldown finishes)
	if _flash_timer > 0.0:
		var flash_norm = _flash_timer / 0.22
		var flash_col = Color(1.0, 0.95, 0.65, flash_norm * 0.45)
		draw_circle(center, button_radius, flash_col)
		var ring_col = Color(1.0, 0.9, 0.45, flash_norm * 0.85)
		draw_arc(center, button_radius + (1.0 - flash_norm) * 7.0, 0, TAU, 36, ring_col, 2.5, true)

	# 6. Button Title / Badge
	if is_special_glow and special_badge_text != "":
		# Badge Pill on Top
		var badge_pos = center + Vector2(0, -button_radius - 6.0)
		var font = ThemeDB.fallback_font
		var font_size = 11
		var text_sz = font.get_string_size(special_badge_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pill_rect = Rect2(badge_pos - Vector2(text_sz.x * 0.5 + 6.0, text_sz.y * 0.5 + 2.0), Vector2(text_sz.x + 12.0, text_sz.y + 4.0))
		var pill_bg = Color(0.85, 0.18, 0.15, 0.95) if theme_color == Color(0.9, 0.72, 0.25) else Color(theme_color.r * 0.75, theme_color.g * 0.25, 0.1, 0.95)
		draw_rect(pill_rect, pill_bg, true)
		draw_rect(pill_rect, Color(1.0, 0.9, 0.4, 1.0), false, 1.5)
		draw_string(font, badge_pos + Vector2(-text_sz.x * 0.5, text_sz.y * 0.35), special_badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 1.0, 0.85))

	if button_label != "":
		var font = ThemeDB.fallback_font
		var font_size = 10
		var text_sz = font.get_string_size(button_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var label_y = center.y + button_radius + 12.0
		# Text drop shadow
		draw_string(font, Vector2(center.x - text_sz.x * 0.5 + 1.0, label_y + 1.0), button_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.85))
		# Text primary
		draw_string(font, Vector2(center.x - text_sz.x * 0.5, label_y), button_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.85, 0.55, 0.95))

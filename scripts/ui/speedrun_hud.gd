class_name SpeedrunHUD
extends Control

## SpeedrunHUD – Live in-game speedrun timer & score overlay
## Accurately displays total running time, total cumulative score,
## Level 2 modaks collected (0/5), and Level 3 boss attempt count.
## Provides rewarding visual pulse animation when points are added.

@onready var panel: PanelContainer = $PanelContainer
@onready var time_label: Label = $PanelContainer/Margin/HBox/TimeLabel
@onready var score_label: Label = $PanelContainer/Margin/HBox/ScoreLabel
@onready var context_badge: Label = $PanelContainer/Margin/HBox/ContextBadge

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grm = get_node_or_null("/root/GameRunManager")
	if grm and grm.has_signal("points_awarded") and not grm.points_awarded.is_connected(_on_points_awarded):
		grm.points_awarded.connect(_on_points_awarded)
	var lm = LeaderboardManager.get_instance()
	if lm and lm.has_signal("achievement_unlocked") and not lm.achievement_unlocked.is_connected(_show_achievement_toast):
		lm.achievement_unlocked.connect(_show_achievement_toast)
	_update_display()

func _show_achievement_toast(_id: String, title_name: String) -> void:
	var toast = PanelContainer.new()
	toast.custom_minimum_size = Vector2(360, 46)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.02, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1.0, 0.85, 0.25, 1.0)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 6
	toast.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	toast.add_child(margin)

	var lbl = Label.new()
	lbl.text = "★ TITLE UNLOCKED: %s ★" % title_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35, 1.0))
	lbl.add_theme_font_size_override("font_size", 13)
	margin.add_child(lbl)

	add_child(toast)
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.position = Vector2((size.x - 360.0) * 0.5, -60.0)
	toast.scale = Vector2(0.8, 0.8)
	toast.pivot_offset = Vector2(180.0, 23.0)

	var tw = create_tween()
	tw.tween_property(toast, "position:y", 58.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(toast, "scale", Vector2(1.05, 1.05), 0.35)
	tw.tween_property(toast, "scale", Vector2(1.0, 1.0), 0.1)
	tw.tween_interval(3.0)
	tw.tween_property(toast, "position:y", -70.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(toast, "modulate:a", 0.0, 0.35)
	tw.tween_callback(toast.queue_free)

func _process(_delta: float) -> void:
	_update_display()

func _on_points_awarded(_amount: int, _total: int, _reason: String) -> void:
	if score_label and is_instance_valid(score_label):
		score_label.pivot_offset = score_label.size * 0.5
		var tw = create_tween()
		tw.tween_property(score_label, "scale", Vector2(1.22, 1.22), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _update_display() -> void:
	var grm = get_node_or_null("/root/GameRunManager")
	if not grm:
		return

	# Format Time: MM:SS:CS
	if time_label:
		time_label.text = "TIME %s" % grm.format_time(grm.total_time)

	# Format Score
	if score_label:
		score_label.text = "%s PTS" % _format_number(grm.total_points)

	# Level-specific badge
	if context_badge:
		match grm.current_level_num:
			1:
				context_badge.text = "[STAGE 1: GATE]"
				context_badge.modulate = Color(1.0, 0.85, 0.4)
			2:
				context_badge.text = "MODAKS: %d/5 (+%d)" % [grm.level2_modaks, grm.level2_modaks * 50]
				context_badge.modulate = Color(0.4, 0.95, 0.6)
			3:
				var max_att = grm.MAX_LEVEL3_ATTEMPTS if "MAX_LEVEL3_ATTEMPTS" in grm else 3
				match grm.level3_attempts:
					1:
						context_badge.text = "TRIES: 1/%d (+500)" % max_att
						context_badge.modulate = Color(1.0, 0.85, 0.4)
					2:
						context_badge.text = "TRIES: 2/%d (+300)" % max_att
						context_badge.modulate = Color(1.0, 0.6, 0.3)
					3:
						context_badge.text = "FINAL TRY: 3/%d (+150)" % max_att
						context_badge.modulate = Color(1.0, 0.25, 0.25)
					_:
						context_badge.text = "TRIES: %d/%d (0)" % [grm.level3_attempts, max_att]
						context_badge.modulate = Color(0.8, 0.2, 0.2)

func _format_number(val: int) -> String:
	var s = str(val)
	var res = ""
	var cnt = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	return res

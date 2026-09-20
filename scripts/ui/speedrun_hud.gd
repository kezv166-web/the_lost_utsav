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
	_update_display()

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
		time_label.text = "⏱ %s" % grm.format_time(grm.total_time)

	# Format Score
	if score_label:
		score_label.text = "★ %s PTS" % _format_number(grm.total_points)

	# Level-specific badge
	if context_badge:
		match grm.current_level_num:
			1:
				context_badge.text = "[STAGE 1: GATE]"
				context_badge.modulate = Color(1.0, 0.85, 0.4)
			2:
				context_badge.text = "🍬 MODAKS: %d/5 (+%d)" % [grm.level2_modaks, grm.level2_modaks * 50]
				context_badge.modulate = Color(0.4, 0.95, 0.6)
			3:
				var attempt_bonus = 500 if grm.level3_attempts == 1 else (300 if grm.level3_attempts == 2 else (150 if grm.level3_attempts == 3 else 50))
				context_badge.text = "⚔ ATTEMPT: %d (+%d)" % [grm.level3_attempts, attempt_bonus]
				context_badge.modulate = Color(1.0, 0.45, 0.35)

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

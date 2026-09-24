class_name GameOver
extends Control

## GameOver – Studio-Grade Expedition Failed Screen
## Displays comprehensive run statistics when player runs out of tries in Level 3.
## Prompts the player to retry expedition, view leaderboard, or return to main menu.

const SCENE_OUTDOOR: String = "res://scenes/levels/outdoor/outdoor_map.tscn"
const SCENE_LEADERBOARD: String = "res://scenes/ui/leaderboard.tscn"
const SCENE_START_PAGE: String = "res://scenes/ui/start_page.tscn"

@onready var card_panel: PanelContainer = $CenterContainer/CardPanel
@onready var title_label: Label = $CenterContainer/CardPanel/Margin/VBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/CardPanel/Margin/VBox/SubtitleLabel
@onready var time_val_label: Label = $CenterContainer/CardPanel/Margin/VBox/StatsGrid/TimeVal
@onready var score_val_label: Label = $CenterContainer/CardPanel/Margin/VBox/StatsGrid/ScoreVal
@onready var level_val_label: Label = $CenterContainer/CardPanel/Margin/VBox/StatsGrid/LevelVal
@onready var modaks_val_label: Label = $CenterContainer/CardPanel/Margin/VBox/StatsGrid/ModaksVal
@onready var boss_val_label: Label = $CenterContainer/CardPanel/Margin/VBox/StatsGrid/BossVal

@onready var btn_retry: Button = $CenterContainer/CardPanel/Margin/VBox/ButtonsHBox/BtnRetry
@onready var btn_leaderboard: Button = $CenterContainer/CardPanel/Margin/VBox/ButtonsHBox/BtnLeaderboard
@onready var btn_menu: Button = $CenterContainer/CardPanel/Margin/VBox/ButtonsHBox/BtnMenu

@onready var screen_fader: ColorRect = $ScreenFader

var sound_synth: UISoundSynth = null
var _is_transitioning: bool = false
var _anim_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sound_synth = UISoundSynth.get_instance(self)

	# Setup buttons
	_setup_button(btn_retry, _on_retry_pressed)
	_setup_button(btn_leaderboard, _on_leaderboard_pressed)
	_setup_button(btn_menu, _on_menu_pressed)

	_populate_stats()

	# Grab focus for gamepad / keyboard
	if btn_retry:
		btn_retry.grab_focus()

	# Intro animation
	if card_panel:
		card_panel.modulate.a = 0.0
		card_panel.scale = Vector2(0.92, 0.92)
		card_panel.pivot_offset = Vector2(300, 240)

	if screen_fader:
		screen_fader.visible = true
		screen_fader.modulate.a = 1.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(screen_fader, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
		if card_panel:
			tw.tween_property(card_panel, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(card_panel, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_anim_time += delta
	# Subtle ominous breathing pulse on title
	if title_label and is_instance_valid(title_label):
		var p = 0.82 + 0.18 * sin(_anim_time * 2.8)
		title_label.modulate = Color(1.0, 0.28 * p + 0.1, 0.28 * p + 0.1, 1.0)

func _populate_stats() -> void:
	var grm = get_node_or_null("/root/GameRunManager")
	var t_str = "00:00:00"
	var pts_str = "0 PTS"
	var modaks_str = "0 / 5"
	var max_lvl_str = "Level 2 (Underground Maze)"
	var boss_str = "Defeated (3/3 Tries Exhausted)"

	if grm:
		t_str = grm.format_time(grm.total_time)
		pts_str = "%s PTS" % LeaderboardManager.format_score(grm.total_points)
		modaks_str = "%d / 5" % grm.level2_modaks

	if time_val_label:
		time_val_label.text = t_str
	if score_val_label:
		score_val_label.text = pts_str
	if level_val_label:
		level_val_label.text = max_lvl_str
	if modaks_val_label:
		modaks_val_label.text = modaks_str
	if boss_val_label:
		boss_val_label.text = boss_str

func _setup_button(btn: Button, action: Callable) -> void:
	if not btn:
		return
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func():
		if sound_synth:
			sound_synth.play_click()
		action.call()
	)
	btn.mouse_entered.connect(func():
		if sound_synth:
			sound_synth.play_hover()
		btn.pivot_offset = btn.size * 0.5
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.10).set_trans(Tween.TRANS_SINE)
	)
	btn.mouse_exited.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
	)

func _on_retry_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var grm = get_node_or_null("/root/GameRunManager")
	if grm:
		grm.start_new_run()
	_transition_to_scene(SCENE_OUTDOOR)

func _on_leaderboard_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_transition_to_scene(SCENE_LEADERBOARD)

func _on_menu_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_transition_to_scene(SCENE_START_PAGE)

func _transition_to_scene(scene_path: String) -> void:
	if screen_fader:
		screen_fader.visible = true
		var tw = create_tween()
		tw.tween_property(screen_fader, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func():
			get_tree().change_scene_to_file(scene_path)
		)
	else:
		get_tree().change_scene_to_file(scene_path)

class_name CreditsScreen
extends Control

## Cinematic End Credits Roll for The Lost Utsav
## Displays full team attribution, special thanks, and inspirational closing lore.
## Supports smooth automatic scrolling, manual scroll override, and skip to leaderboard.

const LEADERBOARD_SCENE: String = "res://scenes/ui/leaderboard.tscn"
const START_PAGE_SCENE: String = "res://scenes/ui/start_page.tscn"

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var credits_content: VBoxContainer = $ScrollContainer/CreditsContent
@onready var btn_skip: Button = $TopHUD/SkipButton
@onready var btn_menu: Button = $BottomActions/HBox/MenuButton
@onready var btn_leaderboard: Button = $BottomActions/HBox/LeaderboardButton
@onready var bottom_actions: Control = $BottomActions
@onready var fade_overlay: ColorRect = $FadeOverlay

var scroll_pos: float = 0.0
var auto_scroll: bool = true
var scroll_speed: float = 38.0 # Pixels per second
var is_transitioning: bool = false
var has_reached_end: bool = false
var sound_synth: UISoundSynth = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sound_synth = UISoundSynth.get_instance(self)

	# Play uplifting theme during credits
	if has_node("/root/MusicManager"):
		MusicManager.play("l1_lower")

	# Setup buttons
	if btn_skip:
		btn_skip.pressed.connect(_on_skip_pressed)
		btn_skip.mouse_entered.connect(_on_btn_hover)
	if btn_leaderboard:
		btn_leaderboard.pressed.connect(_on_leaderboard_pressed)
		btn_leaderboard.mouse_entered.connect(_on_btn_hover)
	if btn_menu:
		btn_menu.pressed.connect(_on_menu_pressed)
		btn_menu.mouse_entered.connect(_on_btn_hover)

	if bottom_actions:
		bottom_actions.modulate.a = 0.0
		bottom_actions.visible = true

	# Start scroll at top
	scroll_pos = 0.0
	if scroll_container:
		scroll_container.scroll_vertical = 0

	# Smooth fade-in
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0
		var tw = create_tween()
		tw.tween_property(fade_overlay, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if not auto_scroll or is_transitioning:
		return

	scroll_pos += scroll_speed * delta
	if scroll_container:
		scroll_container.scroll_vertical = int(scroll_pos)
		
		# Check if scrolled near the bottom
		var max_scroll = scroll_container.get_v_scroll_bar().max_value - scroll_container.size.y
		if scroll_pos >= max_scroll and not has_reached_end:
			_on_scroll_reached_end()

func _on_scroll_reached_end() -> void:
	has_reached_end = true
	if bottom_actions:
		var tw = create_tween()
		tw.tween_property(bottom_actions, "modulate:a", 1.0, 0.5)

func _input(event: InputEvent) -> void:
	# Space or Enter can skip / advance once reached end
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			_transition_to_scene(START_PAGE_SCENE)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if has_reached_end:
				_transition_to_scene(LEADERBOARD_SCENE)
				get_viewport().set_input_as_handled()

func _on_btn_hover() -> void:
	if sound_synth:
		sound_synth.play_hover()

func _on_skip_pressed() -> void:
	if sound_synth:
		sound_synth.play_click()
	_transition_to_scene(LEADERBOARD_SCENE)

func _on_leaderboard_pressed() -> void:
	if sound_synth:
		sound_synth.play_click()
	_transition_to_scene(LEADERBOARD_SCENE)

func _on_menu_pressed() -> void:
	if sound_synth:
		sound_synth.play_click()
	_transition_to_scene(START_PAGE_SCENE)

func _transition_to_scene(target_scene: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			if ResourceLoader.exists(target_scene):
				get_tree().change_scene_to_file(target_scene)
			else:
				push_error("Target scene not found: %s" % target_scene)
		)
	else:
		if ResourceLoader.exists(target_scene):
			get_tree().change_scene_to_file(target_scene)

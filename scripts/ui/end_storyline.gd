class_name EndStoryline
extends Control

signal end_storyline_completed

const FRAME_PATHS: Array[String] = [
	"res://assets/storyline/end/end-story1.png",
	"res://assets/storyline/end/end-story2.png",
	"res://assets/storyline/end/end-story3.png",
	"res://assets/storyline/end/end-story4.png",
	"res://assets/storyline/end/end-story5.png",
	"res://assets/storyline/end/end-story6.png",
	"res://assets/storyline/end/end-story7.png",
	"res://assets/storyline/end/end-story8.png",
	"res://assets/storyline/end/end-story9.png",
	"res://assets/storyline/end/end-story10.png",
	"res://assets/storyline/end/end-story11.png"
]

const NEXT_SCENE: String = "res://scenes/ui/leaderboard.tscn"
const START_PAGE_SCENE: String = "res://scenes/ui/start_page.tscn"

@onready var current_rect: TextureRect = $DisplayContainer/CurrentFrame
@onready var next_rect: TextureRect = $DisplayContainer/NextFrame
@onready var click_catcher: Button = $ClickCatcher
@onready var menu_btn: Button = $HUD/TopBar/MenuButton
@onready var skip_btn: Button = $HUD/TopBar/SkipButton
@onready var prev_btn: Button = $HUD/BottomBar/PrevButton
@onready var next_btn: Button = $HUD/BottomBar/NextButton
@onready var progress_label: Label = $HUD/BottomBar/ProgressLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

var textures: Array[Texture2D] = []
var current_index: int = 0
var is_transitioning: bool = false
var has_finished: bool = false

func _ready() -> void:
	# 1. Play divine chant for ending sequence
	var mm = get_node_or_null("/root/MusicManager")
	if mm and mm.has_method("play"):
		mm.play("l1_lower")
		
	# 2. Preload textures safely
	_load_all_textures()
	
	# 3. Connect HUD button signals idempotently
	if click_catcher and not click_catcher.pressed.is_connected(_on_next_pressed):
		click_catcher.pressed.connect(_on_next_pressed)
	if menu_btn and not menu_btn.pressed.is_connected(_on_menu_pressed):
		menu_btn.pressed.connect(_on_menu_pressed)
	if skip_btn and not skip_btn.pressed.is_connected(_on_skip_pressed):
		skip_btn.pressed.connect(_on_skip_pressed)
	if prev_btn and not prev_btn.pressed.is_connected(_on_prev_pressed):
		prev_btn.pressed.connect(_on_prev_pressed)
	if next_btn and not next_btn.pressed.is_connected(_on_next_pressed):
		next_btn.pressed.connect(_on_next_pressed)
		
	# 4. Setup initial frame
	if textures.size() > 0:
		current_rect.texture = textures[0]
		current_rect.modulate.a = 1.0
	if next_rect:
		next_rect.modulate.a = 0.0
		
	current_index = 0
	_update_hud()
	
	# 5. Smooth startup fade-in from black
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0
		var tw = create_tween()
		if tw:
			tw.tween_property(fade_overlay, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if has_finished or is_transitioning:
		return
		
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE):
		_on_skip_pressed()
	elif event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.keycode == KEY_A or event.keycode == KEY_LEFT)):
		_on_prev_pressed()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.keycode in [KEY_SPACE, KEY_ENTER, KEY_D, KEY_RIGHT, KEY_E, KEY_F])):
		_on_next_pressed()

func _load_all_textures() -> void:
	textures.clear()
	for path in FRAME_PATHS:
		var tex: Texture2D = null
		if ResourceLoader.exists(path):
			tex = load(path)
		elif path.ends_with("end-story2.png") and ResourceLoader.exists("res://assets/storyline/end/end=story2.png"):
			tex = load("res://assets/storyline/end/end=story2.png")
			
		if tex:
			textures.append(tex)
		else:
			push_warning("End storyline frame texture missing: %s" % path)

func _on_next_pressed() -> void:
	if has_finished or is_transitioning:
		return
		
	if current_index < textures.size() - 1:
		_transition_to_frame(current_index + 1)
	else:
		_finish_storyline()

func _on_prev_pressed() -> void:
	if has_finished or is_transitioning:
		return
		
	if current_index > 0:
		_transition_to_frame(current_index - 1)

func _on_menu_pressed() -> void:
	if has_finished or is_transitioning:
		return
	has_finished = true
	is_transitioning = true
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 0.0
		var tw = create_tween()
		if tw:
			tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_callback(func():
				if ResourceLoader.exists(START_PAGE_SCENE):
					get_tree().change_scene_to_file(START_PAGE_SCENE)
			)
			return
	if ResourceLoader.exists(START_PAGE_SCENE):
		get_tree().change_scene_to_file(START_PAGE_SCENE)

func _on_skip_pressed() -> void:
	if has_finished:
		return
	_finish_storyline()

func _transition_to_frame(target_idx: int) -> void:
	if target_idx < 0 or target_idx >= textures.size():
		return
		
	is_transitioning = true
	var next_tex = textures[target_idx]
	next_rect.texture = next_tex
	next_rect.modulate.a = 0.0
	
	var tw = create_tween()
	if tw:
		tw.tween_property(next_rect, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			current_rect.texture = next_tex
			next_rect.modulate.a = 0.0
			current_index = target_idx
			is_transitioning = false
			_update_hud()
		)
	else:
		current_rect.texture = next_tex
		next_rect.modulate.a = 0.0
		current_index = target_idx
		is_transitioning = false
		_update_hud()

func _update_hud() -> void:
	if progress_label:
		progress_label.text = "%d / %d" % [current_index + 1, textures.size()]
	if prev_btn:
		prev_btn.visible = (current_index > 0)
	if next_btn:
		if current_index == textures.size() - 1:
			next_btn.text = "View Leaderboard »"
		else:
			next_btn.text = "[Space / Click] Next »"

func _finish_storyline() -> void:
	if has_finished:
		return
	has_finished = true
	is_transitioning = true
	end_storyline_completed.emit()
	
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 0.0
		var tw = create_tween()
		if tw:
			tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_callback(func(): _load_next_scene())
			return
			
	_load_next_scene()

func _load_next_scene() -> void:
	if ResourceLoader.exists(NEXT_SCENE):
		get_tree().change_scene_to_file(NEXT_SCENE)
	elif ResourceLoader.exists(START_PAGE_SCENE):
		get_tree().change_scene_to_file(START_PAGE_SCENE)
	else:
		push_error("Next scene does not exist: %s" % NEXT_SCENE)

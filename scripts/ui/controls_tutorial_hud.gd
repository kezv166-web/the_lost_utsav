class_name ControlsTutorialHUD
extends CanvasLayer

## ControlsTutorialHUD
## Displays a studio-grade Controls Guide at the start of the game:
## WASD (Move), SPACE (Jump), F (Axe), G (Rope), E (Interact), 1 (Transform).
## Automatically detects mobile/touch and hides itself.
## Smoothly fades out after player acts or after 12 seconds.
## Press [H] anytime to toggle the controls guide.

@onready var panel_container: PanelContainer = $RootControl/TutorialPanel
@onready var toggle_hint: Label = $RootControl/ToggleHint

var is_visible_to_player: bool = true
var time_active: float = 0.0
var has_moved: bool = false
var has_acted: bool = false
var fade_tween: Tween = null

func _ready() -> void:
	layer = 85 # Above gameplay, below system popups
	
	# Detect touch/mobile environment - auto hide if virtual touch controls are used
	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		queue_free()
		return
		
	if panel_container:
		panel_container.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(panel_container, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	if toggle_hint:
		toggle_hint.visible = false

func _process(delta: float) -> void:
	time_active += delta
	
	# Detect player actions to gauge readiness
	if not has_moved:
		if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
			has_moved = true
	if not has_acted:
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack_axe") or Input.is_action_just_pressed("attack_rope") or Input.is_action_just_pressed("interact"):
			has_acted = true
			
	# Auto-fade after 12 seconds or 6 seconds after both moving & acting
	if is_visible_to_player and panel_container and panel_container.modulate.a > 0.9:
		if time_active >= 12.0 or (has_moved and has_acted and time_active >= 6.0):
			fade_out()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.physical_keycode == KEY_H or event.keycode == KEY_H:
			toggle_guide()
			get_viewport().set_input_as_handled()

func toggle_guide() -> void:
	if is_visible_to_player:
		fade_out()
	else:
		fade_in()

func fade_out() -> void:
	if not is_visible_to_player:
		return
	is_visible_to_player = false
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(panel_container, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	fade_tween.tween_callback(func():
		if is_instance_valid(panel_container):
			panel_container.visible = false
		if is_instance_valid(toggle_hint):
			toggle_hint.visible = true
			toggle_hint.modulate.a = 0.0
			var tw = create_tween()
			tw.tween_property(toggle_hint, "modulate:a", 0.75, 0.3)
	)

func fade_in() -> void:
	if is_visible_to_player:
		return
	is_visible_to_player = true
	time_active = 0.0
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		
	if toggle_hint:
		toggle_hint.visible = false
	if panel_container:
		panel_container.visible = true
		fade_tween = create_tween()
		fade_tween.tween_property(panel_container, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)

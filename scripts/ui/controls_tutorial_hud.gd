class_name ControlsTutorialHUD
extends CanvasLayer

## ControlsTutorialHUD
## Studio-grade Controls Guide supporting both PC (Keyboard/Mouse) and Mobile (Touch Screen).
## Displays on game start, supports interactive tabs, and has a dedicated [BEGIN] button.
## Can be reopened anytime via [H] key or by tapping the [?] CONTROLS button.

@onready var panel_container: PanelContainer = $RootControl/CenterBox/TutorialPanel
@onready var pc_content: VBoxContainer = $RootControl/CenterBox/TutorialPanel/Margin/VBox/ContentPC
@onready var mobile_content: VBoxContainer = $RootControl/CenterBox/TutorialPanel/Margin/VBox/ContentMobile
@onready var tab_pc: Button = $RootControl/CenterBox/TutorialPanel/Margin/VBox/TabBar/BtnPC
@onready var tab_mobile: Button = $RootControl/CenterBox/TutorialPanel/Margin/VBox/TabBar/BtnMobile
@onready var btn_begin: Button = $RootControl/CenterBox/TutorialPanel/Margin/VBox/BtnBegin
@onready var toggle_btn: Button = $RootControl/ToggleBtn

@export var start_minimized: bool = false
var is_visible_to_player: bool = true
var time_active: float = 0.0
var has_moved: bool = false
var has_acted: bool = false
var fade_tween: Tween = null

func _ready() -> void:
	layer = 95 # Above gameplay HUDs, below pause menu
	
	# Determine initial tab: Mobile if mobile platform or touchscreen active
	var is_mobile: bool = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	if MobileControlsLayer.is_gamepad_mode():
		is_mobile = true
			
	if is_mobile:
		show_mobile_tab()
	else:
		show_pc_tab()
		
	# Wire tab and button signals
	if tab_pc:
		tab_pc.pressed.connect(show_pc_tab)
	if tab_mobile:
		tab_mobile.pressed.connect(show_mobile_tab)
	if btn_begin:
		btn_begin.pressed.connect(fade_out)
	if toggle_btn:
		toggle_btn.pressed.connect(toggle_guide)

	if start_minimized:
		is_visible_to_player = false
		if panel_container:
			panel_container.visible = false
			panel_container.modulate.a = 0.0
		if toggle_btn:
			toggle_btn.visible = true
			toggle_btn.modulate.a = 0.85
	else:
		if toggle_btn:
			toggle_btn.visible = false
		if panel_container:
			panel_container.visible = true
			panel_container.modulate.a = 0.0
			var tw = create_tween()
			tw.tween_property(panel_container, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func show_pc_tab() -> void:
	if pc_content:
		pc_content.visible = true
	if mobile_content:
		mobile_content.visible = false
	if tab_pc:
		tab_pc.modulate = Color(1.0, 0.9, 0.5, 1.0)
	if tab_mobile:
		tab_mobile.modulate = Color(0.65, 0.65, 0.65, 0.8)

func show_mobile_tab() -> void:
	if pc_content:
		pc_content.visible = false
	if mobile_content:
		mobile_content.visible = true
	if tab_pc:
		tab_pc.modulate = Color(0.65, 0.65, 0.65, 0.8)
	if tab_mobile:
		tab_mobile.modulate = Color(1.0, 0.9, 0.5, 1.0)

func _process(delta: float) -> void:
	if not is_visible_to_player:
		return
		
	time_active += delta
	
	# Detect player actions to gauge readiness
	if not has_moved:
		if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
			has_moved = true
	if not has_acted:
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack_axe") or Input.is_action_just_pressed("attack_rope") or Input.is_action_just_pressed("interact"):
			has_acted = true
			
	# Auto-fade after 12 seconds or 6 seconds after moving and acting
	if is_visible_to_player and panel_container and panel_container.modulate.a > 0.9:
		if time_active >= 12.0 or (has_moved and has_acted and time_active >= 6.0):
			fade_out()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.physical_keycode == KEY_H or event.keycode == KEY_H:
			toggle_guide()
			get_viewport().set_input_as_handled()
		elif is_visible_to_player and (event.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_ESCAPE, KEY_ENTER]):
			# Dismiss on intentional navigation key
			fade_out()

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
	fade_tween.tween_property(panel_container, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	fade_tween.tween_callback(func():
		if is_instance_valid(panel_container):
			panel_container.visible = false
		if is_instance_valid(toggle_btn):
			toggle_btn.visible = true
			toggle_btn.modulate.a = 0.0
			var tw = create_tween()
			tw.tween_property(toggle_btn, "modulate:a", 0.85, 0.25)
	)

func fade_in() -> void:
	if is_visible_to_player:
		return
	is_visible_to_player = true
	time_active = 0.0
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		
	if toggle_btn:
		toggle_btn.visible = false
	if panel_container:
		panel_container.visible = true
		fade_tween = create_tween()
		fade_tween.tween_property(panel_container, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)

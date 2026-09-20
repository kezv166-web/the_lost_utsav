class_name StartPage
extends Control

# The Lost Utsav - Start Game Page (Main Menu)
# Closely mimics the art, composition, and visual aesthetics of start-game-page.png & start_page_elements.png
# Fully compatible with Linux, WebGL/WASM (Vercel/Itch.io), and Desktop exports.

const SCENE_STORYLINE: String = "res://scenes/ui/storyline.tscn"
const SCENE_LEADERBOARD: String = "res://scenes/ui/leaderboard.tscn"
const SCENE_LEVEL_OUTDOOR: String = "res://scenes/levels/outdoor/outdoor_map.tscn"

@onready var background: TextureRect = $Background
@onready var title_logo: TextureRect = $TitleLogo

@onready var btn_play: Button = $MenuContainer/VBoxButtons/PlayButton
@onready var btn_story: Button = $MenuContainer/VBoxButtons/StoryButton
@onready var btn_leaderboard: Button = $MenuContainer/VBoxButtons/LeaderboardButton
@onready var btn_exit: Button = $MenuContainer/VBoxButtons/ExitButton

@onready var btn_controls: Button = $BottomRightHUD/HBoxIcons/ControlsButton
@onready var btn_credits: Button = $BottomRightHUD/HBoxIcons/CreditsButton
@onready var btn_help: Button = $BottomRightHUD/HBoxIcons/HelpButton

@onready var modal_layer: Control = $ModalLayer
@onready var controls_modal: Control = $ModalLayer/ControlsModal
@onready var credits_modal: Control = $ModalLayer/CreditsModal
@onready var help_modal: Control = $ModalLayer/HelpModal
@onready var exit_modal: Control = $ModalLayer/ExitConfirmModal

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var torch_flicker_1: ColorRect = $AmbientVFX/TorchGlow1
@onready var torch_flicker_2: ColorRect = $AmbientVFX/TorchGlow2
@onready var gate_glow: ColorRect = $AmbientVFX/GateGlow

var _sound_synth: UISoundSynth = null
var _is_transitioning: bool = false
var _anim_time: float = 0.0

func _ready() -> void:
	# 0. Apply clean transparent textures from UISliceManager
	if background:
		var bg_tex = UISliceManager.get_start_page_bg()
		if bg_tex:
			background.texture = bg_tex
	if title_logo:
		var logo_tex = UISliceManager.get_texture("sp_title_logo")
		if logo_tex:
			title_logo.texture = logo_tex

	# 1. Initialize Procedural Sound Synthesizer
	_sound_synth = UISoundSynth.get_instance(self)
	
	# 2. Connect Menu Button Signals
	_setup_button(btn_play, _on_play_pressed)
	_setup_button(btn_story, _on_story_pressed)
	_setup_button(btn_leaderboard, _on_leaderboard_pressed)
	_setup_button(btn_exit, _on_exit_pressed)
	
	# 3. Connect Bottom-Right Action Buttons
	_setup_button(btn_controls, _on_controls_pressed)
	_setup_button(btn_credits, _on_credits_pressed)
	_setup_button(btn_help, _on_help_pressed)
	
	# 4. Connect Modal Close Buttons
	var close_controls = $ModalLayer/ControlsModal/Panel/VBox/CloseButton
	var close_credits = $ModalLayer/CreditsModal/Panel/VBox/CloseButton
	var close_help = $ModalLayer/HelpModal/Panel/VBox/CloseButton
	var exit_yes = $ModalLayer/ExitConfirmModal/Panel/VBox/HBox/ConfirmExitButton
	var exit_no = $ModalLayer/ExitConfirmModal/Panel/VBox/HBox/CancelExitButton
	
	_setup_button(close_controls, _close_modals)
	_setup_button(close_credits, _close_modals)
	_setup_button(close_help, _close_modals)
	_setup_button(exit_yes, _on_confirm_exit)
	_setup_button(exit_no, _close_modals)
	
	# Close all modals initially
	_close_modals()
	
	# Initial button focus for gamepad/keyboard accessibility
	if btn_play and is_inside_tree():
		btn_play.grab_focus()
	
	# 5. Startup fade-in transition
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0
		var tw = create_tween()
		if tw:
			tw.tween_property(fade_overlay, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func(): fade_overlay.visible = false)

func _process(delta: float) -> void:
	# Ambient torch flame & demonic gate flicker
	_anim_time += delta
	if torch_flicker_1:
		var flicker1 = 0.28 + 0.14 * sin(_anim_time * 8.2) + 0.07 * cos(_anim_time * 19.3)
		torch_flicker_1.modulate.a = clamp(flicker1, 0.12, 0.48)
	if torch_flicker_2:
		var flicker2 = 0.25 + 0.13 * sin(_anim_time * 7.4 + 1.5) + 0.06 * cos(_anim_time * 22.0)
		torch_flicker_2.modulate.a = clamp(flicker2, 0.12, 0.45)
	if gate_glow:
		var pulse = 0.32 + 0.12 * sin(_anim_time * 3.2)
		gate_glow.modulate.a = clamp(pulse, 0.18, 0.52)

func _setup_button(btn: Button, click_handler: Callable) -> void:
	if not btn:
		return
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func():
		if _sound_synth:
			_sound_synth.play_click()
		_button_press_anim(btn)
		click_handler.call()
	)
	btn.mouse_entered.connect(func():
		if _sound_synth:
			_sound_synth.play_hover()
		_button_hover_anim(btn, true)
	)
	btn.mouse_exited.connect(func():
		_button_hover_anim(btn, false)
	)
	btn.focus_entered.connect(func():
		if _sound_synth:
			_sound_synth.play_hover()
		_button_hover_anim(btn, true)
	)
	btn.focus_exited.connect(func():
		_button_hover_anim(btn, false)
	)

func _button_hover_anim(btn: Button, is_hovered: bool) -> void:
	if not btn or not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var tw = create_tween()
	if not tw:
		return
	if is_hovered:
		tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _button_press_anim(btn: Button) -> void:
	if not btn or not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var tw = create_tween()
	if not tw:
		return
	btn.scale = Vector2(0.97, 0.97)
	tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE):
		if modal_layer and modal_layer.visible:
			_close_modals()
		else:
			_on_exit_pressed()

func _on_play_pressed() -> void:
	# Begin Journey -> Start Storyline narrative intro
	_transition_to_scene(SCENE_STORYLINE)

func _on_story_pressed() -> void:
	_transition_to_scene(SCENE_STORYLINE)

func _on_leaderboard_pressed() -> void:
	_transition_to_scene(SCENE_LEADERBOARD)

func _on_exit_pressed() -> void:
	_show_modal(exit_modal)

func _on_confirm_exit() -> void:
	if OS.has_feature("web"):
		_close_modals()
	else:
		get_tree().quit()

func _on_controls_pressed() -> void:
	_show_modal(controls_modal)

func _on_credits_pressed() -> void:
	_show_modal(credits_modal)

func _on_help_pressed() -> void:
	_show_modal(help_modal)

func _show_modal(modal_node: Control) -> void:
	if _sound_synth:
		_sound_synth.play_open()
	if modal_layer:
		modal_layer.visible = true
	if controls_modal: controls_modal.visible = false
	if credits_modal: credits_modal.visible = false
	if help_modal: help_modal.visible = false
	if exit_modal: exit_modal.visible = false
	
	if modal_node:
		modal_node.visible = true
		modal_node.modulate.a = 0.0
		var tw = create_tween()
		if tw:
			tw.tween_property(modal_node, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _close_modals() -> void:
	if modal_layer and modal_layer.visible and _sound_synth:
		_sound_synth.play_close()
	if modal_layer:
		modal_layer.visible = false
	if controls_modal: controls_modal.visible = false
	if credits_modal: credits_modal.visible = false
	if help_modal: help_modal.visible = false
	if exit_modal: exit_modal.visible = false

func _transition_to_scene(target_scene: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 0.0
		var tw = create_tween()
		if tw:
			tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_callback(func():
				if ResourceLoader.exists(target_scene):
					get_tree().change_scene_to_file(target_scene)
				else:
					push_error("Target scene not found: %s" % target_scene)
					_is_transitioning = false
			)
			return
			
	if ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)

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
@onready var btn_settings: Button = $MenuContainer/VBoxButtons/SettingsButton
@onready var btn_exit: Button = $MenuContainer/VBoxButtons/ExitButton

@onready var btn_controls: Button = $BottomRightHUD/HBoxIcons/ControlsButton
@onready var btn_credits: Button = $BottomRightHUD/HBoxIcons/CreditsButton
@onready var btn_help: Button = $BottomRightHUD/HBoxIcons/HelpButton

@onready var modal_layer: Control = $ModalLayer
@onready var controls_modal: Control = $ModalLayer/ControlsModal
@onready var credits_modal: Control = $ModalLayer/CreditsModal
@onready var help_modal: Control = $ModalLayer/HelpModal
@onready var settings_modal: Control = $ModalLayer/SettingsModal
@onready var master_slider: HSlider = $ModalLayer/SettingsModal/Panel/VBox/Grid/MasterSlider
@onready var music_slider: HSlider = $ModalLayer/SettingsModal/Panel/VBox/Grid/MusicSlider
@onready var sfx_slider: HSlider = $ModalLayer/SettingsModal/Panel/VBox/Grid/SFXSlider
@onready var fullscreen_chk: CheckBox = $ModalLayer/SettingsModal/Panel/VBox/Grid/FullscreenChk
@onready var settings_close: Button = $ModalLayer/SettingsModal/Panel/VBox/CloseButton
@onready var exit_modal: Control = $ModalLayer/ExitConfirmModal
@onready var btn_gamepad_toggle: Button = $ModalLayer/ControlsModal/Panel/VBox/Grid/GamepadToggleBtn

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var torch_flicker_1: ColorRect = $AmbientVFX/TorchGlow1
@onready var torch_flicker_2: ColorRect = $AmbientVFX/TorchGlow2
@onready var gate_glow: ColorRect = $AmbientVFX/GateGlow

var _sound_synth: UISoundSynth = null
var _is_transitioning: bool = false
var _anim_time: float = 0.0

var _profile_badge: PanelContainer = null
var _profile_name_lbl: Label = null
var _name_modal: Control = null
var _name_edit: LineEdit = null
var _has_confirmed_name_this_session: bool = false

func _ready() -> void:
	# 0. Apply clean transparent textures from UISliceManager
	if background:
		var bg_tex = UISliceManager.get_start_page_bg()
		if bg_tex:
			background.texture = bg_tex
	if title_logo:
		var logo_tex = UISliceManager.get_title_logo()
		if logo_tex:
			title_logo.texture = logo_tex

	# 1. Initialize Procedural Sound Synthesizer
	_sound_synth = UISoundSynth.get_instance(self)
	
	# 2. Connect Menu Button Signals
	_setup_button(btn_play, _on_play_pressed)
	_setup_button(btn_story, _on_story_pressed)
	_setup_button(btn_leaderboard, _on_leaderboard_pressed)
	_setup_button(btn_settings, _on_settings_pressed)
	_setup_button(btn_exit, _on_exit_pressed)
	
	# 3. Connect Bottom-Right Action Buttons
	_setup_button(btn_controls, _on_controls_pressed)
	_setup_button(btn_credits, _on_credits_pressed)
	_setup_button(btn_help, _on_help_pressed)
	
	# 4. Connect Modal Close Buttons & Settings Controls
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

	if settings_close:
		_setup_button(settings_close, _close_modals)
	if master_slider:
		var m_idx = AudioServer.get_bus_index("Master")
		if m_idx != -1:
			master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(m_idx)) * 100.0
		else:
			master_slider.value = 80.0
		if not master_slider.value_changed.is_connected(_on_volume_changed):
			master_slider.value_changed.connect(_on_volume_changed.bind("Master"))
	if music_slider:
		var mu_idx = AudioServer.get_bus_index("Music")
		if mu_idx != -1:
			music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(mu_idx)) * 100.0
		else:
			music_slider.value = 75.0
		if not music_slider.value_changed.is_connected(_on_volume_changed):
			music_slider.value_changed.connect(_on_volume_changed.bind("Music"))
	if sfx_slider:
		var s_idx = AudioServer.get_bus_index("SFX")
		if s_idx != -1:
			sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(s_idx)) * 100.0
		else:
			sfx_slider.value = 85.0
		if not sfx_slider.value_changed.is_connected(_on_volume_changed):
			sfx_slider.value_changed.connect(_on_volume_changed.bind("SFX"))
	if fullscreen_chk:
		fullscreen_chk.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		if not fullscreen_chk.toggled.is_connected(_on_fullscreen_toggled):
			fullscreen_chk.toggled.connect(_on_fullscreen_toggled)

	if btn_gamepad_toggle:
		_setup_button(btn_gamepad_toggle, _on_gamepad_toggle_pressed)
		_update_gamepad_toggle_ui()

	# 5. Setup Warrior Profile Badge & Name Modal
	_setup_profile_badge()
	_setup_name_modal()
	
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

func _on_settings_pressed() -> void:
	_show_modal(settings_modal)

func _on_volume_changed(val: float, bus_name: String) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		if val <= 0.01:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			var db = linear_to_db(val / 100.0)
			AudioServer.set_bus_volume_db(bus_idx, db)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_exit_pressed() -> void:
	_show_modal(exit_modal)

func _on_confirm_exit() -> void:
	if OS.has_feature("web"):
		var m_idx = AudioServer.get_bus_index("Master")
		if m_idx != -1:
			AudioServer.set_bus_mute(m_idx, true)
		JavaScriptBridge.eval("window.open('', '_self', ''); window.close();")
		_show_web_exit_screen()
	else:
		get_tree().quit()

func _show_web_exit_screen() -> void:
	_close_modals()
	if modal_layer:
		modal_layer.visible = true
	var exit_screen = modal_layer.get_node_or_null("WebExitScreen")
	if not exit_screen:
		exit_screen = Control.new()
		exit_screen.name = "WebExitScreen"
		exit_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		var bg = ColorRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0.04, 0.04, 0.06, 0.98)
		exit_screen.add_child(bg)
		
		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_CENTER)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.offset_left = -250.0
		vbox.offset_top = -100.0
		vbox.offset_right = 250.0
		vbox.offset_bottom = 100.0
		vbox.add_theme_constant_override("separation", 16)
		
		var lbl_title = Label.new()
		lbl_title.text = "✦ FAREWELL, WARRIOR ✦"
		lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_title.add_theme_font_size_override("font_size", 22)
		lbl_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		vbox.add_child(lbl_title)
		
		var lbl_msg = Label.new()
		lbl_msg.text = "Game session ended.\nYou can now safely close this browser tab or window."
		lbl_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_msg.add_theme_font_size_override("font_size", 14)
		lbl_msg.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		vbox.add_child(lbl_msg)

		var btn_return = Button.new()
		btn_return.text = "  ⟲   Return to Title  "
		btn_return.custom_minimum_size = Vector2(160, 36)
		btn_return.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_setup_button(btn_return, func():
			var m_idx = AudioServer.get_bus_index("Master")
			if m_idx != -1:
				AudioServer.set_bus_mute(m_idx, false)
			exit_screen.visible = false
			_close_modals()
		)
		vbox.add_child(btn_return)
		
		exit_screen.add_child(vbox)
		modal_layer.add_child(exit_screen)
	exit_screen.visible = true

func _on_controls_pressed() -> void:
	_update_gamepad_toggle_ui()
	_show_modal(controls_modal)

func _on_gamepad_toggle_pressed() -> void:
	MobileControlsLayer.toggle_gamepad_mode()
	_update_gamepad_toggle_ui()

func _update_gamepad_toggle_ui() -> void:
	if not btn_gamepad_toggle or not is_instance_valid(btn_gamepad_toggle):
		return
	var is_on = MobileControlsLayer.is_gamepad_mode()
	if is_on:
		btn_gamepad_toggle.text = "[ ON ]"
		btn_gamepad_toggle.modulate = Color(1.0, 0.85, 0.3)
	else:
		btn_gamepad_toggle.text = "[ OFF ]"
		btn_gamepad_toggle.modulate = Color(0.7, 0.7, 0.7)

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
	if settings_modal: settings_modal.visible = false
	if exit_modal: exit_modal.visible = false
	if _name_modal: _name_modal.visible = (modal_node == _name_modal)
	
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
	if settings_modal: settings_modal.visible = false
	if exit_modal: exit_modal.visible = false
	if _name_modal: _name_modal.visible = false
	if modal_layer:
		var exit_screen = modal_layer.get_node_or_null("WebExitScreen")
		if exit_screen: exit_screen.visible = false

# ---------------------------------------------------------------------------
# WARRIOR PROFILE BADGE & NAME CUSTOMIZATION MODAL
# ---------------------------------------------------------------------------

func _setup_profile_badge() -> void:
	if _profile_badge and is_instance_valid(_profile_badge):
		_profile_badge.queue_free()

	var mgr = LeaderboardManager.get_instance()
	var profile = mgr.get_player_profile()
	var p_name = profile.get("name", "Warrior")
	var p_id = profile.get("id", "USR-1000")
	var is_google = profile.get("is_google_linked", false)
	var short_id = "GOOGLE" if is_google else (p_id.substr(0, 12) if p_id.length() > 12 else p_id)

	_profile_badge = PanelContainer.new()
	_profile_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_profile_badge.offset_left = -280.0
	_profile_badge.offset_top = 16.0
	_profile_badge.offset_right = -16.0
	_profile_badge.offset_bottom = 54.0

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.11, 0.88)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.85, 0.70, 0.28, 0.8)
	sb.set_corner_radius_all(6)
	_profile_badge.add_theme_stylebox_override("panel", sb)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	_profile_badge.add_child(hbox)

	# Avatar
	var av_rect = TextureRect.new()
	av_rect.custom_minimum_size = Vector2(26, 26)
	av_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var av_tex = UISliceManager.get_avatar(profile.get("avatar", "avatar_4"))
	if av_tex:
		av_rect.texture = av_tex
	hbox.add_child(av_rect)

	# Name & ID
	_profile_name_lbl = Label.new()
	_profile_name_lbl.text = "%s [%s]" % [p_name, short_id]
	_profile_name_lbl.add_theme_font_size_override("font_size", 12)
	_profile_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	_profile_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_profile_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_profile_name_lbl)

	# Google Sign In button (only if not yet linked to Google)
	if not is_google:
		var btn_signin = Button.new()
		btn_signin.name = "BtnGoogleSignIn"
		btn_signin.text = "🔗 Sign In"
		btn_signin.add_theme_font_size_override("font_size", 11)
		btn_signin.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
		var b_sb = StyleBoxFlat.new()
		b_sb.bg_color = Color(0.15, 0.18, 0.28, 0.9)
		b_sb.border_width_left = 1
		b_sb.border_width_top = 1
		b_sb.border_width_right = 1
		b_sb.border_width_bottom = 1
		b_sb.border_color = Color(0.4, 0.6, 1.0, 0.8)
		b_sb.set_corner_radius_all(4)
		btn_signin.add_theme_stylebox_override("normal", b_sb)
		_setup_button(btn_signin, _on_google_signin_pressed)
		hbox.add_child(btn_signin)

	add_child(_profile_badge)

func _on_google_signin_pressed() -> void:
	GoogleAuthManager.get_instance().sign_in(func(ok: bool, info: String):
		if ok:
			var mgr = LeaderboardManager.get_instance()
			var profile = mgr.get_player_profile()
			_setup_profile_badge()
			# If user hasn't chosen their custom name yet, offer the one-time selection dialog
			if not profile.get("is_custom_name_chosen", false):
				_open_one_time_name_modal(profile.get("name", info))
		else:
			print("[StartPage] Google auth failed or canceled: ", info)
	)

func _setup_name_modal() -> void:
	if not modal_layer:
		return

	_name_modal = Control.new()
	_name_modal.name = "NameCustomModal"
	_name_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_name_modal.visible = false

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 230)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -210.0
	panel.offset_top = -115.0
	panel.offset_right = 210.0
	panel.offset_bottom = 115.0

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.97)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.85, 0.70, 0.28, 1.0)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	_name_modal.add_child(panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.offset_left = 20.0
	vb.offset_top = 16.0
	vb.offset_right = -20.0
	vb.offset_bottom = -16.0
	panel.add_child(vb)

	var title = Label.new()
	title.text = "⚔ CHOOSE WARRIOR NAME ⚔"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	vb.add_child(title)

	var desc = Label.new()
	desc.text = "Choose your warrior name carefully!\nThis name can only be chosen ONCE and cannot be changed later."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	vb.add_child(desc)

	var edit_hbox = HBoxContainer.new()
	edit_hbox.add_theme_constant_override("separation", 8)
	vb.add_child(edit_hbox)

	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size = Vector2(250, 36)
	_name_edit.max_length = 16
	_name_edit.placeholder_text = "Enter warrior name..."
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_hbox.add_child(_name_edit)

	var btn_random = Button.new()
	btn_random.text = "🎲 Roll"
	btn_random.custom_minimum_size = Vector2(70, 36)
	_setup_button(btn_random, func():
		if _name_edit:
			_name_edit.text = LeaderboardManager.generate_unique_display_name()
	)
	edit_hbox.add_child(btn_random)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 14)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(btn_hbox)

	var btn_save = Button.new()
	btn_save.text = "Confirm & Lock Name"
	btn_save.custom_minimum_size = Vector2(170, 36)
	var btn_sb = StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.24, 0.17, 0.06, 0.95)
	btn_sb.border_width_left = 1
	btn_sb.border_width_top = 1
	btn_sb.border_width_right = 1
	btn_sb.border_width_bottom = 1
	btn_sb.border_color = Color(0.96, 0.78, 0.24, 1.0)
	btn_sb.set_corner_radius_all(6)
	btn_save.add_theme_stylebox_override("normal", btn_sb)
	btn_save.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	_setup_button(btn_save, _on_save_one_time_name)
	btn_hbox.add_child(btn_save)

	modal_layer.add_child(_name_modal)

func _open_name_modal(default_name: String = "") -> void:
	if default_name.is_empty():
		default_name = LeaderboardManager.get_instance().get_player_profile().get("name", "Warrior")
	_open_one_time_name_modal(default_name)

func _open_one_time_name_modal(default_name: String) -> void:
	if _name_edit:
		_name_edit.text = default_name
	_show_modal(_name_modal)

func _on_save_one_time_name() -> void:
	if _name_edit:
		var mgr = LeaderboardManager.get_instance()
		var chosen = _name_edit.text.strip_edges()
		if chosen.length() >= 3:
			mgr.update_player_name(chosen, true)
			mgr.lock_custom_name()
			_has_confirmed_name_this_session = true
			_setup_profile_badge()
	_close_modals()

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

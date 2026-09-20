class_name LeaderboardPage
extends Control

# The Lost Utsav - Speedrun Leaderboard Page
# Modular, clean presentation using sliced tilesets from leaderboard_elements.png
# Real persistent data store in user://leaderboard_data.json and user://player_profile.json
# Fastest completion time ranks #1.
# Zero ghost text, zero double-rendering, and zero red square glitch.

const SCENE_START_PAGE: String = "res://scenes/ui/start_page.tscn"
const SCENE_STORYLINE: String = "res://scenes/ui/storyline.tscn"

@onready var btn_play: Button = $LeftMenu/VBox/PlayButton
@onready var btn_story: Button = $LeftMenu/VBox/StoryButton
@onready var btn_leaderboard: Button = $LeftMenu/VBox/LeaderboardButton
@onready var btn_settings: Button = $LeftMenu/VBox/SettingsButton
@onready var btn_exit: Button = $LeftMenu/VBox/ExitButton

@onready var background: TextureRect = $Background
@onready var title_logo: TextureRect = $TitleLogo
@onready var header_banner: TextureRect = $HeaderBanner

@onready var tab_all_time: Button = $CenterTableArea/Tabs/AllTimeTab
@onready var tab_this_month: Button = $CenterTableArea/Tabs/ThisMonthTab
@onready var tab_friends: Button = $CenterTableArea/Tabs/FriendsTab

@onready var level_dropdown: OptionButton = $LevelDropdown/OptionButton

@onready var dynamic_table_overlay: Control = $CenterTableArea/DynamicRowsOverlay
@onready var rows_container: VBoxContainer = $CenterTableArea/DynamicRowsOverlay/VBoxRows
@onready var scroll_note: TextureRect = $RightSideArea/ScrollNote

# Profile card nodes
@onready var profile_avatar: TextureRect = $RightSideArea/ProfileCard/VBox/PlayerAvatar
@onready var profile_name_lbl: Label = $RightSideArea/ProfileCard/VBox/PlayerNameLbl
@onready var profile_id_lbl: Label = $RightSideArea/ProfileCard/VBox/PlayerIdLbl
@onready var profile_rank_lbl: Label = $RightSideArea/ProfileCard/VBox/StatsGrid/ValRank
@onready var profile_best_lbl: Label = $RightSideArea/ProfileCard/VBox/StatsGrid/ValBest
@onready var btn_edit_name: Button = $RightSideArea/ProfileCard/VBox/BtnEditName

# Modals
@onready var modal_layer: Control = $ModalLayer
@onready var settings_modal: Control = $ModalLayer/SettingsModal
@onready var master_slider: HSlider = $ModalLayer/SettingsModal/Panel/VBox/Grid/MasterSlider
@onready var music_slider: HSlider = $ModalLayer/SettingsModal/Panel/VBox/Grid/MusicSlider
@onready var sfx_slider: HSlider = $ModalLayer/SettingsModal/Panel/VBox/Grid/SFXSlider
@onready var fullscreen_chk: CheckBox = $ModalLayer/SettingsModal/Panel/VBox/Grid/FullscreenChk
@onready var settings_close: Button = $ModalLayer/SettingsModal/Panel/VBox/CloseButton

@onready var profile_modal: Control = $ModalLayer/ProfileModal
@onready var name_edit: LineEdit = $ModalLayer/ProfileModal/Panel/VBox/NameEdit
@onready var btn_save_name: Button = $ModalLayer/ProfileModal/Panel/VBox/HBoxBtns/SaveNameBtn
@onready var btn_cancel_name: Button = $ModalLayer/ProfileModal/Panel/VBox/HBoxBtns/CancelNameBtn

@onready var fade_overlay: ColorRect = $FadeOverlay

@onready var torch_glow_l: ColorRect = $AmbientVFX/TorchGlowL
@onready var torch_glow_r: ColorRect = $AmbientVFX/TorchGlowR

var _sound_synth: UISoundSynth = null
var _data_manager: LeaderboardManager = null
var _current_tab: String = "all_time"
var _current_level: String = "level_3"
var _is_transitioning: bool = false
var _anim_time: float = 0.0

func _ready() -> void:
	_sound_synth = UISoundSynth.get_instance(self)
	_data_manager = LeaderboardManager.get_instance()

	# 0. Apply clean transparent textures from UISliceManager
	if background:
		var bg_tex = UISliceManager.get_leaderboard_bg()
		if bg_tex:
			background.texture = bg_tex
	if title_logo:
		var logo_tex = UISliceManager.get_title_logo()
		if logo_tex:
			title_logo.texture = logo_tex
	if header_banner:
		var hb_tex = UISliceManager.get_leaderboard_header()
		if hb_tex:
			header_banner.texture = hb_tex
	if scroll_note:
		var sn_tex = UISliceManager.get_scroll_note()
		if sn_tex:
			scroll_note.texture = sn_tex

	# 1. Connect Left Menu Buttons
	_setup_button(btn_play, _on_play_pressed)
	_setup_button(btn_story, _on_story_pressed)
	_setup_button(btn_leaderboard, _on_leaderboard_refresh)
	_setup_button(btn_settings, _on_settings_pressed)
	_setup_button(btn_exit, _on_exit_pressed)

	# 2. Connect Decorative Filter Tabs (Unified time-based view)
	_setup_tab_button(tab_all_time, "all_time")
	_setup_tab_button(tab_this_month, "this_month")
	_setup_tab_button(tab_friends, "friends")

	# 3. Setup Level Dropdown
	if level_dropdown:
		level_dropdown.clear()
		level_dropdown.add_item("LEVEL 3 (FINAL)", 0)
		level_dropdown.add_item("LEVEL 2 (MAZE)", 1)
		level_dropdown.add_item("LEVEL 1 (OUTDOOR)", 2)
		level_dropdown.selected = 0
		if not level_dropdown.item_selected.is_connected(_on_level_selected):
			level_dropdown.item_selected.connect(_on_level_selected)
		level_dropdown.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# 4. Connect Settings Modal with duplicate guard
	if settings_close:
		_setup_button(settings_close, _close_modals)
	if master_slider:
		master_slider.value = 80.0
		if not master_slider.value_changed.is_connected(_on_volume_changed):
			master_slider.value_changed.connect(_on_volume_changed.bind("Master"))
	if music_slider:
		music_slider.value = 75.0
		if not music_slider.value_changed.is_connected(_on_volume_changed):
			music_slider.value_changed.connect(_on_volume_changed.bind("Music"))
	if sfx_slider:
		sfx_slider.value = 85.0
		if not sfx_slider.value_changed.is_connected(_on_volume_changed):
			sfx_slider.value_changed.connect(_on_volume_changed.bind("SFX"))
	if fullscreen_chk:
		fullscreen_chk.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		if not fullscreen_chk.toggled.is_connected(_on_fullscreen_toggled):
			fullscreen_chk.toggled.connect(_on_fullscreen_toggled)

	# 5. Connect Profile Modal & Card
	if btn_edit_name:
		_setup_button(btn_edit_name, _on_edit_name_pressed)
	if btn_save_name:
		_setup_button(btn_save_name, _on_save_name_pressed)
	if btn_cancel_name:
		_setup_button(btn_cancel_name, _close_modals)

	# 6. Scroll Note tooltip
	if scroll_note:
		scroll_note.tooltip_text = "Courage Inspires Others\nEvery fallen warrior lights the path forward."
		scroll_note.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_close_modals()
	_update_tab_visuals()
	_refresh_table_view()
	_update_profile_card()

	# 7. Startup fade-in animation
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0
		var tw = create_tween()
		if tw:
			tw.tween_property(fade_overlay, "modulate:a", 0.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func(): fade_overlay.visible = false)

func _process(delta: float) -> void:
	_anim_time += delta
	if torch_glow_l:
		var fl = 0.22 + 0.10 * sin(_anim_time * 8.5) + 0.05 * cos(_anim_time * 16.0)
		torch_glow_l.modulate.a = clamp(fl, 0.12, 0.42)
	if torch_glow_r:
		var fr = 0.24 + 0.11 * sin(_anim_time * 7.7 + 1.8) + 0.06 * cos(_anim_time * 20.0)
		torch_glow_r.modulate.a = clamp(fr, 0.12, 0.44)

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

func _setup_tab_button(btn: Button, tab_id: String) -> void:
	if not btn:
		return
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func():
		if _sound_synth:
			_sound_synth.play_tab()
		_current_tab = tab_id
		_update_tab_visuals()
		_refresh_table_view()
	)
	btn.mouse_entered.connect(func():
		if _sound_synth:
			_sound_synth.play_hover()
		_button_hover_anim(btn, true)
	)
	btn.mouse_exited.connect(func():
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
		tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _button_press_anim(btn: Button) -> void:
	if not btn or not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var tw = create_tween()
	if not tw:
		return
	btn.scale = Vector2(0.97, 0.97)
	tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE):
		if modal_layer and modal_layer.visible:
			_close_modals()
		else:
			_on_exit_pressed()

func _on_play_pressed() -> void:
	_transition_to_scene(SCENE_STORYLINE)

func _on_story_pressed() -> void:
	_transition_to_scene(SCENE_STORYLINE)

func _on_leaderboard_refresh() -> void:
	_current_tab = "all_time"
	_current_level = "level_3"
	if level_dropdown:
		level_dropdown.selected = 0
	_update_tab_visuals()
	_refresh_table_view()
	_update_profile_card()

func _on_settings_pressed() -> void:
	_show_modal(settings_modal)

func _on_exit_pressed() -> void:
	_transition_to_scene(SCENE_START_PAGE)

func _on_level_selected(index: int) -> void:
	if _sound_synth:
		_sound_synth.play_tab()
	match index:
		0: _current_level = "level_3"
		1: _current_level = "level_2"
		2: _current_level = "level_1"
		_: _current_level = "level_3"
	_refresh_table_view()

func _update_tab_visuals() -> void:
	var active_style = tab_all_time.get_theme_stylebox("normal")
	var normal_style = tab_this_month.get_theme_stylebox("normal")

	if tab_all_time:
		var is_act = (_current_tab == "all_time")
		tab_all_time.add_theme_stylebox_override("normal", active_style if is_act else normal_style)
		tab_all_time.add_theme_color_override("font_color", Color(1, 1, 1) if is_act else Color(0.85, 0.8, 0.7))
	if tab_this_month:
		var is_act = (_current_tab == "this_month")
		tab_this_month.add_theme_stylebox_override("normal", active_style if is_act else normal_style)
		tab_this_month.add_theme_color_override("font_color", Color(1, 1, 1) if is_act else Color(0.85, 0.8, 0.7))
	if tab_friends:
		var is_act = (_current_tab == "friends")
		tab_friends.add_theme_stylebox_override("normal", active_style if is_act else normal_style)
		tab_friends.add_theme_color_override("font_color", Color(1, 1, 1) if is_act else Color(0.85, 0.8, 0.7))

# ---------------------------------------------------------------------------
# DYNAMIC TABLE PRESENTATION (ALWAYS ACTIVE & LOADED FROM DATA STORE)
# ---------------------------------------------------------------------------

func _refresh_table_view() -> void:
	if not dynamic_table_overlay or not rows_container:
		return

	dynamic_table_overlay.visible = true
	dynamic_table_overlay.modulate.a = 1.0

	for child in rows_container.get_children():
		child.queue_free()

	if _data_manager == null:
		_data_manager = LeaderboardManager.get_instance()

	var entries = _data_manager.get_entries(10)
	for entry in entries:
		var row = _create_row_panel(entry)
		rows_container.add_child(row)

func _create_row_panel(entry: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 26)

	var sb = StyleBoxFlat.new()
	var rank: int = entry.get("rank", 1)
	var is_self: bool = entry.get("is_self", false)

	if rank == 1:
		sb.bg_color = Color(0.24, 0.17, 0.06, 0.92)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.96, 0.78, 0.24, 1.0)
		sb.set_corner_radius_all(4)
	elif is_self:
		# Emerald gold highlight for the user
		sb.bg_color = Color(0.08, 0.22, 0.12, 0.92)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.35, 0.92, 0.48, 0.95)
		sb.set_corner_radius_all(4)
	elif rank % 2 == 1:
		sb.bg_color = Color(0.08, 0.09, 0.13, 0.88)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.26, 0.30, 0.38, 0.35)
		sb.set_corner_radius_all(4)
	else:
		sb.bg_color = Color(0.05, 0.06, 0.09, 0.88)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.20, 0.24, 0.30, 0.25)
		sb.set_corner_radius_all(4)

	panel.add_theme_stylebox_override("panel", sb)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	# 1. Rank Label
	var lbl_rank = Label.new()
	lbl_rank.custom_minimum_size = Vector2(32, 24)
	lbl_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_rank.text = str(rank)
	lbl_rank.add_theme_font_size_override("font_size", 12)
	if rank == 1:
		lbl_rank.add_theme_color_override("font_color", Color(1, 0.86, 0.25))
	elif rank == 2:
		lbl_rank.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0))
	elif rank == 3:
		lbl_rank.add_theme_color_override("font_color", Color(0.92, 0.68, 0.45))
	elif is_self:
		lbl_rank.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		lbl_rank.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	hbox.add_child(lbl_rank)

	# 2. Crown Medal
	var crown_type = entry.get("crown", "")
	var crown_rect = TextureRect.new()
	crown_rect.custom_minimum_size = Vector2(28, 24)
	crown_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not crown_type.is_empty():
		var c_tex = UISliceManager.get_crown(crown_type)
		if c_tex:
			crown_rect.texture = c_tex
	hbox.add_child(crown_rect)

	# 3. Avatar Portrait
	var avatar_key = entry.get("avatar", "avatar_0")
	var avatar_rect = TextureRect.new()
	avatar_rect.custom_minimum_size = Vector2(26, 24)
	avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var a_tex = UISliceManager.get_avatar(avatar_key)
	if a_tex:
		avatar_rect.texture = a_tex
	hbox.add_child(avatar_rect)

	# 4. Player Name + Unique ID
	var lbl_player = Label.new()
	lbl_player.custom_minimum_size = Vector2(170, 24)
	lbl_player.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var player_name = entry.get("player", "Warrior")
	var player_id = entry.get("id", "")
	if is_self:
		lbl_player.text = "%s [YOU]" % [player_name]
		lbl_player.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		if player_id.is_empty():
			lbl_player.text = player_name
		else:
			lbl_player.text = "%s [%s]" % [player_name, player_id]
		if rank == 1:
			lbl_player.add_theme_color_override("font_color", Color(1.0, 0.90, 0.50))
		else:
			lbl_player.add_theme_color_override("font_color", Color(0.94, 0.94, 0.94))
	lbl_player.add_theme_font_size_override("font_size", 12)
	hbox.add_child(lbl_player)

	# 5. Level Reached
	var lbl_lvl = Label.new()
	lbl_lvl.custom_minimum_size = Vector2(85, 24)
	lbl_lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_lvl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_lvl.text = str(entry.get("level", 1))
	lbl_lvl.add_theme_font_size_override("font_size", 12)
	lbl_lvl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	hbox.add_child(lbl_lvl)

	# 6. Time (Speedrun completion time)
	var lbl_time = Label.new()
	lbl_time.custom_minimum_size = Vector2(85, 24)
	lbl_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_time.text = entry.get("time", "00:00:00")
	lbl_time.add_theme_font_size_override("font_size", 12)
	if rank == 1:
		lbl_time.add_theme_color_override("font_color", Color(1.0, 0.90, 0.50))
	elif is_self:
		lbl_time.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		lbl_time.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	hbox.add_child(lbl_time)

	# 7. Score
	var lbl_score = Label.new()
	lbl_score.custom_minimum_size = Vector2(85, 24)
	lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_score.text = LeaderboardManager.format_score(entry.get("score", 0))
	lbl_score.add_theme_font_size_override("font_size", 12)
	if rank == 1:
		lbl_score.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	elif is_self:
		lbl_score.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		lbl_score.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	hbox.add_child(lbl_score)

	return panel

func _update_profile_card() -> void:
	if _data_manager == null:
		_data_manager = LeaderboardManager.get_instance()
	var profile = _data_manager.get_player_profile()

	if profile_name_lbl:
		profile_name_lbl.text = profile.get("name", "BraveWarrior")
	if profile_id_lbl:
		profile_id_lbl.text = "[%s]" % profile.get("id", "USR-8492")
	if profile_best_lbl:
		profile_best_lbl.text = profile.get("best_time", "00:33:45")
	if profile_avatar:
		var a_tex = UISliceManager.get_avatar(profile.get("avatar", "avatar_4"))
		if a_tex:
			profile_avatar.texture = a_tex

	# Calculate current rank in leaderboard
	if profile_rank_lbl:
		var user_id = profile.get("id", "")
		var entries = _data_manager.get_entries(999)
		var user_rank = 1
		for entry in entries:
			if entry.get("id") == user_id or entry.get("is_self", false):
				user_rank = entry.get("rank", 1)
				break
		profile_rank_lbl.text = "#%d" % user_rank

# ---------------------------------------------------------------------------
# PROFILE MODAL (WARRIOR NAME CUSTOMIZATION)
# ---------------------------------------------------------------------------

func _on_edit_name_pressed() -> void:
	if profile_modal and name_edit:
		var profile = _data_manager.get_player_profile()
		name_edit.text = profile.get("name", "BraveWarrior")
		_show_modal(profile_modal)

func _on_save_name_pressed() -> void:
	if name_edit:
		var new_name = name_edit.text.strip_edges()
		if not new_name.is_empty():
			_data_manager.update_player_name(new_name)
			_update_profile_card()
			_refresh_table_view()
	_close_modals()

# ---------------------------------------------------------------------------
# MODAL HELPERS & SETTINGS
# ---------------------------------------------------------------------------

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

func _show_modal(modal_node: Control) -> void:
	if _sound_synth:
		_sound_synth.play_open()
	if modal_layer:
		modal_layer.visible = true
	if settings_modal:
		settings_modal.visible = (modal_node == settings_modal)
	if profile_modal:
		profile_modal.visible = (modal_node == profile_modal)
	if modal_node:
		modal_node.modulate.a = 0.0
		var tw = create_tween()
		if tw:
			tw.tween_property(modal_node, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _close_modals() -> void:
	if modal_layer and modal_layer.visible and _sound_synth:
		_sound_synth.play_close()
	if modal_layer:
		modal_layer.visible = false
	if settings_modal:
		settings_modal.visible = false
	if profile_modal:
		profile_modal.visible = false

func _transition_to_scene(target_scene: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 0.0
		var tw = create_tween()
		if tw:
			tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
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

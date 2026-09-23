class_name MobileControlsLayer
extends CanvasLayer

## Global Mobile Controls System for "The Lost Utsav"
## Dynamically configures virtual joystick & combat buttons per level context.
## Supports Gamepad/Touch mode toggle: OFF by default on PC, ON on Mobile.

const SETTINGS_PATH: String = "user://game_settings.cfg"
const ICON_INTERACT_DEFAULT = preload("res://assets/ui/mobile/btn_interact.png")
const ICON_ROCK_THROW = preload("res://assets/environment/rock_small_01.png")
static var gamepad_mode: bool = false
static var _initialized: bool = false
static var _instance: MobileControlsLayer = null

signal gamepad_mode_changed(is_enabled: bool)

@onready var root_control: Control = $RootControl
@onready var joystick: Control = $RootControl/JoystickZone/VirtualJoystick
@onready var btn_axe: Control = $RootControl/ButtonsZone/AxeButton
@onready var btn_pasa: Control = $RootControl/ButtonsZone/PasaButton
@onready var btn_jump: Control = $RootControl/ButtonsZone/JumpButton
@onready var btn_interact: Control = $RootControl/ButtonsZone/InteractButton
@onready var btn_transform: Control = $RootControl/ButtonsZone/TransformButton

var _cached_player: Node = null
var _last_scene_path: String = ""

static func is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.get_name() in ["Android", "iOS"]

static func _load_settings() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SETTINGS_PATH)
	if err == OK and cfg.has_section_key("controls", "gamepad_mode"):
		gamepad_mode = cfg.get_value("controls", "gamepad_mode", false)
	else:
		# Default: ON for mobile platforms, OFF for PC/desktop!
		gamepad_mode = is_mobile_platform()

static func set_gamepad_mode(enabled: bool) -> void:
	gamepad_mode = enabled
	var cfg = ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("controls", "gamepad_mode", gamepad_mode)
	cfg.save(SETTINGS_PATH)
	if is_instance_valid(_instance):
		_instance._update_for_current_scene()
		_instance.gamepad_mode_changed.emit(gamepad_mode)

static func toggle_gamepad_mode() -> bool:
	set_gamepad_mode(not gamepad_mode)
	return gamepad_mode

static func is_gamepad_mode() -> bool:
	if not _initialized:
		_load_settings()
		_initialized = true
	return gamepad_mode

func _ready() -> void:
	_instance = self
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _initialized:
		_load_settings()
		_initialized = true
		
	_ensure_input_actions()
	_update_for_current_scene()
	get_tree().node_added.connect(_on_node_added)

func _unhandled_input(event: InputEvent) -> void:
	# Quick toggle for PC testing: Press F1 to toggle Gamepad / Touch controls
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F1:
			toggle_gamepad_mode()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	var tree = get_tree()
	if not tree:
		return
	var current_scene = tree.current_scene
	if not current_scene:
		return
		
	var path = current_scene.scene_file_path
	if path != _last_scene_path:
		_last_scene_path = path
		_update_for_current_scene()

	if not root_control.visible:
		return

	# Dynamic combat updates: cooldown sweeps & divine glow
	if is_instance_valid(_cached_player):
		# Cooldown sweeps & seconds display per weapon
		if btn_axe.visible or btn_pasa.visible:
			var axe_sec: float = 0.0
			var axe_ratio: float = 0.0
			var pasa_sec: float = 0.0
			var pasa_ratio: float = 0.0
			if _cached_player.has_method("get_attack_cooldown_remaining"):
				axe_sec = _cached_player.get_attack_cooldown_remaining("axe")
				pasa_sec = _cached_player.get_attack_cooldown_remaining("rope")
			if _cached_player.has_method("get_attack_cooldown_ratio"):
				axe_ratio = _cached_player.get_attack_cooldown_ratio("axe")
				pasa_ratio = _cached_player.get_attack_cooldown_ratio("rope")
			btn_axe.set_cooldown(axe_sec, axe_ratio)
			btn_pasa.set_cooldown(pasa_sec, pasa_ratio)

		# Dynamic combat glow updates for minion throw or special attack
		var is_holding = ("held_chota_asur" in _cached_player) and is_instance_valid(_cached_player.held_chota_asur)
		if is_holding:
			if not btn_pasa.is_special_glow:
				btn_pasa.is_special_glow = true
				btn_pasa.special_badge_text = "THROW!"
		elif ("combo_hits" in _cached_player) and ("COMBO_MAX" in _cached_player):
			if _cached_player.combo_hits >= _cached_player.COMBO_MAX:
				if not btn_pasa.is_special_glow or btn_pasa.special_badge_text != "SPECIAL!":
					btn_pasa.is_special_glow = true
					btn_pasa.special_badge_text = "SPECIAL!"
			else:
				if btn_pasa.is_special_glow:
					btn_pasa.is_special_glow = false
	else:
		_find_player()

	# Dynamic Interact button updates (Rock Grab / Throw, Blessing Claim, Exit)
	update_interact_visuals(current_scene)

func update_interact_visuals(current_scene: Node) -> void:
	if not is_instance_valid(btn_interact):
		btn_interact = get_node_or_null("RootControl/ButtonsZone/InteractButton")
		if not is_instance_valid(btn_interact):
			return
	if not current_scene:
		return
		
	var is_carrying_rock = false
	if is_instance_valid(_cached_player) and ("is_carrying" in _cached_player) and _cached_player.is_carrying:
		is_carrying_rock = true
	if ("held_rock" in current_scene) and is_instance_valid(current_scene.held_rock):
		is_carrying_rock = true
		
	var is_holding_minion = false
	if is_instance_valid(_cached_player) and ("held_chota_asur" in _cached_player) and is_instance_valid(_cached_player.held_chota_asur):
		is_holding_minion = true

	if is_carrying_rock:
		btn_interact.set_button_visuals("THROW", ICON_ROCK_THROW, true, "THROW!", Color(1.0, 0.45, 0.15))
	elif is_holding_minion:
		btn_interact.set_button_visuals("THROW", ICON_INTERACT_DEFAULT, true, "THROW!", Color(1.0, 0.50, 0.20))
	elif ("nearby_rock" in current_scene) and is_instance_valid(current_scene.nearby_rock):
		btn_interact.set_button_visuals("GRAB", ICON_ROCK_THROW, true, "GRAB", Color(0.95, 0.8, 0.25))
	elif ("player_near_altar" in current_scene) and current_scene.player_near_altar:
		var blessing_done = ("blessing_claimed" in current_scene and current_scene.blessing_claimed) or ("blessing_in_progress" in current_scene and current_scene.blessing_in_progress)
		if not blessing_done:
			btn_interact.set_button_visuals("BLESSING", ICON_INTERACT_DEFAULT, true, "CLAIM!", Color(1.0, 0.88, 0.2))
		else:
			btn_interact.set_button_visuals("INTERACT", ICON_INTERACT_DEFAULT, false, "", Color(0.9, 0.72, 0.25))
	elif ("player_near_exit" in current_scene) and current_scene.player_near_exit:
		btn_interact.set_button_visuals("EXIT", ICON_INTERACT_DEFAULT, true, "ENTER", Color(0.9, 0.8, 0.3))
	else:
		btn_interact.set_button_visuals("INTERACT", ICON_INTERACT_DEFAULT, false, "", Color(0.9, 0.72, 0.25))

func _ensure_input_actions() -> void:
	var actions = [
		"move_left", "move_right", "move_up", "move_down",
		"jump", "attack_axe", "attack_rope", "interact", "transform_1"
	]
	for act in actions:
		if not InputMap.has_action(act):
			InputMap.add_action(act)

func _update_for_current_scene() -> void:
	# 0. Check Gamepad Mode setting: If disabled (default on PC), keep controls hidden
	if not gamepad_mode:
		root_control.visible = false
		_release_all_inputs()
		_cached_player = null
		return

	var current_scene = get_tree().current_scene
	if not current_scene:
		root_control.visible = false
		return
		
	var path = current_scene.scene_file_path.to_lower()
	var sname = current_scene.name.to_lower()
	
	# Release any pressed touch inputs on scene transition
	_release_all_inputs()
	
	# 1. Menus, Loading, and Cutscenes: Hide completely
	var is_menu = (
		"start_page" in path or "start_page" in sname or
		"storyline" in path or "storyline" in sname or
		"level_select" in path or "level_select" in sname or
		"leaderboard" in path or "leaderboard" in sname or
		"credits" in path or "credits" in sname or
		"loading_screen" in path or "loading_screen" in sname
	)
	
	if is_menu:
		root_control.visible = false
		_cached_player = null
		return
		
	# Active Gameplay Level: Show Mobile Controls
	root_control.visible = true
	_find_player()
	
	# 2. Level Case: Level 2 Underground Maze
	# Strictly NO ATTACKS since player is in sacred mouse form navigating the maze
	var is_maze = ("maze" in path or "maze" in sname)
	var grm = get_node_or_null("/root/GameRunManager")
	if grm and ("current_level_num" in grm) and grm.current_level_num == 2:
		is_maze = true
		
	if is_maze:
		joystick.visible = true
		btn_jump.visible = true
		btn_interact.visible = true
		# NO ATTACKS AT MAZE
		btn_axe.visible = false
		btn_pasa.visible = false
		btn_transform.visible = false
		return

	# 3. Level Case: Level 3 Asur's Arena (Boss Battle)
	# Full combat with special glow, no mouse form
	var is_l3 = ("l3" in path or "l3" in sname or "arena" in path)
	if grm and ("current_level_num" in grm) and grm.current_level_num == 3:
		is_l3 = true
		
	if is_l3:
		joystick.visible = true
		btn_jump.visible = true
		btn_axe.visible = true
		btn_pasa.visible = true
		btn_interact.visible = true
		btn_transform.visible = false
		return

	# 4. Level Case: Level 1 (The Great Gate / L1 Maps)
	# Traversal, puzzles, combat, and Mushika transformation
	joystick.visible = true
	btn_jump.visible = true
	btn_axe.visible = true
	btn_pasa.visible = true
	btn_interact.visible = true
	btn_transform.visible = true

func _find_player() -> void:
	var tree = get_tree()
	if not tree:
		return
	var players = tree.get_nodes_in_group("player")
	if players.size() > 0:
		_set_player(players[0])
		return
		
	var current = tree.current_scene
	if current:
		var p = current.find_child("Player", true, false)
		if p:
			_set_player(p)

func _set_player(p: Node) -> void:
	if _cached_player == p:
		return
	_cached_player = p
	if _cached_player.has_signal("divine_energy_changed"):
		if not _cached_player.is_connected("divine_energy_changed", _on_divine_energy_changed):
			_cached_player.connect("divine_energy_changed", _on_divine_energy_changed)
			
	# Initial combo check
	if "combo_hits" in _cached_player and "COMBO_MAX" in _cached_player:
		_on_divine_energy_changed(_cached_player.combo_hits, _cached_player.COMBO_MAX)

func _on_divine_energy_changed(combo_hits: int, max_combo: int) -> void:
	if not is_instance_valid(btn_pasa):
		return
		
	if combo_hits >= max_combo:
		btn_pasa.is_special_glow = true
		btn_pasa.special_badge_text = "SPECIAL!"
	else:
		if is_instance_valid(_cached_player) and ("held_chota_asur" in _cached_player) and is_instance_valid(_cached_player.held_chota_asur):
			btn_pasa.is_special_glow = true
			btn_pasa.special_badge_text = "THROW!"
		else:
			btn_pasa.is_special_glow = false

func _on_node_added(node: Node) -> void:
	if node.is_in_group("player") or node.name == "Player":
		call_deferred("_find_player")

func _release_all_inputs() -> void:
	if is_instance_valid(joystick):
		joystick.release_all_inputs()
	if is_instance_valid(btn_axe):
		btn_axe.release_now()
	if is_instance_valid(btn_pasa):
		btn_pasa.release_now()
	if is_instance_valid(btn_jump):
		btn_jump.release_now()
	if is_instance_valid(btn_interact):
		btn_interact.release_now()
	if is_instance_valid(btn_transform):
		btn_transform.release_now()

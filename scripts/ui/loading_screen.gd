class_name LoadingScreen
extends Control

## Interactive Loading Screen with Authentic Indian Fantasy Aesthetics & Runner Mini-Game
## - Features Hero & Mushika running atop the castle parapet with perfect ground alignment.
## - Fully decoupled mini-game controls: [SPACE / W / Up] or clicking runner area ALWAYS jumps.
## - Dedicated stage entry button: [ENTER] or clicking button confirms entry once loaded.
## - Golden lotus jewel centered on progress bar with diamond caps and live percentage.
## - Seamless parallax mountains, blood moon, hanging banners, braziers, and corner mandalas.

# Header nodes
@onready var logo_rect: TextureRect = $Header/LogoRect
@onready var tips_box: PanelContainer = $Header/TipsBox
@onready var tip_title_lbl: Label = $Header/TipsBox/MarginContainer/HBox/VBox/TipTitle
@onready var tip_quote_lbl: Label = $Header/TipsBox/MarginContainer/HBox/VBox/TipQuote
@onready var emblem_rect: TextureRect = $Header/TipsBox/MarginContainer/HBox/EmblemRect
@onready var score_label: Label = $Header/ScoreContainer/Margin/ScoreLabel

# Mini-game nodes
@onready var mini_game_area: Control = $MiniGameArea
@onready var parallax_bg1: TextureRect = $ParallaxBackdrop/BG1
@onready var parallax_bg2: TextureRect = $ParallaxBackdrop/BG2
@onready var cloud1: TextureRect = $ParallaxBackdrop/Cloud1
@onready var cloud2: TextureRect = $ParallaxBackdrop/Cloud2
@onready var moon_rect: TextureRect = $ParallaxBackdrop/Moon
@onready var ground_track1: TextureRect = $Ground/Track1
@onready var ground_track2: TextureRect = $Ground/Track2
@onready var player_sprite: TextureRect = $Entities/PlayerSprite
@onready var mushika_sprite: TextureRect = $Entities/MushikaSprite
@onready var obstacles_container: Control = $Entities/Obstacles
@onready var collectibles_container: Control = $Entities/Collectibles

# Bottom section nodes
@onready var progress_bar: ProgressBar = $BottomSection/VBox/LoadingBarSection/BarStack/ProgressBar
@onready var lotus_center: TextureRect = $BottomSection/VBox/LoadingBarSection/BarStack/LotusCenter
@onready var percent_label: Label = $BottomSection/VBox/LoadingBarSection/PercentLabel
@onready var level_title_lbl: Label = $BottomSection/VBox/TitleLabel
@onready var level_subtitle_lbl: Label = $BottomSection/VBox/SubtitleLabel
@onready var enter_button: Button = $BottomSection/VBox/ButtonCenter/EnterButton
@onready var key_badge: PanelContainer = $BottomSection/VBox/ButtonCenter/EnterButton/Margin/HBox/KeyBadge
@onready var action_prompt_lbl: Label = $BottomSection/VBox/ButtonCenter/EnterButton/Margin/HBox/ActionPrompt

# Overlays
@onready var corner_overlay: Control = $CornerOverlay
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var game_over_score: Label = $GameOverOverlay/Panel/Margin/VBox/Score
@onready var restart_button: Button = $GameOverOverlay/Panel/Margin/VBox/RestartButton

# Lore pool
const LORE_TIPS: Array[String] = [
	"\"Faith turns distance into destiny.\"",
	"\"Even a small step makes a difference.\"",
	"\"Courage lights the path through the darkest fortress.\"",
	"\"Sacred Modaks bestow divine speed upon the faithful.\"",
	"\"Mushika's tiny steps unlock great fortress secrets.\"",
	"\"The Great Demon King Mahishasur awaits in the abyss.\""
]

# Mini-game physics & dimensions
# Ground surface is at y = 415.0
const RUN_SPEED: float = 240.0
const PARALLAX_SPEED: float = 28.0
const CLOUD_SPEED_1: float = 14.0
const CLOUD_SPEED_2: float = 9.0
const GROUND_TOP_Y: float = 415.0

# Player sprite height is 56px, feet at y ~ 56 -> GROUND_Y = 359.0 (359 + 56 = 415.0)
const PLAYER_GROUND_Y: float = 359.0
# Mushika sprite height is 45px, feet at y ~ 41.25 -> MUSHIKA_GROUND_Y = 374.0 (374 + 41.25 = 415.25)
const MUSHIKA_GROUND_Y: float = 374.0

const GRAVITY: float = 1400.0
const JUMP_VELOCITY: float = -520.0
const MUSHIKA_JUMP_VELOCITY: float = -480.0

# Textures
var player_walk_frames: Array[Texture2D] = []
var player_jump_tex: Texture2D = null
var mushika_run_frames: Array[Texture2D] = []
var modak_tex: Texture2D = null
var spike_tex: Texture2D = null
var crate_tex: Texture2D = null
var brazier_tex: Texture2D = null

# Mini-game state
var is_game_over: bool = false
var is_jumping: bool = false
var player_y: float = PLAYER_GROUND_Y
var player_vy: float = 0.0
var mushika_y: float = MUSHIKA_GROUND_Y
var mushika_vy: float = 0.0

var walk_frame_timer: float = 0.0
var current_walk_frame: int = 0
var mushika_frame_timer: float = 0.0
var current_mushika_frame: int = 0

var bg_scroll: float = 0.0
var ground_scroll: float = 0.0
var obstacle_spawn_timer: float = 1.4
var modak_spawn_timer: float = 2.2

var active_obstacles: Array[Dictionary] = []
var active_modaks: Array[Dictionary] = []

var mini_score: int = 0
var score_tick_timer: float = 0.0
var invulnerable_timer: float = 0.0

# Loading state
var target_path: String = ""
var load_progress: float = 0.0
var is_load_complete: bool = false
var is_transitioning_to_stage: bool = false
var min_load_time: float = 2.0
var elapsed_load_time: float = 0.0
var ready_pulse_timer: float = 0.0
var sound_synth: UISoundSynth = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sound_synth = UISoundSynth.get_instance(self)

	_init_typography()
	_load_mini_game_assets()
	_setup_corner_mandala()
	_setup_load_parameters()
	_setup_initial_positions()
	_connect_button_signals()
	_start_background_loading()

func _setup_initial_positions() -> void:
	player_y = PLAYER_GROUND_Y
	player_sprite.position = Vector2(150, player_y)
	mushika_y = MUSHIKA_GROUND_Y
	mushika_sprite.position = Vector2(95, mushika_y)

	progress_bar.value = 0.0
	percent_label.text = "0%"

	# Initial button appearance: subtle loading state without Enter badge
	enter_button.focus_mode = Control.FOCUS_NONE
	enter_button.modulate.a = 0.55
	if key_badge:
		key_badge.visible = false
	if action_prompt_lbl:
		action_prompt_lbl.text = "LOADING STAGE..."

	if score_label:
		score_label.text = "◆ SCORE: 0000 ◆"

	if game_over_overlay:
		game_over_overlay.visible = false

	# Screen fade-in
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0
		var tw = create_tween()
		tw.tween_property(fade_overlay, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _connect_button_signals() -> void:
	if enter_button:
		enter_button.mouse_entered.connect(_on_enter_button_mouse_entered)
		enter_button.pressed.connect(_on_enter_button_pressed)

	if restart_button:
		restart_button.mouse_entered.connect(func():
			if sound_synth:
				sound_synth.play_hover()
		)
		restart_button.pressed.connect(_on_restart_button_pressed)

	if mini_game_area:
		mini_game_area.gui_input.connect(_on_mini_game_gui_input)

func _setup_corner_mandala() -> void:
	if corner_overlay:
		corner_overlay.draw.connect(_draw_corner_mandalas)
		corner_overlay.queue_redraw()

func _draw_corner_mandalas() -> void:
	var color_gold = Color(0.72, 0.54, 0.22, 0.22)
	var color_gold_accent = Color(0.92, 0.75, 0.35, 0.28)

	# Bottom-Left Flourish
	_draw_mandala_cluster(Vector2(40, 680), color_gold, color_gold_accent, 1.0)

	# Bottom-Right Flourish
	_draw_mandala_cluster(Vector2(980, 680), color_gold, color_gold_accent, -1.0)

func _draw_mandala_cluster(center: Vector2, col: Color, accent: Color, dir_x: float) -> void:
	# Concentric ornate arcs
	for r in [28.0, 48.0, 68.0]:
		corner_overlay.draw_arc(center, r, -PI * 0.5, 0.0 if dir_x > 0 else PI, 16, col, 1.5, true)

	# Petal flourishes
	for i in range(5):
		var angle = -PI * 0.5 + float(i) * (PI * 0.125) * dir_x
		var pt1 = center + Vector2(cos(angle), sin(angle)) * 36.0
		var pt2 = center + Vector2(cos(angle), sin(angle)) * 54.0
		corner_overlay.draw_line(pt1, pt2, accent, 1.2, true)

func _init_typography() -> void:
	var serif_font = SystemFont.new()
	serif_font.font_names = PackedStringArray(["Cinzel", "Palatino Linotype", "Palatino", "Georgia", "Times New Roman", "serif"])
	serif_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO

	if level_title_lbl:
		level_title_lbl.add_theme_font_override("font", serif_font)
	if level_subtitle_lbl:
		level_subtitle_lbl.add_theme_font_override("font", serif_font)
	if tip_title_lbl:
		tip_title_lbl.add_theme_font_override("font", serif_font)
	if tip_quote_lbl:
		tip_quote_lbl.add_theme_font_override("font", serif_font)
		randomize()
		tip_quote_lbl.text = LORE_TIPS[randi() % LORE_TIPS.size()]
	if score_label:
		score_label.add_theme_font_override("font", serif_font)
	if action_prompt_lbl:
		action_prompt_lbl.add_theme_font_override("font", serif_font)

func _load_mini_game_assets() -> void:
	# Hero walk frames (0 to 7)
	for i in range(8):
		var p = "res://assets/character/frames/walk_right_%d.png" % i
		if ResourceLoader.exists(p):
			player_walk_frames.append(load(p))

	# Hero jump texture
	if ResourceLoader.exists("res://assets/character/frames/jump_right_2.png"):
		player_jump_tex = load("res://assets/character/frames/jump_right_2.png")
	elif player_walk_frames.size() > 0:
		player_jump_tex = player_walk_frames[0]

	# Clean authentic Mushika walk frames (0 to 5)
	for i in range(6):
		var p = "res://assets/character/mushika/frames/mouse_walk_right_%d.png" % i
		if ResourceLoader.exists(p):
			mushika_run_frames.append(load(p))

	# Fallback if needed
	if mushika_run_frames.is_empty():
		for i in range(3):
			var p = "res://assets/temp/mushika_run_%d.png" % i
			if ResourceLoader.exists(p):
				mushika_run_frames.append(load(p))

	# Collectible Modak
	if ResourceLoader.exists("res://assets/collectibles/modak/modak_0.png"):
		modak_tex = load("res://assets/collectibles/modak/modak_0.png")

	# Obstacles
	if ResourceLoader.exists("res://assets/temp/user_real_crate.png"):
		crate_tex = load("res://assets/temp/user_real_crate.png")

	if ResourceLoader.exists("res://assets/asur/frames/asur_spikes_down_2.png"):
		spike_tex = load("res://assets/asur/frames/asur_spikes_down_2.png")
	elif ResourceLoader.exists("res://assets/vfx/asur_spikes.png"):
		spike_tex = load("res://assets/vfx/asur_spikes.png")

	if ResourceLoader.exists("res://assets/environment/brazier_flaming.png"):
		brazier_tex = load("res://assets/environment/brazier_flaming.png")

func _setup_load_parameters() -> void:
	var info = SceneLoader.get_load_info()
	target_path = info.get("path", "")
	if target_path.is_empty():
		target_path = "res://scenes/levels/outdoor/outdoor_map.tscn"
		SceneLoader.target_scene_path = target_path

	var title = info.get("title", "LOADING LEVEL 1")
	var subtitle = info.get("subtitle", "Preparing the fortress...")

	level_title_lbl.text = title.to_upper()
	level_subtitle_lbl.text = subtitle

	var grm = get_node_or_null("/root/GameRunManager")
	if grm:
		grm.pause_run_timer()

func _start_background_loading() -> void:
	if target_path.is_empty():
		target_path = "res://scenes/levels/outdoor/outdoor_map.tscn"
		SceneLoader.target_scene_path = target_path


	if not ResourceLoader.exists(target_path):
		push_error("[LoadingScreen] Target scene not found: %s" % target_path)
		is_load_complete = true
		_on_loading_finished()
		return

	var err = ResourceLoader.load_threaded_request(target_path, "", false)
	if err != OK:
		push_warning("[LoadingScreen] load_threaded_request returned %s, fallback to sync load." % err)

func _process(delta: float) -> void:
	_update_threaded_loader(delta)
	_update_mini_game(delta)
	_update_ready_button_pulse(delta)

func _update_threaded_loader(delta: float) -> void:
	elapsed_load_time += delta
	var time_ratio = clampf(elapsed_load_time / min_load_time, 0.0, 1.0)

	if not is_load_complete:
		var progress_arr: Array = []
		var status = ResourceLoader.load_threaded_get_status(target_path, progress_arr)

		var raw_pct = 0.0
		if progress_arr.size() > 0:
			raw_pct = progress_arr[0]

		var simulated_target = time_ratio * 0.94
		var target_visual = maxf(raw_pct * 0.95, simulated_target)
		if status == ResourceLoader.THREAD_LOAD_LOADED and time_ratio >= 1.0:
			target_visual = 1.0

		load_progress = move_toward(load_progress, target_visual, delta * 1.6)

		if status == ResourceLoader.THREAD_LOAD_LOADED and time_ratio >= 1.0 and load_progress >= 0.999:
			load_progress = 1.0
			is_load_complete = true
			var loaded_res = ResourceLoader.load_threaded_get(target_path)
			if loaded_res is PackedScene:
				SceneLoader.loaded_packed_scene = loaded_res
			SceneLoader.pre_instantiate_target()
			_on_loading_finished()
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			load_progress = 1.0
			is_load_complete = true
			if ResourceLoader.exists(target_path):
				SceneLoader.loaded_packed_scene = load(target_path)
			SceneLoader.pre_instantiate_target()
			_on_loading_finished()


	progress_bar.value = load_progress * 100.0
	percent_label.text = "%d%%" % int(load_progress * 100.0)

func _on_loading_finished() -> void:
	progress_bar.value = 100.0
	percent_label.text = "100%"

	enter_button.modulate.a = 1.0
	if key_badge:
		key_badge.visible = true
	if action_prompt_lbl:
		action_prompt_lbl.text = "or CLICK TO ENTER"
	level_subtitle_lbl.text = "Fortress ready. Enter when prepared."

	if lotus_center:
		lotus_center.pivot_offset = lotus_center.size * 0.5
		var tw = create_tween().set_loops()
		tw.tween_property(lotus_center, "scale", Vector2(1.15, 1.15), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(lotus_center, "scale", Vector2(1.0, 1.0), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	print("[LoadingScreen] Level fully loaded! Mini-game remains playable until Enter is confirmed.")

func _update_ready_button_pulse(delta: float) -> void:
	if not is_load_complete or is_transitioning_to_stage:
		return

	ready_pulse_timer += delta * 3.5
	var alpha_pulse = 0.88 + 0.12 * sin(ready_pulse_timer)
	enter_button.modulate = Color(1.0, 1.0, 1.0, alpha_pulse)

# ==============================================================================
# Decoupled Controls: JUMP always works; ENTER confirms stage entry
# ==============================================================================
# Decoupled Controls: JUMP always works; ENTER confirms stage entry
# ==============================================================================
func _input(event: InputEvent) -> void:
	if is_transitioning_to_stage:
		return

	# Stage confirmation key: KEY_ENTER or KEY_KP_ENTER
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if is_load_complete:
				_enter_stage()
				get_viewport().set_input_as_handled()
				return

	# If Game Over: Space, W, or Up restarts the runner!
	if is_game_over:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.keycode == KEY_SPACE or event.keycode == KEY_W or event.keycode == KEY_UP)):
			_restart_mini_game()
			get_viewport().set_input_as_handled()
			return
		return

	# Mini-game jump inputs: SPACE, W, UP, or ui_up action
	# IMPORTANT: Space NEVER triggers _enter_stage(), so mini-game is always playable!
	if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.keycode == KEY_SPACE or event.keycode == KEY_W or event.keycode == KEY_UP)):
		_trigger_jump()
		get_viewport().set_input_as_handled()

func _on_mini_game_gui_input(event: InputEvent) -> void:
	if is_transitioning_to_stage:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_game_over:
			_restart_mini_game()
		else:
			_trigger_jump()

func _on_restart_button_pressed() -> void:
	_restart_mini_game()

func _on_enter_button_mouse_entered() -> void:
	if is_load_complete and sound_synth:
		sound_synth.play_hover()

func _on_enter_button_pressed() -> void:
	if is_load_complete:
		_enter_stage()

func _trigger_jump() -> void:
	if is_game_over:
		return
	if not is_jumping:
		is_jumping = true
		player_vy = JUMP_VELOCITY
		mushika_vy = MUSHIKA_JUMP_VELOCITY
		if sound_synth:
			sound_synth.play_hover()

func _trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	if sound_synth:
		sound_synth.play_close()

	# Fade active collectibles & obstacles so they never overlap the Game Over modal
	for m in active_modaks:
		if is_instance_valid(m.get("node")):
			var tw_m = create_tween()
			tw_m.tween_property(m["node"], "modulate:a", 0.0, 0.18)
	for obs in active_obstacles:
		if is_instance_valid(obs.get("node")):
			var tw_o = create_tween()
			tw_o.tween_property(obs["node"], "modulate:a", 0.3, 0.18)

	if game_over_score:
		game_over_score.text = "SCORE: %04d" % mini_score
	if game_over_overlay:
		game_over_overlay.visible = true
		game_over_overlay.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(game_over_overlay, "modulate:a", 1.0, 0.22)
	if score_label:
		var tw_s = create_tween()
		tw_s.tween_property(score_label, "modulate", Color(1.0, 0.35, 0.35), 0.15)

func _restart_mini_game() -> void:
	if is_transitioning_to_stage:
		return
	is_game_over = false
	if game_over_overlay:
		game_over_overlay.visible = false
	mini_score = 0
	if score_label:
		score_label.modulate = Color.WHITE
		score_label.text = "◆ SCORE: 0000 ◆"
	is_jumping = false
	player_y = PLAYER_GROUND_Y
	player_vy = 0.0
	mushika_y = MUSHIKA_GROUND_Y
	mushika_vy = 0.0
	player_sprite.position.y = player_y
	mushika_sprite.position.y = mushika_y
	invulnerable_timer = 0.8
	obstacle_spawn_timer = 1.6
	modak_spawn_timer = 2.4

	# Clear active obstacles
	for obs in active_obstacles:
		if is_instance_valid(obs.get("node")):
			obs["node"].queue_free()
	active_obstacles.clear()

	# Clear active modaks
	for m in active_modaks:
		if is_instance_valid(m.get("node")):
			m["node"].queue_free()
	active_modaks.clear()

	if sound_synth:
		sound_synth.play_tab()

func _enter_stage() -> void:
	if is_transitioning_to_stage:
		return
	is_transitioning_to_stage = true

	if sound_synth:
		sound_synth.play_click()

	if SceneLoader.target_scene_path.is_empty():
		SceneLoader.target_scene_path = target_path

	# Delegate transition and fading directly to SceneLoader's persistent curtain
	SceneLoader.enter_loaded_stage()


# ==============================================================================
# Mini-Game Runner Engine
# ==============================================================================
func _update_mini_game(delta: float) -> void:
	# 1. Subtle cloud drifting
	if cloud1:
		cloud1.position.x -= CLOUD_SPEED_1 * delta
		if cloud1.position.x < -160.0:
			cloud1.position.x = 1060.0
	if cloud2:
		cloud2.position.x -= CLOUD_SPEED_2 * delta
		if cloud2.position.x < -180.0:
			cloud2.position.x = 1080.0

	# When Game Over: pause world movement and physics
	if is_game_over:
		return

	# 2. Parallax background mountains scrolling (1665px width loop)
	bg_scroll += PARALLAX_SPEED * delta
	var bg_width = 1665.0
	if parallax_bg1 and parallax_bg2:
		parallax_bg1.position.x = -fposmod(bg_scroll, bg_width)
		parallax_bg2.position.x = parallax_bg1.position.x + bg_width

	# 3. Ground parapet scrolling (1024px width loop)
	ground_scroll += RUN_SPEED * delta
	var ground_width = 1024.0
	if ground_track1 and ground_track2:
		ground_track1.position.x = -fposmod(ground_scroll, ground_width)
		ground_track2.position.x = ground_track1.position.x + ground_width

	# 4. Jump physics
	if is_jumping:
		player_vy += GRAVITY * delta
		player_y += player_vy * delta

		mushika_vy += GRAVITY * delta
		mushika_y += mushika_vy * delta

		if player_y >= PLAYER_GROUND_Y:
			player_y = PLAYER_GROUND_Y
			player_vy = 0.0
			is_jumping = false

		if mushika_y >= MUSHIKA_GROUND_Y:
			mushika_y = MUSHIKA_GROUND_Y
			mushika_vy = 0.0

		if player_jump_tex:
			player_sprite.texture = player_jump_tex
	else:
		# Walking animation frames
		walk_frame_timer += delta * 12.0
		if walk_frame_timer >= 1.0:
			walk_frame_timer -= 1.0
			if player_walk_frames.size() > 0:
				current_walk_frame = (current_walk_frame + 1) % player_walk_frames.size()
				player_sprite.texture = player_walk_frames[current_walk_frame]

		# Mushika running animation frames
		mushika_frame_timer += delta * 14.0
		if mushika_frame_timer >= 1.0:
			mushika_frame_timer -= 1.0
			if mushika_run_frames.size() > 0:
				current_mushika_frame = (current_mushika_frame + 1) % mushika_run_frames.size()
				mushika_sprite.texture = mushika_run_frames[current_mushika_frame]

	player_sprite.position.y = player_y
	mushika_sprite.position.y = mushika_y

	# Invulnerability blink
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		player_sprite.modulate.a = 0.4 if fposmod(invulnerable_timer, 0.16) > 0.08 else 1.0
	else:
		player_sprite.modulate.a = 1.0

	# 5. Spawners
	_update_spawners(delta)

	# 6. Move obstacles & check collision
	_update_obstacles(delta)

	# 7. Move modaks & check collection
	_update_modaks(delta)

	# 8. Distance score
	score_tick_timer += delta * 10.0
	if score_tick_timer >= 1.0:
		score_tick_timer -= 1.0
		mini_score += 1
		score_label.text = "◆ SCORE: %04d ◆" % mini_score

func _update_spawners(delta: float) -> void:
	obstacle_spawn_timer -= delta
	if obstacle_spawn_timer <= 0.0:
		obstacle_spawn_timer = randf_range(2.0, 3.6)
		_spawn_obstacle()

	modak_spawn_timer -= delta
	if modak_spawn_timer <= 0.0:
		modak_spawn_timer = randf_range(2.8, 4.8)
		_spawn_modak_arc()

func _spawn_obstacle() -> void:
	var roll = randf()
	var tex: Texture2D = crate_tex
	var obs_w: float = 34.0
	var obs_h: float = 34.0

	if roll < 0.4 and spike_tex:
		tex = spike_tex
		obs_w = 36.0
		obs_h = 32.0
	elif roll < 0.65 and brazier_tex:
		tex = brazier_tex
		obs_w = 26.0
		obs_h = 38.0

	if not tex:
		return

	var rect = TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size = Vector2(obs_w, obs_h)
	# Sit right atop GROUND_TOP_Y (415.0)
	rect.position = Vector2(1040.0, GROUND_TOP_Y - obs_h)

	obstacles_container.add_child(rect)
	active_obstacles.append({
		"node": rect,
		"width": obs_w,
		"height": obs_h,
		"active": true
	})

func _spawn_modak_arc() -> void:
	if not modak_tex:
		return

	var count = randi_range(3, 4)
	for i in range(count):
		var m_rect = TextureRect.new()
		m_rect.texture = modak_tex
		m_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		m_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		m_rect.size = Vector2(26, 26)

		# Graceful jump arc
		var arc_offset = sin(float(i) / float(count - 1) * PI) * 58.0
		m_rect.position = Vector2(1040.0 + i * 40.0, GROUND_TOP_Y - 48.0 - arc_offset)

		collectibles_container.add_child(m_rect)
		active_modaks.append({
			"node": m_rect,
			"active": true
		})

func _update_obstacles(delta: float) -> void:
	var player_box = Rect2(player_sprite.position.x + 12, player_sprite.position.y + 10, 32, 42)

	for i in range(active_obstacles.size() - 1, -1, -1):
		var obs = active_obstacles[i]
		var node = obs["node"] as TextureRect
		if not is_instance_valid(node):
			active_obstacles.remove_at(i)
			continue

		node.position.x -= RUN_SPEED * delta

		# Collision check
		if obs["active"] and not is_game_over and invulnerable_timer <= 0.0:
			var obs_box = Rect2(node.position.x + 4, node.position.y + 4, obs["width"] - 8, obs["height"] - 8)
			if player_box.intersects(obs_box):
				_trigger_game_over()
				return

		if node.position.x < -60:
			node.queue_free()
			active_obstacles.remove_at(i)

func _update_modaks(delta: float) -> void:
	var player_box = Rect2(player_sprite.position.x + 8, player_sprite.position.y + 8, 40, 44)

	for i in range(active_modaks.size() - 1, -1, -1):
		var m = active_modaks[i]
		var node = m["node"] as TextureRect
		if not is_instance_valid(node):
			active_modaks.remove_at(i)
			continue

		node.position.x -= RUN_SPEED * delta

		if m["active"]:
			var m_box = Rect2(node.position.x - 2, node.position.y - 2, 30, 30)
			if player_box.intersects(m_box):
				m["active"] = false
				mini_score += 25
				score_label.text = "◆ SCORE: %04d ◆" % mini_score
				if sound_synth:
					sound_synth.play_tab()

				var tw = create_tween()
				tw.tween_property(node, "position:y", node.position.y - 28.0, 0.2)
				tw.parallel().tween_property(node, "modulate:a", 0.0, 0.2)
				tw.tween_callback(func():
					if is_instance_valid(node):
						node.queue_free()
				)
				active_modaks.remove_at(i)
				continue

		if node.position.x < -60:
			node.queue_free()
			active_modaks.remove_at(i)

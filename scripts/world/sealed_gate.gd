extends Area3D

@onready var prompt_label: Label3D = $PromptLabel
@onready var barrier_light: OmniLight3D = $BarrierLight

var pulse_time: float = 0.0
var player_inside: bool = false
var current_player: Node3D = null

var is_spell_broken: bool = false
var puzzle_ui_instance: GatePuzzle = null

const PuzzleScene = preload("res://scenes/ui/gate_puzzle.tscn")
const AssetExtractor = preload("res://scripts/extract_assets.gd")

func _ready() -> void:
	var music_mgr = get_node_or_null("/root/MusicManager")
	if music_mgr and music_mgr.has_method("play"):
		music_mgr.play("outdoor")
	
	var grm = get_node_or_null("/root/GameRunManager")
	if grm:
		if not grm.is_run_active:
			grm.start_new_run()
		grm.set_current_level(1)
		
	var hud_scene = preload("res://scenes/ui/speedrun_hud.tscn")
	var cl = CanvasLayer.new()
	cl.name = "SpeedrunCanvas"
	cl.layer = 15
	add_child(cl)
	cl.add_child(hud_scene.instantiate())

	AssetExtractor.extract_assets_now()
	_update_prompt_text()
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	pulse_time += delta * 3.0
	if barrier_light:
		if not is_spell_broken:
			barrier_light.light_color = Color(0.9, 0.25, 0.45, 1.0) # Demonic crimson spell pulse
			barrier_light.light_energy = 2.0 + sin(pulse_time) * 0.8
		else:
			barrier_light.light_color = Color(1.0, 0.85, 0.4, 1.0) # Warm golden blessing
			barrier_light.light_energy = 1.6 + sin(pulse_time * 0.5) * 0.3
	
	if player_inside and Input.is_action_just_pressed("interact"):
		if not is_spell_broken:
			_open_puzzle()
		else:
			enter_level_1()

func _update_prompt_text() -> void:
	if not prompt_label:
		return
	if not is_spell_broken:
		prompt_label.text = "The Great Gate is sealed by an ancient lock spell!\n[E] Inspect the Puzzle Mechanism"
	else:
		prompt_label.text = "Spell Broken! The Great Gate is Open\n[E] Enter Level 1 (The Asur's Fortress)"

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		current_player = body
		_update_prompt_text()
		prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		current_player = null
		prompt_label.visible = false

func _open_puzzle() -> void:
	if puzzle_ui_instance != null:
		return
	puzzle_ui_instance = PuzzleScene.instantiate()
	get_tree().root.add_child(puzzle_ui_instance)
	puzzle_ui_instance.puzzle_solved.connect(_on_puzzle_solved)
	puzzle_ui_instance.puzzle_closed.connect(_on_puzzle_closed)
	
	# Freeze player movement while solving puzzle
	if current_player and current_player.has_method("set_physics_process"):
		current_player.set_physics_process(false)
		if "velocity" in current_player:
			current_player.velocity = Vector3.ZERO
	
	prompt_label.visible = false

func _on_puzzle_solved() -> void:
	is_spell_broken = true
	puzzle_ui_instance = null
	_update_prompt_text()
	if prompt_label:
		prompt_label.visible = true
	
	# Restore player control
	if current_player and current_player.has_method("set_physics_process"):
		current_player.set_physics_process(true)
		
	var grm = get_node_or_null("/root/GameRunManager")
	if grm and grm.has_method("complete_level_1"):
		grm.complete_level_1()
		
	# Dissolve spell barrier & Asur sigil in outdoor world
	var parent_gate = get_parent()
	if parent_gate:
		var barrier_sprite = parent_gate.get_node_or_null("GateBarrierPortalSprite")
		if barrier_sprite:
			var tw = create_tween()
			tw.tween_property(barrier_sprite, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func(): barrier_sprite.visible = false)
			
		var sigil_sprite = parent_gate.get_node_or_null("AsurSigilShrineTop")
		if sigil_sprite:
			var tw_sigil = create_tween()
			tw_sigil.tween_property(sigil_sprite, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_sigil.tween_callback(func(): sigil_sprite.visible = false)

func _on_puzzle_closed() -> void:
	puzzle_ui_instance = null
	if current_player and current_player.has_method("set_physics_process"):
		current_player.set_physics_process(true)
	if player_inside:
		_update_prompt_text()
		prompt_label.visible = true

func enter_level_1() -> void:
	var l1_path = "res://scenes/levels/l1/l1_map.tscn"
	if ResourceLoader.exists(l1_path):
		get_tree().change_scene_to_file(l1_path)


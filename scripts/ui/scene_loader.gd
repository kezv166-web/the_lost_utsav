extends Node

## SceneLoader – Global Level Transition & Background Thread Loading Manager
## Manages asynchronous threaded loading, loading screen parameters,
## and pauses the run timer until the user confirms entry into the stage.

const LOADING_SCREEN_SCENE: String = "res://scenes/ui/loading_screen.tscn"

var target_scene_path: String = ""
var target_level_num: int = 1
var target_title: String = "LOADING LEVEL 1"
var target_subtitle: String = "Preparing the fortress..."
var loaded_packed_scene: PackedScene = null
var pre_instantiated_stage: Node = null

var _curtain_layer: CanvasLayer = null
var _curtain_rect: ColorRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_persistent_curtain()

func _setup_persistent_curtain() -> void:
	_curtain_layer = CanvasLayer.new()
	_curtain_layer.layer = 128
	add_child(_curtain_layer)

	_curtain_rect = ColorRect.new()
	_curtain_rect.color = Color(0.04, 0.02, 0.05, 1.0)
	_curtain_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_curtain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain_rect.modulate.a = 0.0
	_curtain_layer.add_child(_curtain_rect)

## Pre-instantiates the level in memory during the runner mini-game for zero-gap handoff
func pre_instantiate_target() -> void:
	if pre_instantiated_stage:
		return
	if loaded_packed_scene:
		pre_instantiated_stage = loaded_packed_scene.instantiate()
		print("[SceneLoader] Stage pre-instantiated in memory! Ready for zero-gap handoff.")
	elif not target_scene_path.is_empty() and ResourceLoader.exists(target_scene_path):
		var ps = load(target_scene_path) as PackedScene
		if ps:
			loaded_packed_scene = ps
			pre_instantiated_stage = ps.instantiate()
			print("[SceneLoader] Stage pre-instantiated from file in memory! Ready for zero-gap handoff.")

## Initiates a transition through the interactive loading screen
func load_scene(path: String, level_num: int = 1, title: String = "", subtitle: String = "") -> void:
	target_scene_path = path
	target_level_num = level_num
	target_title = title if not title.is_empty() else ("LOADING LEVEL %d" % level_num)
	target_subtitle = subtitle if not subtitle.is_empty() else "Preparing the stage..."
	loaded_packed_scene = null
	if is_instance_valid(pre_instantiated_stage):
		pre_instantiated_stage.queue_free()
	pre_instantiated_stage = null

	# Pause the speedrun timer so loading time doesn't penalize the player
	var grm = get_node_or_null("/root/GameRunManager")
	if grm:
		grm.pause_run_timer()

	print("[SceneLoader] Loading requested: %s (Level %d: %s)" % [path, level_num, target_title])
	get_tree().change_scene_to_file(LOADING_SCREEN_SCENE)

## Called by LoadingScreen when loading finishes and player presses Space/Click to enter
func enter_loaded_stage() -> void:
	if target_scene_path.is_empty():
		target_scene_path = "res://scenes/levels/outdoor/outdoor_map.tscn"

	var grm = get_node_or_null("/root/GameRunManager")
	if grm:
		grm.set_current_level(target_level_num)
		grm.resume_run_timer()

	print("[SceneLoader] Entering loaded stage: %s" % target_scene_path)

	# ZERO-GAP FAST PATH: Stage was already pre-instantiated in memory during the mini-game!
	if pre_instantiated_stage:
		var stage = pre_instantiated_stage
		pre_instantiated_stage = null

		if _curtain_rect:
			_curtain_rect.modulate.a = 0.0
			var tw_in = create_tween()
			tw_in.tween_property(_curtain_rect, "modulate:a", 1.0, 0.08).set_trans(Tween.TRANS_QUAD)
			await tw_in.finished

		var current = get_tree().current_scene
		get_tree().root.add_child(stage)
		get_tree().current_scene = stage
		if is_instance_valid(current):
			current.queue_free()

		await get_tree().process_frame

		if _curtain_rect:
			var tw_out = create_tween()
			tw_out.tween_property(_curtain_rect, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD)
		return

	# Fallback if pre-instantiation was skipped
	if _curtain_rect:
		var tw_in = create_tween()
		tw_in.tween_property(_curtain_rect, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_in.finished

	var err = get_tree().change_scene_to_file(target_scene_path)
	if err != OK and loaded_packed_scene:
		get_tree().change_scene_to_packed(loaded_packed_scene)

	await get_tree().process_frame

	if _curtain_rect:
		var tw_out = create_tween()
		tw_out.tween_property(_curtain_rect, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)




func get_load_info() -> Dictionary:
	return {
		"path": target_scene_path,
		"level_num": target_level_num,
		"title": target_title,
		"subtitle": target_subtitle
	}

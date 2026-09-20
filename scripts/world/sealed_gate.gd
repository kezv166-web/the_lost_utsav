extends Area3D

@onready var prompt_label: Label3D = $PromptLabel
@onready var barrier_light: OmniLight3D = $BarrierLight

var pulse_time: float = 0.0

var player_inside: bool = false

const AssetExtractor = preload("res://scripts/extract_assets.gd")

func _ready() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play("outdoor")
	AssetExtractor.extract_assets_now()
	prompt_label.visible = false
	prompt_label.text = "The Great Gate\n[E] Enter Level 1 (The Asur's Fortress)"
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	pulse_time += delta * 3.0
	if barrier_light:
		barrier_light.light_energy = 2.0 + sin(pulse_time) * 0.8
	
	if player_inside and Input.is_action_just_pressed("interact"):
		enter_level_1()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		prompt_label.visible = false

func enter_level_1() -> void:
	var l1_path = "res://scenes/levels/l1/l1_map.tscn"
	if ResourceLoader.exists(l1_path):
		get_tree().change_scene_to_file(l1_path)

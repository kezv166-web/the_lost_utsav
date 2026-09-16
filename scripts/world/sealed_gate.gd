extends Area3D

@onready var prompt_label: Label3D = $PromptLabel
@onready var barrier_light: OmniLight3D = $BarrierLight

var pulse_time: float = 0.0

const AssetExtractor = preload("res://scripts/extract_assets.gd")

func _ready() -> void:
	AssetExtractor.extract_assets_now()
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	pulse_time += delta * 3.0
	if barrier_light:
		barrier_light.light_energy = 2.0 + sin(pulse_time) * 0.8

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = false

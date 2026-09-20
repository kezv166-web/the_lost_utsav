class_name GatePuzzle
extends CanvasLayer

signal puzzle_solved
signal puzzle_closed

@onready var backdrop: TextureRect = $Control/Backdrop
@onready var complete_disc: TextureRect = $Control/CompleteDisc
@onready var grid_root: Control = $Control/GridRoot
@onready var victory_banner: PanelContainer = $Control/VictoryBanner
@onready var victory_label: Label = $Control/VictoryBanner/VBox/MessageLabel
@onready var keyhole_visual: Control = $Control/KeyholeMarker
@onready var reset_btn: Button = $Control/ControlsBar/ResetBtn
@onready var close_btn: Button = $Control/ControlsBar/CloseBtn

const PIECE_TEXTURES = [
	preload("res://assets/vfx/puzzle/piece_0.png"),
	preload("res://assets/vfx/puzzle/piece_1.png"),
	preload("res://assets/vfx/puzzle/piece_2.png"),
	preload("res://assets/vfx/puzzle/piece_3.png"),
	preload("res://assets/vfx/puzzle/piece_4.png"),
	preload("res://assets/vfx/puzzle/piece_5.png"),
	preload("res://assets/vfx/puzzle/piece_6.png"),
	preload("res://assets/vfx/puzzle/piece_7.png"),
	preload("res://assets/vfx/puzzle/piece_8.png")
]

# Scaled grid coordinates in 1020x720:
# X bounds: [223, 370, 544, 690] -> widths: [147, 174, 146]
# Y bounds: [155, 284, 418, 542] -> heights: [129, 134, 124]
const COL_WIDTHS = [147.0, 174.0, 146.0]
const ROW_HEIGHTS = [129.0, 134.0, 124.0]
const COL_X_OFFSETS = [0.0, 147.0, 321.0]
const ROW_Y_OFFSETS = [0.0, 129.0, 263.0]

var grid_slots: Array[int] = [-1, -1, -1, -1, -1, -1, -1, -1, -1]

# Selected slot index (-1 if none selected)
var selected_slot: int = -1
var is_solved: bool = false
var is_animating: bool = false

var slot_nodes: Array[Control] = []

func _ready() -> void:
	if victory_banner:
		victory_banner.visible = false
	if complete_disc:
		complete_disc.visible = false
		complete_disc.modulate.a = 0.0

	if reset_btn and not reset_btn.pressed.is_connected(_on_reset_pressed):
		reset_btn.pressed.connect(_on_reset_pressed)
	if close_btn and not close_btn.pressed.is_connected(_on_close_pressed):
		close_btn.pressed.connect(_on_close_pressed)

	_create_grid_slots()
	setup_puzzle(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE):
		_on_close_pressed()

func _create_grid_slots() -> void:
	slot_nodes.clear()
	for child in grid_root.get_children():
		child.queue_free()

	for r in range(3):
		for c in range(3):
			var idx = r * 3 + c
			var slot = Control.new()
			slot.name = "Slot_%d" % idx
			slot.position = Vector2(COL_X_OFFSETS[c], ROW_Y_OFFSETS[r])
			slot.size = Vector2(COL_WIDTHS[c], ROW_HEIGHTS[r])
			slot.custom_minimum_size = slot.size

			# Background dark slot texture
			var bg_rect = TextureRect.new()
			bg_rect.name = "SlotBG"
			bg_rect.texture = preload("res://assets/vfx/puzzle/slot_empty.png")
			bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
			bg_rect.size = slot.size
			slot.add_child(bg_rect)

			# Piece visual
			var piece_rect = TextureRect.new()
			piece_rect.name = "PieceVisual"
			piece_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			piece_rect.stretch_mode = TextureRect.STRETCH_SCALE
			piece_rect.size = slot.size
			piece_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(piece_rect)

			# Selection / Hover highlight
			var highlight = ReferenceRect.new()
			highlight.name = "Highlight"
			highlight.border_color = Color(1.0, 0.85, 0.3, 0.0)
			highlight.border_width = 3.0
			highlight.editor_only = false
			highlight.size = slot.size
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(highlight)

			# Interactive button overlay
			var btn = Button.new()
			btn.name = "ClickArea"
			btn.flat = true
			btn.size = slot.size
			btn.pressed.connect(func(): _on_grid_slot_clicked(idx))
			btn.mouse_entered.connect(func(): _on_slot_hover(slot, true))
			btn.mouse_exited.connect(func(): _on_slot_hover(slot, false))
			slot.add_child(btn)

			grid_root.add_child(slot)
			slot_nodes.append(slot)

func setup_puzzle(scramble: bool = true) -> void:
	is_solved = false
	is_animating = false
	selected_slot = -1
	if complete_disc:
		complete_disc.visible = false
		complete_disc.modulate.a = 0.0
	if victory_banner:
		victory_banner.visible = false

	if scramble:
		# Scramble deterministic permutation where no tile is in its solved position
		var permutation: Array[int] = [4, 0, 7, 6, 8, 1, 2, 5, 3]
		# Randomize slight variation
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		for i in range(rng.randi_range(3, 8)):
			var a = rng.randi_range(0, 8)
			var b = rng.randi_range(0, 8)
			if a != b:
				var temp = permutation[a]
				permutation[a] = permutation[b]
				permutation[b] = temp

		# Ensure it's not solved at start
		if permutation == [0, 1, 2, 3, 4, 5, 6, 7, 8]:
			var tmp = permutation[0]
			permutation[0] = permutation[1]
			permutation[1] = tmp

		grid_slots.assign(permutation)
	else:
		grid_slots.assign([0, 1, 2, 3, 4, 5, 6, 7, 8])

	_refresh_all_visuals()

func _refresh_all_visuals() -> void:
	for i in range(9):
		var slot = slot_nodes[i]
		var piece_rect: TextureRect = slot.get_node("PieceVisual")
		var p_id = grid_slots[i]
		if p_id >= 0 and p_id < PIECE_TEXTURES.size():
			piece_rect.texture = PIECE_TEXTURES[p_id]
			piece_rect.visible = true
		else:
			piece_rect.texture = null
			piece_rect.visible = false
		_update_selection_highlight(slot, selected_slot == i)

func _on_grid_slot_clicked(slot_idx: int) -> void:
	if is_solved or is_animating:
		return

	if selected_slot == -1:
		# First click: select this grid slot
		selected_slot = slot_idx
		_refresh_all_visuals()
	elif selected_slot == slot_idx:
		# Second click on the same slot: deselect
		selected_slot = -1
		_refresh_all_visuals()
	else:
		# Second click on a different slot: swap tiles!
		var temp = grid_slots[slot_idx]
		grid_slots[slot_idx] = grid_slots[selected_slot]
		grid_slots[selected_slot] = temp
		selected_slot = -1
		_refresh_all_visuals()
		_check_win_condition()

func _on_slot_hover(slot: Control, hovering: bool) -> void:
	if is_solved or is_animating:
		return
	var hl: ReferenceRect = slot.get_node_or_null("Highlight")
	if hl:
		var is_selected = (slot_nodes.find(slot) == selected_slot)
		if not is_selected:
			hl.border_color = Color(0.6, 0.9, 1.0, 0.6) if hovering else Color(1.0, 0.85, 0.3, 0.0)

func _update_selection_highlight(slot: Control, selected: bool) -> void:
	var hl: ReferenceRect = slot.get_node_or_null("Highlight")
	if hl:
		hl.border_color = Color(1.0, 0.9, 0.2, 1.0) if selected else Color(1.0, 0.85, 0.3, 0.0)

func _check_win_condition() -> void:
	for i in range(9):
		if grid_slots[i] != i:
			return

	# ALL 9 TILES IN CORRECT POSITIONS!
	is_solved = true
	is_animating = true
	_play_victory_sequence()

func _play_victory_sequence() -> void:
	print("PASSED: Gate 1 Buddhi Siddhi Vinayak Puzzle Solved!")
	selected_slot = -1

	# 1. Divine flash: complete seamless carving fades in
	if complete_disc and is_inside_tree():
		complete_disc.visible = true
		complete_disc.modulate = Color(2.0, 1.8, 1.2, 0.0)
		var tw = create_tween()
		if tw:
			tw.tween_property(complete_disc, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Golden Keyhole rotation
	if keyhole_visual and is_inside_tree():
		var tw_lock = create_tween()
		if tw_lock:
			tw_lock.tween_property(keyhole_visual, "rotation_degrees", 90.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 3. Banner appearance
	if victory_banner and is_inside_tree():
		victory_banner.visible = true
		victory_banner.modulate.a = 0.0
		var tw_b = create_tween()
		if tw_b:
			tw_b.tween_property(victory_banner, "modulate:a", 1.0, 0.5)

	# 4. Wait for player to enjoy completion then emit solved signal
	if is_inside_tree() and get_tree():
		await get_tree().create_timer(2.0).timeout
	puzzle_solved.emit()
	queue_free()

func _on_reset_pressed() -> void:
	if not is_solved and not is_animating:
		setup_puzzle(true)

func _on_close_pressed() -> void:
	if is_animating and is_solved:
		return
	puzzle_closed.emit()
	queue_free()

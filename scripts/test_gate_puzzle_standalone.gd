extends SceneTree

func _init() -> void:
	print("--- BEGIN GATE PUZZLE REFACTOR VERIFICATION ---")
	var scene = load("res://scenes/ui/gate_puzzle.tscn")
	if scene == null:
		printerr("ERROR: Failed to load gate_puzzle.tscn")
		quit(1)
		return
	
	var puzzle = scene.instantiate()
	root.add_child(puzzle)
	puzzle._ready()
	
	# 1. Verify TrayPanel is completely absent
	var tray = puzzle.get_node_or_null("Control/TrayPanel")
	if tray != null:
		printerr("FAILED: TrayPanel still exists in gate_puzzle.tscn!")
		quit(1)
		return
	print("PASS: TrayPanel is confirmed removed from scene hierarchy.")
	
	# 2. Verify 9 grid slots exist
	if puzzle.slot_nodes.size() != 9:
		printerr("FAILED: Expected 9 slot nodes, found %d" % puzzle.slot_nodes.size())
		quit(1)
		return
	print("PASS: 9 grid slot nodes successfully initialized.")
	
	# 3. Test initial selection
	if puzzle.selected_slot != -1:
		printerr("FAILED: Initial selected_slot should be -1")
		quit(1)
		return
	puzzle._on_grid_slot_clicked(2)
	if puzzle.selected_slot != 2:
		printerr("FAILED: selected_slot should be 2 after clicking slot 2")
		quit(1)
		return
	print("PASS: Slot selection works.")
	
	# 4. Test deselecting when clicking same slot
	puzzle._on_grid_slot_clicked(2)
	if puzzle.selected_slot != -1:
		printerr("FAILED: selected_slot should be -1 after clicking slot 2 again")
		quit(1)
		return
	print("PASS: Slot deselection on repeat click works.")
	
	# 5. Test tile swapping
	var val_at_1 = puzzle.grid_slots[1]
	var val_at_4 = puzzle.grid_slots[4]
	puzzle._on_grid_slot_clicked(1)
	if puzzle.selected_slot != 1:
		printerr("FAILED: selected_slot should be 1")
		quit(1)
		return
	puzzle._on_grid_slot_clicked(4)
	if puzzle.selected_slot != -1:
		printerr("FAILED: selected_slot should reset to -1 after swap")
		quit(1)
		return
	if puzzle.grid_slots[1] != val_at_4 or puzzle.grid_slots[4] != val_at_1:
		printerr("FAILED: Slot values not swapped properly")
		quit(1)
		return
	print("PASS: Slot swapping between slot 1 and slot 4 works perfectly.")
	
	# 6. Test win condition trigger
	puzzle.grid_slots.assign([0, 1, 2, 3, 4, 5, 6, 7, 8])
	puzzle._check_win_condition()
	if not puzzle.is_solved:
		printerr("FAILED: Win condition did not trigger when solved")
		quit(1)
		return
	print("PASS: Win condition triggers and is_solved is true.")
	
	print("--- ALL GATE PUZZLE TESTS PASSED SUCCESSFULLY! ---")
	quit(0)

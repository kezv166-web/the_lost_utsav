@tool
extends SceneTree

func _init() -> void:
	print("Running slice_clean_floor...")
	var tileset_res = "res://scenes/levels/l3/3rd-lvl-tileset.png"
	var img = Image.load_from_file(ProjectSettings.globalize_path(tileset_res))
	if img:
		# Crop 64x64 clean tile from top-left
		var tile = img.get_region(Rect2i(0, 0, 64, 64))
		var out_path = ProjectSettings.globalize_path("res://assets/environment/l3_3d/tile_floor_stone_clean.png")
		tile.save_png(out_path)
		print("Saved clean orthogonal floor tile to tile_floor_stone_clean.png")
	
	# Also let's extract the clean 4x4 grid tile from 3d-3rd-lvl.png if available
	var sheet_res = "res://scenes/levels/l3/3d-3rd-lvl.png"
	var sheet = Image.load_from_file(ProjectSettings.globalize_path(sheet_res))
	if sheet:
		# In 3d-3rd-lvl.png, let's crop the top surface of the modular tile at (580, 856, 68, 62)
		var top_surface = sheet.get_region(Rect2i(580, 856, 68, 62))
		var out_surface = ProjectSettings.globalize_path("res://assets/environment/l3_3d/tile_floor_surface.png")
		top_surface.save_png(out_surface)
		print("Saved tile_floor_surface.png")
	
	quit()

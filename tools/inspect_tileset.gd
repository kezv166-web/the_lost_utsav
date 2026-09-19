@tool
extends SceneTree

func _init() -> void:
	var path = ProjectSettings.globalize_path("res://scenes/levels/l3/3rd-lvl-tileset.png")
	var img = Image.load_from_file(path)
	if img:
		print("3rd-lvl-tileset size: ", img.get_width(), "x", img.get_height())
		# The tiles in 3rd-lvl-tileset top-left:
		# Let's crop Rect2i(16, 16, 64, 64), (16, 16, 80, 80), etc.
		# Let's save a crop of the top-left 256x256
		var tl256 = img.get_region(Rect2i(0, 0, 256, 256))
		tl256.save_png(ProjectSettings.globalize_path("res://assets/environment/l3_3d/tileset_tl256.png"))
		print("Saved tileset_tl256.png")
	quit()

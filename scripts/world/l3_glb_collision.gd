extends Node
## Converts L3 arena elements (pillars, broken ruins, cover blocks, rocks)
## to TRUE 3D MODELS from the provided .glb files.
## 1. Instantiates the 3D mesh models and makes them visible in the world.
## 2. Hides the flat 2.5D Sprite3D visuals and CSG plinths.
## 3. Attaches exact matching 3D convex collision shapes grounded to the floor.

const GLB_DIR := "res://scenes/levels/l3/3d-models-glb/"

const GLB_MAP := {
	"pillar_tall": "Meshy_AI_Amethyst_Spire_0919000152_texture",
	"pillar_obelisk": "Meshy_AI_Crimson_Obelisk_0918235345_texture",
	"pillar_broken": "Meshy_AI_Broken_Pillar_0919000544_texture",
	"cover_blocks": "Meshy_AI_Amethyst_Pair_0919001203_texture",
	"cover_ruins": "Meshy_AI_Amethyst_Ruins_0919001309_texture",
	"rock": "Meshy_AI_Amethyst_Prism_0919001011_texture",
}

const NODE_TO_GLB := {
	# Colonnade pillars
	"Col1_L": "pillar_tall",
	"Col1_R": "pillar_tall",
	"Col2_L": "pillar_broken",
	"Col2_R": "pillar_broken",
	"Col3_L": "pillar_tall",
	"Col3_R": "pillar_tall",
	"Col4_L": "pillar_broken",
	"Col4_R": "pillar_broken",
	"Col5_L": "pillar_obelisk",
	"Col5_R": "pillar_obelisk",
	# Cover blocks
	"Cover2_L": "cover_blocks",
	"Cover2_R": "cover_blocks",
	"Cover4_L": "cover_ruins",
	"Cover4_R": "cover_ruins",
	# Movable rocks
	"Rock1": "rock",
	"Rock2": "rock",
	"Rock3": "rock",
	"Rock4": "rock",
	"Rock5": "rock",
	"Rock6": "rock",
}

# Calibrated scales so the 3D models match the grand temple proportions
const SCALE_MAP := {
	"pillar_tall": Vector3(1.3, 2.5, 1.3),
	"pillar_obelisk": Vector3(2.2, 2.4, 2.2),
	"pillar_broken": Vector3(1.4, 1.6, 1.4),
	"cover_blocks": Vector3(1.1, 1.6, 1.1),
	"cover_ruins": Vector3(1.1, 1.3, 1.1),
	"rock": Vector3(0.75, 0.75, 0.75),
}

# Y offsets to ensure the base of each 3D model sits flush with floor (Y=0)
const Y_OFFSET_MAP := {
	"pillar_tall": 2.38,
	"pillar_obelisk": 2.28,
	"pillar_broken": 1.52,
	"cover_blocks": 0.58,
	"cover_ruins": 0.77,
	"rock": 0.08, # Rock node origin is at Y=0.4 in scene
}

var _glb_cache: Dictionary = {}
var _shape_cache: Dictionary = {}


func setup_glb_collisions(arena_props: Node) -> void:
	if not arena_props:
		push_warning("[L3 3D] arena_props node is null")
		return

	print("[L3 3D] Converting arena obstacles to TRUE 3D MESHES...")

	var pillars_node = arena_props.get_node_or_null("Pillars")
	if pillars_node:
		for child in pillars_node.get_children():
			if child is StaticBody3D and child.name in NODE_TO_GLB:
				_apply_glb_model(child, NODE_TO_GLB[child.name])

	var cover_node = arena_props.get_node_or_null("CoverBlocks")
	if cover_node:
		for child in cover_node.get_children():
			if child is StaticBody3D and child.name in NODE_TO_GLB:
				_apply_glb_model(child, NODE_TO_GLB[child.name])

	var rocks_node = arena_props.get_node_or_null("MovableRocks")
	if rocks_node:
		for child in rocks_node.get_children():
			if child is StaticBody3D and child.name in NODE_TO_GLB:
				_apply_glb_model(child, NODE_TO_GLB[child.name])

	print("[L3 3D] True 3D conversion complete for all arena elements.")


func _apply_glb_model(body: StaticBody3D, glb_key: String) -> void:
	var glb_name: String = GLB_MAP.get(glb_key, "")
	if glb_name.is_empty():
		return

	var glb_path := GLB_DIR + glb_name + ".glb"
	var glb_scene: PackedScene = _load_glb(glb_path)
	if not glb_scene:
		push_warning("[L3 3D] Failed to load GLB: %s" % glb_path)
		return

	var scale_vec: Vector3 = SCALE_MAP.get(glb_key, Vector3.ONE)
	var y_offset: float = Y_OFFSET_MAP.get(glb_key, 0.0)

	# 1. HIDE FLAT 2.5D SPRITES AND CSG PLINTHS
	var visual_sprite = body.get_node_or_null("Visual")
	if visual_sprite:
		visual_sprite.visible = false

	var plinth = body.get_node_or_null("Plinth3D")
	if plinth:
		plinth.visible = false

	var mesh3d = body.get_node_or_null("Mesh3D")
	if mesh3d:
		mesh3d.visible = false

	# 2. INSTANTIATE AND DISPLAY TRUE 3D MODEL
	var prev_model = body.get_node_or_null("GLBModel")
	if prev_model:
		prev_model.queue_free()

	var glb_instance: Node3D = glb_scene.instantiate()
	glb_instance.name = "GLBModel"
	glb_instance.transform = Transform3D(Basis.from_scale(scale_vec), Vector3(0, y_offset, 0))

	# Subtle inward rotation for left/right colonnade pillars to enhance perspective depth
	if body.name.ends_with("_L"):
		glb_instance.rotation_degrees.y = 15.0
	elif body.name.ends_with("_R"):
		glb_instance.rotation_degrees.y = -15.0

	body.add_child(glb_instance)

	# 3. ATTACH MATCHING 3D SOLID COLLISION SHAPE
	var shape: Shape3D = _get_or_create_scaled_shape(glb_key, glb_instance, scale_vec)
	if shape:
		var old_col = body.get_node_or_null("CollisionShape3D")
		if old_col:
			old_col.queue_free()

		var prev_glb_col = body.get_node_or_null("GLBCollision")
		if prev_glb_col:
			prev_glb_col.queue_free()

		var new_col := CollisionShape3D.new()
		new_col.name = "GLBCollision"
		new_col.shape = shape
		new_col.position = Vector3(0, y_offset, 0)
		body.add_child(new_col)

	# Ensure collision layer and mask match player (Layer 1 = solid environment)
	body.collision_layer = 1
	body.collision_mask = 1

	print("[L3 3D] Rendered true 3D mesh & collision on %s (%s, scale=%s, Y=%0.2f)" % [body.name, glb_key, scale_vec, y_offset])


func _get_or_create_scaled_shape(glb_key: String, model_instance: Node3D, scale_vec: Vector3) -> Shape3D:
	if _shape_cache.has(glb_key):
		return _shape_cache[glb_key]

	var meshes: Array[Mesh] = []
	_collect_meshes(model_instance, meshes)
	if meshes.is_empty():
		return null

	var primary_mesh: Mesh = meshes[0]
	var raw_shape: ConvexPolygonShape3D = primary_mesh.create_convex_shape(true, true)
	if not raw_shape or raw_shape.points.is_empty():
		var tri_shape: ConcavePolygonShape3D = primary_mesh.create_trimesh_shape()
		if tri_shape:
			_shape_cache[glb_key] = tri_shape
			return tri_shape
		return null

	# Bake scaling directly into points
	var scaled_shape := ConvexPolygonShape3D.new()
	var raw_pts = raw_shape.points
	var scaled_pts := PackedVector3Array()
	scaled_pts.resize(raw_pts.size())
	for i in range(raw_pts.size()):
		scaled_pts[i] = raw_pts[i] * scale_vec
	scaled_shape.points = scaled_pts

	_shape_cache[glb_key] = scaled_shape
	return scaled_shape


func _load_glb(path: String) -> PackedScene:
	if _glb_cache.has(path):
		return _glb_cache[path]

	if not ResourceLoader.exists(path):
		push_warning("[L3 3D] Resource not found: %s" % path)
		return null

	var scene: PackedScene = load(path) as PackedScene
	if scene:
		_glb_cache[path] = scene
	return scene


func _collect_meshes(node: Node, meshes: Array[Mesh]) -> void:
	if node is MeshInstance3D and node.mesh:
		meshes.append(node.mesh)
	for child in node.get_children():
		_collect_meshes(child, meshes)

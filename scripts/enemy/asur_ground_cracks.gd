extends Node3D

const CRACKS_PATH = "res://assets/vfx/ground_cracks.png"
const TARGET_SIZE: float = 5.2
const EXPAND_TIME: float = 0.22
const LINGER_TIME: float = 3.5
const FADE_TIME: float = 0.9

static var _cached_texture: Texture2D = null

@onready var decal: Decal = $CracksDecal
@onready var debris: CPUParticles3D = get_node_or_null("StoneDebris")
@onready var flash_light: OmniLight3D = get_node_or_null("FlashLight")

func _ready() -> void:
	_setup_cracks()

func setup(pos: Vector3) -> void:
	global_position = pos
	global_position.y = 0.05
	_play_impact_effects()

static func ensure_ground_cracks_texture() -> Texture2D:
	if _cached_texture != null:
		return _cached_texture
		
	var global_path = ProjectSettings.globalize_path(CRACKS_PATH)
	if FileAccess.file_exists(global_path):
		var img := Image.load_from_file(global_path)
		if img and not img.is_empty():
			_cached_texture = ImageTexture.create_from_image(img)
			return _cached_texture
		var loaded_tex = load(CRACKS_PATH)
		if loaded_tex:
			_cached_texture = loaded_tex
			return _cached_texture
			
	# Generate procedural radial cracked stone image
	var size: int = 512
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var cx: float = size * 0.5
	var cy: float = size * 0.5
	
	# Primary fracture fissure angles (in radians)
	var angles = [0.15, 0.65, 1.25, 1.85, 2.45, 3.05, 3.65, 4.25, 4.85, 5.55]
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	# Helper to draw soft/sharp pixel
	var set_crack_px = func(px: int, py: int, col: Color):
		if px >= 0 and px < size and py >= 0 and py < size:
			var existing = img.get_pixel(px, py)
			if col.a > existing.a:
				img.set_pixel(px, py, col)
	
	# Draw center fractured crater
	for r in range(4, 38):
		var ring_pts = int(r * 4.0)
		for p in range(ring_pts):
			var theta = (float(p) / float(ring_pts)) * TAU
			var jx = int(cx + cos(theta) * r + rng.randf_range(-1.5, 1.5))
			var jy = int(cy + sin(theta) * r + rng.randf_range(-1.5, 1.5))
			if rng.randf() < 0.25:
				set_crack_px.call(jx, jy, Color(0.95, 0.55, 0.12, 0.85))
			elif rng.randf() < 0.45:
				set_crack_px.call(jx, jy, Color(0.18, 0.06, 0.06, 0.8))
	
	# Radiate primary fissures
	for a in angles:
		var curr_x = cx
		var curr_y = cy
		var curr_angle = a + rng.randf_range(-0.1, 0.1)
		var max_dist = rng.randf_range(180.0, 235.0)
		var step_len = 3.0
		var steps = int(max_dist / step_len)
		
		var branch_due = rng.randi_range(steps / 4, steps / 2)
		
		for s in range(steps):
			var dist_ratio = float(s) / float(steps)
			curr_angle += rng.randf_range(-0.16, 0.16)
			curr_x += cos(curr_angle) * step_len
			curr_y += sin(curr_angle) * step_len
			
			var ix = int(curr_x)
			var iy = int(curr_y)
			var core_col = Color(1.0, 0.55 * (1.0 - dist_ratio * 0.4), 0.15, 0.95 * (1.0 - dist_ratio * 0.3))
			var edge_col = Color(0.18, 0.05, 0.05, 0.85 * (1.0 - dist_ratio * 0.4))
			
			var w = 2 if dist_ratio < 0.5 else 1
			for dx in range(-w, w + 1):
				for dy in range(-w, w + 1):
					if dx == 0 and dy == 0:
						set_crack_px.call(ix, iy, core_col)
					else:
						set_crack_px.call(ix + dx, iy + dy, edge_col)
						
			# Branch off tributary fissure
			if s == branch_due:
				var b_angle = curr_angle + (0.75 if rng.randf() > 0.5 else -0.75)
				var bx = curr_x
				var by = curr_y
				var b_steps = rng.randi_range(15, 30)
				for bs in range(b_steps):
					var b_ratio = float(bs) / float(b_steps)
					b_angle += rng.randf_range(-0.18, 0.18)
					bx += cos(b_angle) * step_len
					by += sin(b_angle) * step_len
					var b_col = Color(0.9, 0.35, 0.1, 0.75 * (1.0 - b_ratio))
					set_crack_px.call(int(bx), int(by), b_col)
					set_crack_px.call(int(bx + 1), int(by), Color(0.15, 0.04, 0.04, 0.6))
	
	# Save PNG file to disk
	img.save_png(global_path)
	print("[VFX] Successfully generated radial ground cracks texture: ", global_path)
	_cached_texture = ImageTexture.create_from_image(img)
	return _cached_texture

func _setup_cracks() -> void:
	var tex = ensure_ground_cracks_texture()
	if decal:
		if tex:
			decal.texture_albedo = tex
			decal.texture_emission = tex
			decal.emission_energy = 2.6
		decal.size = Vector3(0.2, 2.0, 0.2)
		decal.modulate = Color(1.0, 0.92, 0.85, 1.0)
		
		# Snappy expansion with ease-out
		var tw = create_tween()
		tw.tween_property(decal, "size", Vector3(TARGET_SIZE, 2.0, TARGET_SIZE), EXPAND_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Linger for 3.5s then fade out
	var fade_tw = create_tween()
	fade_tw.tween_interval(LINGER_TIME)
	if decal:
		fade_tw.tween_property(decal, "modulate:a", 0.0, FADE_TIME)
	if flash_light:
		fade_tw.parallel().tween_property(flash_light, "light_energy", 0.0, FADE_TIME)
	fade_tw.tween_callback(queue_free)

func _play_impact_effects() -> void:
	# Stone chunk burst particles (at exact stomp location)
	if debris:
		debris.restart()
		debris.emitting = true

	# Impact flash light
	if flash_light:
		flash_light.light_energy = 4.2
		var ltw = create_tween()
		ltw.tween_property(flash_light, "light_energy", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

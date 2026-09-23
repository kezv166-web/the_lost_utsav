class_name UISliceManager
extends RefCounted

# The Lost Utsav - Dynamic UI Slice & Atlas Texture Manager
# Loads and provides clean modular assets extracted from:
# - res://assets/start-pages/leaderboard_elements.png
# - res://assets/start-pages/start_page_elements.png
# Strips checkerboard mockups with BFS flood fill to produce true alpha transparency.
# Fully compatible with Linux, WebGL/WASM, and Desktop exports.

const PATH_LB_ELEMENTS: String = "res://assets/start-pages/leaderboard_elements.png"
const PATH_SP_ELEMENTS: String = "res://assets/start-pages/start_page_elements.png"
const SLICES_DIR: String = "res://assets/start-pages/slices/"

const PATH_LOST_UTSAV_LOGO: String = "res://assets/lost-utsav-text.png"
const PATH_SCROLL_NOTE: String = "res://assets/scroll.png"

static var _instance: UISliceManager = null
static var _cache: Dictionary = {}
static var _lb_image: Image = null
static var _sp_image: Image = null

static func load_clean_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex and tex is Texture2D:
			return tex
	var global_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path) or FileAccess.file_exists(global_path):
		var img = Image.load_from_file(global_path)
		if img != null:
			return ImageTexture.create_from_image(img)
	return null

# Exact bounding regions on leaderboard_elements.png (1536 x 1024)
const LB_REGIONS = {
	"bg_leaderboard": Rect2i(16, 40, 637, 702),
	"title_logo": Rect2i(674, 38, 412, 252),
	"leaderboard_header": Rect2i(1104, 38, 416, 252),
	"table_frame": Rect2i(885, 412, 635, 314),
	"tabs_bar": Rect2i(885, 330, 430, 68),
	"level_dropdown": Rect2i(1325, 330, 195, 68),
	"scroll_note": Rect2i(915, 770, 210, 175),
	"divider_gold": Rect2i(1150, 790, 365, 45),
	"divider_red": Rect2i(1150, 848, 365, 45),
	"crown_gold": Rect2i(25, 828, 52, 56),
	"crown_silver": Rect2i(93, 828, 52, 56),
	"crown_bronze": Rect2i(161, 828, 52, 56),
	# Avatars
	"avatar_0": Rect2i(233, 828, 52, 56),
	"avatar_1": Rect2i(301, 828, 52, 56),
	"avatar_2": Rect2i(369, 828, 52, 56),
	"avatar_3": Rect2i(437, 828, 52, 56),
	"avatar_4": Rect2i(505, 828, 52, 56),
	"avatar_5": Rect2i(573, 828, 52, 56),
	"avatar_6": Rect2i(641, 828, 52, 56),
	"avatar_7": Rect2i(709, 828, 52, 56),
	"avatar_8": Rect2i(777, 828, 52, 56),
	"avatar_9": Rect2i(845, 828, 52, 56),
	# Named avatars mapped to indices
	"avatar_keshav": Rect2i(233, 828, 52, 56),
	"avatar_aryan": Rect2i(301, 828, 52, 56),
	"avatar_ritvik": Rect2i(369, 828, 52, 56),
	"avatar_aditya": Rect2i(437, 828, 52, 56),
	"avatar_ishaan": Rect2i(505, 828, 52, 56),
	"avatar_sneha": Rect2i(573, 828, 52, 56),
	"avatar_harshal": Rect2i(641, 828, 52, 56),
	"avatar_zyaan": Rect2i(709, 828, 52, 56),
	"avatar_dev": Rect2i(777, 828, 52, 56),
	"avatar_meera": Rect2i(845, 828, 52, 56)
}

# Elements that have outer checkerboard patterns that need flood-fill transparency
const ELEMENTS_WITH_CHECKERBOARD = [
	"title_logo",
	"leaderboard_header",
	"scroll_note",
	"crown_gold",
	"crown_silver",
	"crown_bronze",
	"avatar_0", "avatar_1", "avatar_2", "avatar_3", "avatar_4",
	"avatar_5", "avatar_6", "avatar_7", "avatar_8", "avatar_9",
	"avatar_keshav", "avatar_aryan", "avatar_ritvik", "avatar_aditya", "avatar_ishaan",
	"avatar_sneha", "avatar_harshal", "avatar_zyaan", "avatar_dev", "avatar_meera",
	"sp_title_logo",
	"tabs_bar",
	"level_dropdown"
]

# Exact bounding regions on start_page_elements.png (1536 x 1024)
const SP_REGIONS = {
	"bg_start_page": Rect2i(14, 50, 770, 948),
	"sp_title_logo": Rect2i(810, 70, 450, 238),
	"icon_controls": Rect2i(825, 630, 100, 110),
	"icon_credits": Rect2i(935, 630, 100, 110),
	"icon_help": Rect2i(1045, 630, 100, 110),
	"btn_play": Rect2i(810, 365, 220, 80),
	"btn_exit": Rect2i(1045, 365, 220, 80),
	"btn_story": Rect2i(810, 465, 220, 80),
	"btn_leaderboard": Rect2i(1045, 465, 220, 80)
}

static func get_instance() -> UISliceManager:
	if _instance == null:
		_instance = UISliceManager.new()
	return _instance

# ---------------------------------------------------------------------------
# TRANSPARENCY FLOOD-FILL ALGORITHM
# ---------------------------------------------------------------------------

static func _is_checkerboard_color(c: Color) -> bool:
	# Neutral gray check: r approx equal to g approx equal to b
	var diff1 = abs(c.r - c.g)
	var diff2 = abs(c.g - c.b)
	var diff3 = abs(c.r - c.b)
	if diff1 <= 0.08 and diff2 <= 0.08 and diff3 <= 0.08:
		# Checkerboard grays (0.12 to 0.88) or white border (>= 0.90)
		if (c.r >= 0.12 and c.r <= 0.88) or (c.r >= 0.90 and c.g >= 0.90 and c.b >= 0.90):
			return true
	return false

static func remove_checkerboard_flood(src_img: Image) -> Image:
	var img = src_img.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()

	var visited = PackedByteArray()
	visited.resize(w * h)
	visited.fill(0)

	var queue_x = PackedInt32Array()
	var queue_y = PackedInt32Array()

	# Seed perimeter pixels
	for x in range(w):
		for y in [0, h - 1]:
			var idx = y * w + x
			if visited[idx] == 0:
				var c = img.get_pixel(x, y)
				if _is_checkerboard_color(c):
					visited[idx] = 1
					queue_x.append(x)
					queue_y.append(y)

	for y in range(h):
		for x in [0, w - 1]:
			var idx = y * w + x
			if visited[idx] == 0:
				var c = img.get_pixel(x, y)
				if _is_checkerboard_color(c):
					visited[idx] = 1
					queue_x.append(x)
					queue_y.append(y)

	var head = 0
	var transparent = Color(0, 0, 0, 0)
	while head < queue_x.size():
		var cx = queue_x[head]
		var cy = queue_y[head]
		head += 1

		img.set_pixel(cx, cy, transparent)

		# 4-neighbors
		if cx > 0:
			var nidx = cy * w + (cx - 1)
			if visited[nidx] == 0:
				visited[nidx] = 1
				if _is_checkerboard_color(img.get_pixel(cx - 1, cy)):
					queue_x.append(cx - 1)
					queue_y.append(cy)
		if cx < w - 1:
			var nidx = cy * w + (cx + 1)
			if visited[nidx] == 0:
				visited[nidx] = 1
				if _is_checkerboard_color(img.get_pixel(cx + 1, cy)):
					queue_x.append(cx + 1)
					queue_y.append(cy)
		if cy > 0:
			var nidx = (cy - 1) * w + cx
			if visited[nidx] == 0:
				visited[nidx] = 1
				if _is_checkerboard_color(img.get_pixel(cx, cy - 1)):
					queue_x.append(cx)
					queue_y.append(cy - 1)
		if cy < h - 1:
			var nidx = (cy + 1) * w + cx
			if visited[nidx] == 0:
				visited[nidx] = 1
				if _is_checkerboard_color(img.get_pixel(cx, cy + 1)):
					queue_x.append(cx)
					queue_y.append(cy + 1)

	return img

# ---------------------------------------------------------------------------
# TEXTURE ACCESSORS
# ---------------------------------------------------------------------------

static func _ensure_master_images() -> void:
	if _lb_image == null and ResourceLoader.exists(PATH_LB_ELEMENTS):
		var tex = load(PATH_LB_ELEMENTS)
		if tex and tex is Texture2D:
			_lb_image = tex.get_image()
	if _sp_image == null and ResourceLoader.exists(PATH_SP_ELEMENTS):
		var tex = load(PATH_SP_ELEMENTS)
		if tex and tex is Texture2D:
			_sp_image = tex.get_image()

static func get_texture(element_id: String) -> Texture2D:
	if _cache.has(element_id):
		return _cache[element_id]

	# Clean replacements provided by user
	if element_id == "title_logo" or element_id == "sp_title_logo":
		var logo_tex = load_clean_texture(PATH_LOST_UTSAV_LOGO)
		if logo_tex:
			_cache[element_id] = logo_tex
			return logo_tex

	if element_id == "scroll_note":
		var sn_tex = load_clean_texture(PATH_SCROLL_NOTE)
		if sn_tex:
			_cache[element_id] = sn_tex
			return sn_tex

	# 1. Check if a pre-existing clean slice is already on disk (bypass for leaderboard_header to ensure fresh cleanup)
	var slice_path = SLICES_DIR + element_id + ".png"
	if element_id != "leaderboard_header" and ResourceLoader.exists(slice_path):
		var tex = load(slice_path)
		if tex:
			_cache[element_id] = tex
			return tex

	# 2. Extract from master images
	_ensure_master_images()

	var target_img: Image = null
	var region = Rect2i()

	if LB_REGIONS.has(element_id):
		if _lb_image != null:
			region = LB_REGIONS[element_id]
			target_img = _lb_image.get_region(region)
	elif SP_REGIONS.has(element_id):
		if _sp_image != null:
			region = SP_REGIONS[element_id]
			target_img = _sp_image.get_region(region)

	if target_img != null:
		# If element has checkerboard, strip it with BFS flood fill
		if element_id in ELEMENTS_WITH_CHECKERBOARD:
			target_img = remove_checkerboard_flood(target_img)
			if element_id == "leaderboard_header":
				for py in range(target_img.get_height()):
					for px in range(target_img.get_width()):
						var c = target_img.get_pixel(px, py)
						if c.a > 0.0 and _is_checkerboard_color(c):
							target_img.set_pixel(px, py, Color(0, 0, 0, 0))

		# Try saving to slices directory if possible
		var dir = DirAccess.open("res://")
		if dir != null:
			if not dir.dir_exists("res://assets/start-pages/slices"):
				dir.make_dir_recursive("res://assets/start-pages/slices")
			target_img.save_png(slice_path)

		var img_tex = ImageTexture.create_from_image(target_img)
		if img_tex != null:
			_cache[element_id] = img_tex
			return img_tex

	# Fallback to AtlasTexture if dynamic extraction fails
	if LB_REGIONS.has(element_id) and ResourceLoader.exists(PATH_LB_ELEMENTS):
		var master_tex = load(PATH_LB_ELEMENTS)
		if master_tex:
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = master_tex
			atlas_tex.region = Rect2(LB_REGIONS[element_id])
			atlas_tex.filter_clip = true
			_cache[element_id] = atlas_tex
			return atlas_tex

	return null

static func get_leaderboard_bg() -> Texture2D:
	return get_texture("bg_leaderboard")

static func get_start_page_bg() -> Texture2D:
	return get_texture("bg_start_page")

static func get_title_logo() -> Texture2D:
	var logo_tex = load_clean_texture(PATH_LOST_UTSAV_LOGO)
	if logo_tex:
		return logo_tex
	return get_texture("title_logo")

static func get_leaderboard_header() -> Texture2D:
	return get_texture("leaderboard_header")

static func get_table_frame() -> Texture2D:
	return get_texture("table_frame")

static func get_tabs_bar() -> Texture2D:
	return get_texture("tabs_bar")

static func get_level_dropdown() -> Texture2D:
	return get_texture("level_dropdown")

static func get_scroll_note() -> Texture2D:
	var sn_tex = load_clean_texture(PATH_SCROLL_NOTE)
	if sn_tex:
		return sn_tex
	return get_texture("scroll_note")

static func get_crown(crown_type: String) -> Texture2D:
	var key = "crown_" + crown_type.to_lower()
	if LB_REGIONS.has(key):
		return get_texture(key)
	return null

static func get_avatar(avatar_key: String) -> Texture2D:
	var key = avatar_key.to_lower()
	if not key.begins_with("avatar_"):
		key = "avatar_" + key
	if LB_REGIONS.has(key):
		return get_texture(key)
	return get_texture("avatar_0")

static func get_divider(color: String = "gold") -> Texture2D:
	return get_texture("divider_" + color.to_lower())

static func get_icon(icon_name: String) -> Texture2D:
	return get_texture("icon_" + icon_name.to_lower())

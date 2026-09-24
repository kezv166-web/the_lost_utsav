class_name LeaderboardManager
extends RefCounted

signal achievement_unlocked(achievement_id: String, title_name: String)
signal title_changed(new_title: String)

## LeaderboardManager – Authentic Persistent Data Store & Player Profile Manager
## 100% Real Data Store: Zero fake bots.
## Dual-Layer Persistence: Saves to 'user://' on Desktop and mirrors to 'window.localStorage' via JavaScriptBridge on Web (Itch.io & Vercel).
## Multi-Stage Filtering: Supports All Stages (Full Run), Level 1 (Gate), Level 2 (Maze), Level 3 (Boss).

const DATA_FILE_PATH: String = "user://leaderboard_data.json"
const PROFILE_FILE_PATH: String = "user://player_profile.json"

const WEB_KEY_LEADERBOARD: String = "lost_utsav_leaderboard_v5"
const WEB_KEY_PROFILE: String = "lost_utsav_profile_v5"

# Talo Global Leaderboard Backend Credentials (CORS & Web Verified)
const TALO_API_URL: String = "https://api.trytalo.com"
const TALO_API_KEY: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjIyNzQsImFwaSI6dHJ1ZSwiaWF0IjoxNzkwMDU4MDQzfQ.UFdLMNTU68ZA2EmEmOabc12rqV_xCgrVCgxFy0_K4zg"
const TALO_LEADERBOARD_NAME: String = "main"

static var _instance: LeaderboardManager = null

var player_profile: Dictionary = {}
var leaderboard_entries: Array = []
var is_cloud_connected: bool = false
var talo_alias_id: int = -1
var talo_player_id: String = ""
var _cloud_fetch_retries: int = 0
const _CLOUD_MAX_RETRIES: int = 2

static func get_instance() -> LeaderboardManager:
	if _instance == null:
		_instance = LeaderboardManager.new()
		_instance.initialize()
	return _instance

func initialize() -> void:
	# Clean up any legacy localStorage cache on web
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try { ['lost_utsav_leaderboard_real', 'lost_utsav_leaderboard_v2', 'lost_utsav_leaderboard_v3', 'lost_utsav_leaderboard_v4', 'lost_utsav_profile_real', 'lost_utsav_profile_v2', 'lost_utsav_profile_v3', 'lost_utsav_profile_v4'].forEach(function(k){ localStorage.removeItem(k); }); } catch(e){}")
	load_player_profile()
	load_leaderboard_data()
	_deduplicate_self_entries()
	_recalc_profile_stats()
	_retroactively_evaluate_achievements()

# ---------------------------------------------------------------------------
# WEB LOCALSTORAGE PERSISTENCE HELPERS (ITCH.IO & VERCEL SAFEGUARDS)
# ---------------------------------------------------------------------------

func _save_web_storage(key: String, json_str: String) -> void:
	if OS.has_feature("web"):
		var escaped = json_str.replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ")
		var js_code = "try { localStorage.setItem('%s', '%s'); } catch(e) { console.error('LocalStorage write failed:', e); }" % [key, escaped]
		JavaScriptBridge.eval(js_code)

func _load_web_storage(key: String) -> String:
	if OS.has_feature("web"):
		var js_code = "(function() { try { return localStorage.getItem('%s') || ''; } catch(e) { return ''; } })()" % key
		var res = JavaScriptBridge.eval(js_code)
		if res != null and typeof(res) == TYPE_STRING:
			return res
	return ""

# ---------------------------------------------------------------------------
# PLAYER PROFILE MANAGEMENT
# ---------------------------------------------------------------------------

func load_player_profile() -> void:
	var loaded_data: String = ""

	# 1. Try reading from FileAccess (user://)
	if FileAccess.file_exists(PROFILE_FILE_PATH):
		var file = FileAccess.open(PROFILE_FILE_PATH, FileAccess.READ)
		if file:
			loaded_data = file.get_as_text()
			file.close()

	# 2. On Web, fallback to browser localStorage if user:// was empty
	if loaded_data.strip_edges().is_empty():
		loaded_data = _load_web_storage(WEB_KEY_PROFILE)

	# 3. Parse JSON
	if not loaded_data.strip_edges().is_empty():
		var parsed = JSON.parse_string(loaded_data)
		if parsed is Dictionary and parsed.has("id"):
			player_profile = parsed
			_ensure_profile_schema()
			# Graceful upgrade for legacy accounts still using generic "BraveWarrior"
			if not player_profile.get("is_custom_name", false) and player_profile.get("name", "") == "BraveWarrior":
				player_profile["name"] = generate_unique_display_name()
				save_player_profile()
			return

	# 4. Generate unique profile if missing or invalid
	player_profile = _generate_new_profile()
	save_player_profile()

func save_player_profile() -> void:
	var json_str = JSON.stringify(player_profile, "\t")

	# Write to disk / IDBFS
	var file = FileAccess.open(PROFILE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()

	# Mirror to browser localStorage for Itch.io / Vercel resilience
	_save_web_storage(WEB_KEY_PROFILE, json_str)

# ---------------------------------------------------------------------------
# AMONG US-STYLE PROCEDURAL UNIQUE NAMES & TRUE CRYPTOGRAPHIC UUIDs
# ---------------------------------------------------------------------------

const NAME_ADJECTIVES: Array[String] = [
	"Swift", "Mighty", "Brave", "Fierce", "Noble", "Radiant", "Golden", "Iron",
	"Shadow", "Solar", "Thunder", "Cosmic", "Astral", "Valiant", "Storm", "Wild",
	"Blazing", "Ancient", "Sacred", "Mystic"
]

const NAME_ARCHETYPES: Array[String] = [
	"Tiger", "Falcon", "Lion", "Archer", "Sage", "Guardian", "Slayer", "Rider",
	"Seeker", "Champion", "Knight", "Avenger", "Hero", "Yodha", "Warrior"
]

static func generate_unique_display_name() -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var adj = NAME_ADJECTIVES[rng.randi() % NAME_ADJECTIVES.size()]
	var noun = NAME_ARCHETYPES[rng.randi() % NAME_ARCHETYPES.size()]
	var num = rng.randi_range(10, 99)
	return "%s%s%d" % [adj, noun, num]

static func generate_unique_id() -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var h1 = "%08x" % (rng.randi() & 0xffffffff)
	var h2 = "%04x" % (rng.randi() & 0xffff)
	return "USR-%s%s" % [h1, h2]

static func sanitize_player_name(raw_name: String) -> String:
	if raw_name.is_empty():
		return ""
	var clean = raw_name
	# Strip HTML and BBCode tags
	var tag_regex = RegEx.new()
	tag_regex.compile("[\\[<][^\\]>]*[\\]>]")
	clean = tag_regex.sub(clean, "", true)
	
	# Allow only alphanumeric characters, spaces, underscores, and hyphens
	var char_regex = RegEx.new()
	char_regex.compile("[^a-zA-Z0-9_ \\-]")
	clean = char_regex.sub(clean, "", true)
	
	# Collapse consecutive spaces into one and trim
	var space_regex = RegEx.new()
	space_regex.compile("\\s+")
	clean = space_regex.sub(clean, " ", true).strip_edges()
	
	if clean.length() > 16:
		clean = clean.substr(0, 16).strip_edges()
	return clean

func _ensure_profile_schema() -> void:
	if not player_profile.has("achievements") or not (player_profile["achievements"] is Dictionary):
		player_profile["achievements"] = {
			"master_thief": false,
			"divine_runner": false,
			"asur_slayer": false
		}
	if not player_profile.has("unlocked_titles") or not (player_profile["unlocked_titles"] is Array):
		player_profile["unlocked_titles"] = []
	if not player_profile.has("selected_title"):
		player_profile["selected_title"] = ""

func _generate_new_profile() -> Dictionary:
	var profile = {
		"id": generate_unique_id(),
		"name": generate_unique_display_name(),
		"is_custom_name": false,
		"is_custom_name_chosen": false,
		"avatar": "avatar_4",
		"best_time": "--:--:--",
		"best_level": 0,
		"best_score": 0,
		"total_runs": 0,
		"achievements": {
			"master_thief": false,
			"divine_runner": false,
			"asur_slayer": false
		},
		"unlocked_titles": [],
		"selected_title": "",
		"created_at": Time.get_datetime_string_from_system()
	}
	return profile

func unlock_achievement(achievement_id: String, title_name: String) -> bool:
	if player_profile.is_empty():
		load_player_profile()
	_ensure_profile_schema()

	var achs = player_profile["achievements"]
	var was_unlocked = bool(achs.get(achievement_id, false))
	achs[achievement_id] = true

	var titles: Array = player_profile["unlocked_titles"]
	if not titles.has(title_name):
		titles.append(title_name)

	# Check bonus combo titles:
	var core_count = 0
	for core_id in ["master_thief", "divine_runner", "asur_slayer"]:
		if bool(achs.get(core_id, false)):
			core_count += 1

	if core_count >= 2 and not titles.has("[Veteran Yodha]"):
		titles.append("[Veteran Yodha]")
		achievement_unlocked.emit("veteran_yodha", "[Veteran Yodha]")

	if core_count >= 3 and not titles.has("[Bappa's Champion]"):
		titles.append("[Bappa's Champion]")
		achievement_unlocked.emit("bappas_champion", "[Bappa's Champion]")

	# Auto-equip title if currently blank
	if str(player_profile.get("selected_title", "")).is_empty():
		player_profile["selected_title"] = title_name

	save_player_profile()
	_update_self_entries_title(str(player_profile.get("selected_title", "")))

	if not was_unlocked:
		print("[LeaderboardManager] ★ ACHIEVEMENT UNLOCKED: %s -> Title: %s ★" % [achievement_id, title_name])
		achievement_unlocked.emit(achievement_id, title_name)
		return true

	return false

func set_selected_title(title_name: String) -> void:
	if player_profile.is_empty():
		load_player_profile()
	_ensure_profile_schema()

	var titles: Array = player_profile.get("unlocked_titles", [])
	if title_name.is_empty() or titles.has(title_name):
		player_profile["selected_title"] = title_name
		save_player_profile()
		_update_self_entries_title(title_name)
		title_changed.emit(title_name)
		print("[LeaderboardManager] Equipped title updated to: '%s'" % title_name)

func get_unlocked_titles() -> Array:
	if player_profile.is_empty():
		load_player_profile()
	_ensure_profile_schema()
	return player_profile.get("unlocked_titles", [])

func get_selected_title() -> String:
	if player_profile.is_empty():
		load_player_profile()
	_ensure_profile_schema()
	return player_profile.get("selected_title", "")

func has_achievement(achievement_id: String) -> bool:
	if player_profile.is_empty():
		load_player_profile()
	_ensure_profile_schema()
	var achs = player_profile.get("achievements", {})
	if achs is Dictionary:
		return bool(achs.get(achievement_id, false))
	return false

func _update_self_entries_title(title_name: String) -> void:
	var user_guest_id = player_profile.get("id", "")
	var user_google_id = str(player_profile.get("google_id", ""))
	var is_google_linked = player_profile.get("is_google_linked", false)

	for entry in leaderboard_entries:
		if not (entry is Dictionary):
			continue
		var e_id = str(entry.get("id", ""))
		var is_user = (entry.get("is_self", false) or (not user_guest_id.is_empty() and e_id == user_guest_id) or (is_google_linked and not user_google_id.is_empty() and e_id == user_google_id))
		if is_user:
			entry["title"] = title_name

	save_leaderboard_data()

func _retroactively_evaluate_achievements() -> void:
	var newly_unlocked = false
	for entry in leaderboard_entries:
		if not (entry is Dictionary) or not entry.get("is_self", false):
			continue

		var l1_t = float(entry.get("level1_time", 999.0))
		if l1_t > 0.0 and l1_t <= 20.0:
			if unlock_achievement("master_thief", "[Master Thief]"):
				newly_unlocked = true

		var l2_t = float(entry.get("level2_time", 999.0))
		var l2_m = int(entry.get("level2_modaks", 0))
		if l2_m >= 5 and l2_t > 0.0 and l2_t <= 45.0:
			if unlock_achievement("divine_runner", "[Divine Runner]"):
				newly_unlocked = true

		var l3_a = int(entry.get("level3_attempts", 99))
		var lvl = int(entry.get("level", 0))
		if lvl >= 3 and l3_a == 1:
			if unlock_achievement("asur_slayer", "[Asur Slayer]"):
				newly_unlocked = true

	if newly_unlocked:
		print("[LeaderboardManager] Retroactive achievement evaluation completed with new unlocks!")

func get_player_profile() -> Dictionary:
	if player_profile.is_empty():
		load_player_profile()
	return player_profile

func is_story_completed() -> bool:
	if player_profile.is_empty():
		load_player_profile()
	if bool(player_profile.get("story_completed", false)):
		return true
	if int(player_profile.get("best_level", 0)) >= 3:
		return true
	var achs = player_profile.get("achievements", {})
	if achs is Dictionary and bool(achs.get("asur_slayer", false)):
		return true
	for entry in leaderboard_entries:
		if entry is Dictionary and entry.get("is_self", false):
			if bool(entry.get("level3_cleared", false)) or float(entry.get("level3_time", 0.0)) > 0.0:
				return true
	return false

func mark_story_completed() -> void:
	if player_profile.is_empty():
		load_player_profile()
	player_profile["story_completed"] = true
	save_player_profile()
	print("[LeaderboardManager] Story mode marked as completed! Extras Trials permanently unlocked.")

func lock_custom_name() -> void:
	player_profile["is_custom_name_chosen"] = true
	save_player_profile()
	print("[LeaderboardManager] Warrior name locked permanently: '%s'" % player_profile.get("name", ""))

func update_player_name(new_name: String, force: bool = false) -> String:
	if player_profile.get("is_custom_name_chosen", false) and not force:
		print("[LeaderboardManager] Name is locked and cannot be changed.")
		return player_profile.get("name", "")

	var clean_name = sanitize_player_name(new_name)
	if clean_name.length() < 3:
		print("[LeaderboardManager] Name rejected (minimum 3 characters required): '%s'" % new_name)
		return ""
	player_profile["name"] = clean_name
	player_profile["is_custom_name"] = true
	save_player_profile()

	# Update player's runs in local leaderboard data
	var user_guest_id = player_profile.get("id", "")
	var user_google_id = str(player_profile.get("google_id", ""))
	var is_google_linked = player_profile.get("is_google_linked", false)

	for entry in leaderboard_entries:
		var e_id = str(entry.get("id", ""))
		var is_user = (entry.get("is_self", false) or (not user_guest_id.is_empty() and e_id == user_guest_id) or (is_google_linked and not user_google_id.is_empty() and e_id == user_google_id))
		if is_user:
			entry["player"] = clean_name
			entry["is_self"] = true
			if is_google_linked and not user_google_id.is_empty():
				entry["id"] = user_google_id

	_deduplicate_self_entries()
	sort_and_rank()
	save_leaderboard_data()

	# Immediately update Talo live player properties (syncs live name to other players)
	update_talo_player_props(clean_name)

	# Immediately update Talo cloud row with the new display name
	var best_entry: Dictionary = {}
	for entry in leaderboard_entries:
		if entry.get("is_self", false):
			best_entry = entry
			break

	if not best_entry.is_empty():
		post_global_score(best_entry)
		print("[LeaderboardManager] Updated display name to '%s' and synchronized with cloud!" % clean_name)
	else:
		print("[LeaderboardManager] Updated display name to '%s'" % clean_name)

	return clean_name

func _deduplicate_self_entries() -> void:
	var user_guest_id = player_profile.get("id", "")
	var user_google_id = str(player_profile.get("google_id", ""))
	var is_google_linked = player_profile.get("is_google_linked", false)
	var active_name = player_profile.get("name", "Warrior")
	
	var user_entry: Dictionary = {}
	var other_entries: Array = []
	var other_ids_seen: Dictionary = {}

	for entry in leaderboard_entries:
		var e_id = str(entry.get("id", ""))
		var e_name = str(entry.get("player", ""))
		
		# Discard obsolete placeholders or test runs
		if e_name == "BraveWarrior" or e_name == "TestWarrior" or e_id.begins_with("BOT-"):
			continue
			
		var is_user = (entry.get("is_self", false) or (not user_guest_id.is_empty() and e_id == user_guest_id) or (is_google_linked and not user_google_id.is_empty() and e_id == user_google_id))
		
		if is_user:
			if user_entry.is_empty():
				user_entry = entry.duplicate()
				user_entry["is_self"] = true
				user_entry["player"] = active_name
				if is_google_linked and not user_google_id.is_empty():
					user_entry["id"] = user_google_id
				else:
					user_entry["id"] = user_guest_id
			else:
				# Merge with previous user entry, keeping highest score and best time
				var s1 = int(user_entry.get("score", 0))
				var s2 = int(entry.get("score", 0))
				if s2 > s1:
					user_entry = entry.duplicate()
					user_entry["is_self"] = true
					user_entry["player"] = active_name
					if is_google_linked and not user_google_id.is_empty():
						user_entry["id"] = user_google_id
					else:
						user_entry["id"] = user_guest_id
				elif s2 == s1:
					var t1 = float(user_entry.get("raw_time", 999999.0))
					var t2 = float(entry.get("raw_time", 999999.0))
					if t2 < t1:
						user_entry["raw_time"] = t2
						user_entry["time"] = entry.get("time", user_entry.get("time"))
		else:
			# For other players, deduplicate by ID so cloud doesn't return duplicate entries
			if not e_id.is_empty() and other_ids_seen.has(e_id):
				continue
			if not e_id.is_empty():
				other_ids_seen[e_id] = true
			other_entries.append(entry)

	leaderboard_entries.clear()
	for o in other_entries:
		leaderboard_entries.append(o)
	if not user_entry.is_empty():
		leaderboard_entries.append(user_entry)

func _recalc_profile_stats() -> void:
	var user_guest_id = player_profile.get("id", "")
	var user_google_id = str(player_profile.get("google_id", ""))
	var is_google_linked = player_profile.get("is_google_linked", false)
	var best_sc: int = 0
	var best_tm: String = "--:--:--"
	var best_raw_tm: float = 999999.0
	var best_lvl: int = 0
	var count: int = 0

	for e in leaderboard_entries:
		var e_id = str(e.get("id", ""))
		var is_user = (e.get("is_self", false) or (not user_guest_id.is_empty() and e_id == user_guest_id) or (is_google_linked and not user_google_id.is_empty() and e_id == user_google_id))
		if is_user:
			count += 1
			var sc = int(e.get("score", 0))
			# Exclude legacy placeholder
			if sc > 50000:
				continue
			var raw_t = float(e.get("raw_time", time_str_to_seconds(str(e.get("time", "99:99:99")))))
			var lvl = int(e.get("level", 1))
			if sc > best_sc or (sc == best_sc and raw_t < best_raw_tm):
				best_sc = sc
				best_tm = str(e.get("time", "00:00:00"))
				best_raw_tm = raw_t
			if lvl > best_lvl:
				best_lvl = lvl

	if best_sc > 0:
		player_profile["best_score"] = best_sc
		player_profile["best_time"] = best_tm
		player_profile["best_level"] = best_lvl
		player_profile["total_runs"] = count
	else:
		player_profile["best_score"] = 0
		player_profile["best_time"] = "--:--:--"
		player_profile["best_level"] = 0
		player_profile["total_runs"] = 0
	save_player_profile()

# ---------------------------------------------------------------------------
# REAL LEADERBOARD DATA MANAGEMENT (ZERO FAKE BOTS)
# ---------------------------------------------------------------------------

func load_leaderboard_data() -> void:
	leaderboard_entries.clear()
	var loaded_data: String = ""

	# 1. Try reading from FileAccess (user://)
	if FileAccess.file_exists(DATA_FILE_PATH):
		var file = FileAccess.open(DATA_FILE_PATH, FileAccess.READ)
		if file:
			loaded_data = file.get_as_text()
			file.close()

	# 2. On Web, fallback to browser localStorage if user:// was empty
	if loaded_data.strip_edges().is_empty():
		loaded_data = _load_web_storage(WEB_KEY_LEADERBOARD)

	# 3. Parse JSON
	if not loaded_data.strip_edges().is_empty():
		var parsed = JSON.parse_string(loaded_data)
		if parsed is Array:
			for item in parsed:
				if item is Dictionary:
					var item_id = str(item.get("id", ""))
					var p_name = str(item.get("player", ""))
					var sc = int(item.get("score", 0))
					# Filter out legacy dummy bot rows, BraveWarrior/TestWarrior placeholders, and test benchmarks
					if not item_id.begins_with("BOT-") and p_name != "BraveWarrior" and p_name != "TestWarrior" and sc < 50000:
						leaderboard_entries.append(item)
			_deduplicate_self_entries()
			sort_and_rank()
			return

	leaderboard_entries = []
	save_leaderboard_data()

func clear_all_leaderboard_data() -> void:
	leaderboard_entries.clear()
	save_leaderboard_data()
	if player_profile is Dictionary:
		player_profile["best_score"] = 0
		player_profile["best_time"] = "--:--:--"
		player_profile["best_level"] = 0
		player_profile["total_runs"] = 0
		save_player_profile()
	print("[LeaderboardManager] All local leaderboard data and profile run stats wiped clean!")

func save_leaderboard_data() -> void:
	var json_str = JSON.stringify(leaderboard_entries, "\t")

	# Write to disk / IDBFS
	var file = FileAccess.open(DATA_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()

	# Mirror to browser localStorage
	_save_web_storage(WEB_KEY_LEADERBOARD, json_str)

func add_run_entry(run_data: Dictionary) -> void:
	var user_guest_id = player_profile.get("id", "USR-1000")
	var user_google_id = str(player_profile.get("google_id", ""))
	var is_google_linked = player_profile.get("is_google_linked", false)

	var p_id = user_google_id if (is_google_linked and not user_google_id.is_empty()) else user_guest_id
	var p_name = player_profile.get("name", run_data.get("player", "Warrior"))
	var score = int(run_data.get("score", 0))
	var raw_time = float(run_data.get("raw_time", 0.0))
	var formatted_time = str(run_data.get("time", "00:00:00"))
	var lvl = int(run_data.get("level", 1))

	var l1_t = float(run_data.get("level1_time", 0.0))
	var l2_t = float(run_data.get("level2_time", 0.0))
	var l2_m = int(run_data.get("level2_modaks", 0))
	var l3_t = float(run_data.get("level3_time", 0.0))
	var l3_a = int(run_data.get("level3_attempts", 1))

	var active_title = str(player_profile.get("selected_title", ""))

	var entry = {
		"id": p_id,
		"player": p_name,
		"title": active_title,
		"avatar": player_profile.get("avatar", "avatar_4"),
		"level": lvl,
		"level_reached_str": run_data.get("level_reached_str", "%.1f" % lvl),
		"time": formatted_time,
		"raw_time": raw_time,
		"score": score,
		"level1_time": l1_t,
		"level1_points": run_data.get("level1_points", calculate_level_1_points(l1_t)),
		"level2_time": l2_t,
		"level2_points": run_data.get("level2_points", calculate_level_2_points(l2_t, l2_m)),
		"level2_modaks": l2_m,
		"level3_time": l3_t,
		"level3_points": run_data.get("level3_points", calculate_level_3_points(l3_t, l3_a)),
		"level3_attempts": l3_a,
		"date": run_data.get("date", Time.get_date_string_from_system()),
		"is_self": true,
		"created_at_utc": Time.get_datetime_string_from_system(true) + "Z"
	}

	# --- SINGLE ENTRY PER PLAYER (IN-PLACE UPSERT) ---
	var existing_idx = -1
	for i in range(leaderboard_entries.size()):
		var e = leaderboard_entries[i]
		var e_id = str(e.get("id", ""))
		if e.get("is_self", false) or e_id == p_id or (not user_guest_id.is_empty() and e_id == user_guest_id) or (is_google_linked and not user_google_id.is_empty() and e_id == user_google_id):
			existing_idx = i
			break

	var is_new_high_score = false
	if existing_idx >= 0:
		var old_entry = leaderboard_entries[existing_idx]
		var old_score = int(old_entry.get("score", 0))
		var old_time = float(old_entry.get("raw_time", 999999.0))
		
		# Better score, OR same score with faster speedrun time:
		if score > old_score or (score == old_score and raw_time < old_time):
			# Preserve higher level stats if old_entry had later levels
			if entry.get("level2_time", 0.0) == 0.0 and float(old_entry.get("level2_time", 0.0)) > 0.0:
				entry["level2_time"] = old_entry["level2_time"]
				entry["level2_points"] = old_entry.get("level2_points", 0)
				entry["level2_modaks"] = old_entry.get("level2_modaks", 0)
			if entry.get("level3_time", 0.0) == 0.0 and float(old_entry.get("level3_time", 0.0)) > 0.0:
				entry["level3_time"] = old_entry["level3_time"]
				entry["level3_points"] = old_entry.get("level3_points", 0)
				entry["level3_attempts"] = old_entry.get("level3_attempts", 1)
			leaderboard_entries[existing_idx] = entry
			is_new_high_score = true
			print("[LeaderboardManager] Personal best updated in-place! Old: %d pts -> New: %d pts" % [old_score, score])
		else:
			# Update level-specific stats in old_entry if improved or missing
			if l1_t > 0.0 and (float(old_entry.get("level1_time", 0.0)) <= 0.0 or l1_t < float(old_entry.get("level1_time", 999999.0))):
				old_entry["level1_time"] = l1_t
				old_entry["level1_points"] = entry.get("level1_points", calculate_level_1_points(l1_t))
			if l2_t > 0.0 and (float(old_entry.get("level2_time", 0.0)) <= 0.0 or l2_t < float(old_entry.get("level2_time", 999999.0)) or l2_m > int(old_entry.get("level2_modaks", 0))):
				old_entry["level2_time"] = l2_t
				old_entry["level2_points"] = entry.get("level2_points", calculate_level_2_points(l2_t, l2_m))
				old_entry["level2_modaks"] = l2_m
			if l3_t > 0.0 and (float(old_entry.get("level3_time", 0.0)) <= 0.0 or l3_t < float(old_entry.get("level3_time", 999999.0))):
				old_entry["level3_time"] = l3_t
				old_entry["level3_points"] = entry.get("level3_points", calculate_level_3_points(l3_t, l3_a))
				old_entry["level3_attempts"] = l3_a
			print("[LeaderboardManager] Run finished with %d pts. Keeping existing personal best (%d pts) on leaderboard." % [score, old_score])
	else:
		# First time on leaderboard - append single row
		leaderboard_entries.append(entry)
		is_new_high_score = true
		print("[LeaderboardManager] Added initial authentic run: %s, Score: %d, Time: %s" % [p_name, score, formatted_time])

	_deduplicate_self_entries()
	sort_and_rank()
	_recalc_profile_stats()
	save_leaderboard_data()

	# Post authentic score and level props to Talo global leaderboard backend
	var best_entry_to_post = leaderboard_entries[existing_idx] if existing_idx >= 0 else entry
	post_global_score(best_entry_to_post)

# ---------------------------------------------------------------------------
# TALO GLOBAL ONLINE LEADERBOARD INTEGRATION (CORS & ITCH.IO VERIFIED)
# ---------------------------------------------------------------------------

func _create_http_node() -> HTTPRequest:
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var http = HTTPRequest.new()
		http.timeout = 7.0
		# Web export uses browser fetch/XHR without native worker threads
		http.use_threads = false if OS.has_feature("web") else true
		tree.root.add_child(http)
		return http
	return null

func identify_talo_player(callback: Callable = Callable()) -> void:
	if talo_alias_id > 0:
		if callback.is_valid():
			callback.call(true, talo_alias_id)
		return

	var service_name = "username"
	var identifier_val = player_profile.get("id", "USR-1000")
	if player_profile.get("is_google_linked", false) and not str(player_profile.get("google_id", "")).is_empty():
		service_name = "google"
		identifier_val = str(player_profile["google_id"])

	var http = _create_http_node()
	if not http:
		if callback.is_valid():
			callback.call(false, -1)
		return

	var url = "%s/v1/players/identify?service=%s&identifier=%s" % [TALO_API_URL, service_name, identifier_val]
	var headers = [
		"Authorization: Bearer " + TALO_API_KEY,
		"Accept: application/json",
		"X-Talo-Client: godot:1.1.0"
	]

	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		var success = (response_code >= 200 and response_code < 300)
		if success:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary and parsed.has("alias") and parsed["alias"] is Dictionary:
				talo_alias_id = int(parsed["alias"].get("id", -1))
				var p_obj = parsed["alias"].get("player", {})
				if p_obj is Dictionary:
					talo_player_id = str(p_obj.get("id", ""))
				print("[LeaderboardManager] Talo player identified (%s). Alias ID: %d, Player ID: %s" % [service_name, talo_alias_id, talo_player_id])
		if callback.is_valid():
			callback.call(success, talo_alias_id)
	)

	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		http.queue_free()
		if callback.is_valid():
			callback.call(false, -1)

func update_talo_player_props(new_name: String, callback: Callable = Callable()) -> void:
	if talo_player_id.is_empty():
		identify_talo_player(func(ok: bool, _alias: int):
			if ok and not talo_player_id.is_empty():
				update_talo_player_props(new_name, callback)
			else:
				if callback.is_valid():
					callback.call(false)
		)
		return

	var http = _create_http_node()
	if not http:
		if callback.is_valid():
			callback.call(false)
		return

	var url = "%s/v1/players/%s" % [TALO_API_URL, talo_player_id]
	var headers = [
		"Authorization: Bearer " + TALO_API_KEY,
		"Content-Type: application/json",
		"Accept: application/json",
		"X-Talo-Client: godot:1.1.0"
	]
	var payload = {
		"props": [
			{"key": "player", "value": new_name}
		]
	}
	var json_payload = JSON.stringify(payload)
	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		var success = (response_code >= 200 and response_code < 300)
		if success:
			print("[LeaderboardManager] Synced live player name '%s' to Talo (HTTP %d)" % [new_name, response_code])
		if callback.is_valid():
			callback.call(success)
	)

	var err = http.request(url, headers, HTTPClient.METHOD_PATCH, json_payload)
	if err != OK:
		http.queue_free()
		if callback.is_valid():
			callback.call(false)

func link_talo_google_account(google_sub: String, callback: Callable = Callable()) -> void:
	talo_alias_id = -1 # Force re-identification under Google
	talo_player_id = ""
	player_profile["google_id"] = google_sub
	player_profile["is_google_linked"] = true
	save_player_profile()
	_deduplicate_self_entries()
	sort_and_rank()
	save_leaderboard_data()
	identify_talo_player(func(success: bool, _alias: int):
		if callback.is_valid():
			callback.call(success)
	)

func post_global_score(entry: Dictionary, callback: Callable = Callable()) -> void:
	if talo_alias_id <= 0:
		identify_talo_player(func(ok: bool, _alias: int):
			if ok:
				post_global_score(entry, callback)
			else:
				if callback.is_valid():
					callback.call(false)
		)
		return

	var http = _create_http_node()
	if not http:
		if callback.is_valid():
			callback.call(false)
		return

	var p_name = str(entry.get("player", player_profile.get("name", "BraveWarrior")))
	var score_val = int(entry.get("score", 0))

	# Format props as array of {key, value} objects as expected by Talo
	var props_array: Array[Dictionary] = [
		{"key": "player", "value": p_name},
		{"key": "time", "value": str(entry.get("time", "00:00:00"))},
		{"key": "raw_time", "value": str(entry.get("raw_time", 0.0))},
		{"key": "avatar", "value": str(entry.get("avatar", "avatar_4"))},
		{"key": "level", "value": str(entry.get("level", 1))},
		{"key": "level_reached_str", "value": str(entry.get("level_reached_str", "1.0"))},
		{"key": "date", "value": str(entry.get("date", Time.get_date_string_from_system()))},
		{"key": "level1_time", "value": str(entry.get("level1_time", 0.0))},
		{"key": "level1_points", "value": str(entry.get("level1_points", 0))},
		{"key": "level2_time", "value": str(entry.get("level2_time", 0.0))},
		{"key": "level2_points", "value": str(entry.get("level2_points", 0))},
		{"key": "level2_modaks", "value": str(entry.get("level2_modaks", 0))},
		{"key": "level3_time", "value": str(entry.get("level3_time", 0.0))},
		{"key": "level3_points", "value": str(entry.get("level3_points", 0))},
		{"key": "level3_attempts", "value": str(entry.get("level3_attempts", 1))}
	]

	var payload = {
		"score": score_val,
		"props": props_array
	}

	var json_payload = JSON.stringify(payload)
	var url = "%s/v1/leaderboards/%s/entries" % [TALO_API_URL, TALO_LEADERBOARD_NAME]
	var headers = [
		"Authorization: Bearer " + TALO_API_KEY,
		"X-Talo-Alias: %d" % talo_alias_id,
		"Content-Type: application/json",
		"Accept: application/json",
		"X-Talo-Client: godot:1.1.0"
	]

	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		var success = (response_code >= 200 and response_code < 300)
		is_cloud_connected = success
		if success:
			print("[LeaderboardManager] Successfully posted global score to Talo for %s!" % p_name)
		else:
			print("[LeaderboardManager] Talo post response: HTTP %d: %s" % [response_code, body.get_string_from_utf8().substr(0, 200)])
		if callback.is_valid():
			callback.call(success)
	)

	var err = http.request(url, headers, HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		print("[LeaderboardManager] Talo HTTP POST dispatch failed: code %d" % err)
		http.queue_free()
		if callback.is_valid():
			callback.call(false)

func fetch_global_leaderboard(callback: Callable = Callable()) -> void:
	var http = _create_http_node()
	if not http:
		if callback.is_valid():
			callback.call(false, leaderboard_entries)
		return

	var url = "%s/v1/leaderboards/%s/entries?page=0&limit=100" % [TALO_API_URL, TALO_LEADERBOARD_NAME]
	var headers = [
		"Authorization: Bearer " + TALO_API_KEY,
		"Accept: application/json",
		"X-Talo-Client: godot:1.1.0"
	]

	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		var success = false
		if response_code >= 200 and response_code < 300:
			var body_str = body.get_string_from_utf8()
			var parsed = JSON.parse_string(body_str)
			var raw_entries: Array = []
			if parsed is Dictionary and parsed.has("entries") and parsed["entries"] is Array:
				raw_entries = parsed["entries"]

			_merge_talo_scores(raw_entries)
			success = true
			is_cloud_connected = true
			_cloud_fetch_retries = 0
			print("[LeaderboardManager] Successfully synced %d global scores from Talo" % raw_entries.size())

		if not success:
			print("[LeaderboardManager] Talo fetch response: HTTP %d. Serving %d local authentic runs." % [response_code, leaderboard_entries.size()])
			if _cloud_fetch_retries < _CLOUD_MAX_RETRIES:
				_cloud_fetch_retries += 1
				print("[LeaderboardManager] Retrying Talo fetch in 3s (attempt %d/%d)..." % [_cloud_fetch_retries, _CLOUD_MAX_RETRIES])
				var tree = Engine.get_main_loop() as SceneTree
				if tree:
					tree.create_timer(3.0).timeout.connect(func():
						fetch_global_leaderboard(callback)
					)
					return

		if callback.is_valid():
			callback.call(success, leaderboard_entries)
	)

	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("[LeaderboardManager] Talo HTTP GET dispatch failed: code %d" % err)
		http.queue_free()
		if callback.is_valid():
			callback.call(false, leaderboard_entries)

func _merge_talo_scores(raw_entries: Array) -> void:
	var user_guest_id = player_profile.get("id", "")
	var user_google_id = str(player_profile.get("google_id", ""))
	var is_google_linked = player_profile.get("is_google_linked", false)
	var active_name = player_profile.get("name", "Warrior")

	# Find any existing local run for 'self'
	var local_self_entry: Dictionary = {}
	for e in leaderboard_entries:
		var e_id = str(e.get("id", ""))
		var is_user = (e.get("is_self", false) or (not user_guest_id.is_empty() and e_id == user_guest_id) or (is_google_linked and not user_google_id.is_empty() and e_id == user_google_id))
		if is_user:
			local_self_entry = e.duplicate()
			break

	var new_entries: Array = []
	var other_ids_seen: Dictionary = {}
	var user_entry_found: bool = false

	for item in raw_entries:
		if not (item is Dictionary):
			continue

		var score_val = int(item.get("score", 0))
		var alias = item.get("playerAlias", {})
		var p_id = ""
		if alias is Dictionary:
			p_id = str(alias.get("identifier", ""))

		# Convert props array into a dictionary map for direct lookup
		var props_map: Dictionary = {}
		var props_list = item.get("props", [])
		if props_list is Array:
			for p in props_list:
				if p is Dictionary and p.has("key") and p.has("value"):
					props_map[str(p["key"])] = p["value"]

		# Also check live player props on playerAlias.player.props (takes precedence over static score snapshot)
		var player_props_map: Dictionary = {}
		if alias is Dictionary and alias.has("player") and alias["player"] is Dictionary:
			var pl_props = alias["player"].get("props", [])
			if pl_props is Array:
				for pp in pl_props:
					if pp is Dictionary and pp.has("key") and pp.has("value"):
						player_props_map[str(pp["key"])] = pp["value"]

		var created_at = str(item.get("createdAt", ""))
		# Use live player name if available, otherwise entry snapshot name, fallback to Warrior
		var p_name = str(player_props_map.get("player", props_map.get("player", "Warrior")))

		# Discard obsolete placeholders or old test runs
		if p_name == "BraveWarrior" or p_name == "TestWarrior" or p_id.begins_with("BOT-"):
			continue

		var is_self = false
		if not p_id.is_empty():
			if p_id == user_guest_id:
				is_self = true
			elif is_google_linked and not user_google_id.is_empty() and p_id == user_google_id:
				is_self = true

		if is_self:
			p_name = active_name
			user_entry_found = true

		var time_val = str(props_map.get("time", "00:00:00"))
		var raw_t = float(props_map.get("raw_time", time_str_to_seconds(time_val)))
		var lvl = int(props_map.get("level", 1))

		var canonical_id = p_id
		if is_self:
			canonical_id = user_google_id if (is_google_linked and not user_google_id.is_empty()) else user_guest_id

		var entry_dict = {
			"id": canonical_id if not canonical_id.is_empty() else "TALO-%d" % randi_range(1000, 9999),
			"player": p_name,
			"avatar": str(props_map.get("avatar", "avatar_4")),
			"level": lvl,
			"level_reached_str": str(props_map.get("level_reached_str", "%.1f" % lvl)),
			"time": time_val,
			"raw_time": raw_t,
			"score": score_val,
			"date": str(props_map.get("date", Time.get_date_string_from_system())),
			"is_self": is_self,
			"level1_time": float(props_map.get("level1_time", 0.0)),
			"level1_points": int(props_map.get("level1_points", 0)),
			"level2_time": float(props_map.get("level2_time", 0.0)),
			"level2_points": int(props_map.get("level2_points", 0)),
			"level2_modaks": int(props_map.get("level2_modaks", 0)),
			"level3_time": float(props_map.get("level3_time", 0.0)),
			"level3_points": int(props_map.get("level3_points", 0)),
			"level3_attempts": int(props_map.get("level3_attempts", 1)),
			"created_at_utc": created_at
		}

		if is_self and not local_self_entry.is_empty():
			var loc_sc = int(local_self_entry.get("score", 0))
			var loc_raw_t = float(local_self_entry.get("raw_time", 999999.0))
			if loc_sc > score_val or (loc_sc == score_val and loc_raw_t < raw_t):
				entry_dict["score"] = loc_sc
				entry_dict["time"] = local_self_entry.get("time", entry_dict["time"])
				entry_dict["raw_time"] = loc_raw_t
				entry_dict["level"] = local_self_entry.get("level", entry_dict["level"])
				entry_dict["level_reached_str"] = local_self_entry.get("level_reached_str", entry_dict["level_reached_str"])
			if entry_dict["level1_time"] == 0.0 and float(local_self_entry.get("level1_time", 0.0)) > 0.0:
				entry_dict["level1_time"] = local_self_entry.get("level1_time", 0.0)
				entry_dict["level1_points"] = local_self_entry.get("level1_points", 0)
			if entry_dict["level2_time"] == 0.0 and float(local_self_entry.get("level2_time", 0.0)) > 0.0:
				entry_dict["level2_time"] = local_self_entry.get("level2_time", 0.0)
				entry_dict["level2_points"] = local_self_entry.get("level2_points", 0)
				entry_dict["level2_modaks"] = local_self_entry.get("level2_modaks", 0)
			if entry_dict["level3_time"] == 0.0 and float(local_self_entry.get("level3_time", 0.0)) > 0.0:
				entry_dict["level3_time"] = local_self_entry.get("level3_time", 0.0)
				entry_dict["level3_points"] = local_self_entry.get("level3_points", 0)
				entry_dict["level3_attempts"] = local_self_entry.get("level3_attempts", 1)

		if not is_self:
			if not canonical_id.is_empty() and other_ids_seen.has(canonical_id):
				continue
			if not canonical_id.is_empty():
				other_ids_seen[canonical_id] = true

		new_entries.append(entry_dict)

	# If local player had a run that wasn't on Talo yet, keep it!
	if not user_entry_found and not local_self_entry.is_empty():
		var sc = int(local_self_entry.get("score", 0))
		if sc > 0 and sc <= 50000:
			local_self_entry["is_self"] = true
			local_self_entry["player"] = active_name
			new_entries.append(local_self_entry)

	# Authoritatively replace leaderboard_entries with fresh entries
	leaderboard_entries = new_entries
	_deduplicate_self_entries()
	sort_and_rank()
	_recalc_profile_stats()
	save_leaderboard_data()

# ---------------------------------------------------------------------------
# TIME-BASED ACCURATE SORTING & LEVEL FILTERING
# ---------------------------------------------------------------------------

func sort_and_rank() -> void:
	for entry in leaderboard_entries:
		if not entry.has("time_seconds"):
			entry["time_seconds"] = time_str_to_seconds(str(entry.get("time", "99:99:99")))
		var sc = entry.get("score", 0)
		if sc is String:
			entry["score_int"] = int(sc.replace(",", "").replace(".", ""))
		else:
			entry["score_int"] = int(sc)

	# Primary sort: HIGHEST SCORE descending
	# Secondary sort: FASTEST TIME (lowest time_seconds) ascending
	leaderboard_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a = a.get("score_int", 0)
		var score_b = b.get("score_int", 0)
		if score_a != score_b:
			return score_a > score_b
		var time_a = a.get("time_seconds", 999999.0)
		var time_b = b.get("time_seconds", 999999.0)
		if not is_equal_approx(time_a, time_b):
			return time_a < time_b
		return a.get("level", 1) > b.get("level", 1)
	)

	# Assign rank numbers and crown medals
	for i in range(leaderboard_entries.size()):
		var rank = i + 1
		leaderboard_entries[i]["rank"] = rank
		if rank == 1:
			leaderboard_entries[i]["crown"] = "gold"
		elif rank == 2:
			leaderboard_entries[i]["crown"] = "silver"
		elif rank == 3:
			leaderboard_entries[i]["crown"] = "bronze"
		else:
			leaderboard_entries[i]["crown"] = ""

func get_entries(limit: int = 10) -> Array:
	if leaderboard_entries.is_empty():
		load_leaderboard_data()
	if limit <= 0 or limit >= leaderboard_entries.size():
		return leaderboard_entries
	return leaderboard_entries.slice(0, limit)

func get_filtered_entries(level_filter: String, tab_filter: String) -> Array:
	var list = get_entries(0)
	var filtered: Array = []
	var current_month = Time.get_date_string_from_system().substr(0, 7) # YYYY-MM

	for orig in list:
		# Tab filter
		if tab_filter == "this_month":
			var date_str = str(orig.get("date", ""))
			if not date_str.begins_with(current_month):
				continue
		elif tab_filter == "friends":
			if not orig.get("is_self", false):
				continue

		var lvl = int(orig.get("level", 1))
		var entry = orig.duplicate()

		match level_filter:
			"level_1":
				# Any run that completed Level 1 (i.e. lvl >= 1 or has level1_time)
				var l1_t = float(orig.get("level1_time", 0.0))
				if l1_t <= 0.0 and lvl == 1:
					l1_t = float(orig.get("raw_time", 0.0))
				entry["display_level"] = "GATE 1"
				entry["display_time"] = format_time(l1_t) if l1_t > 0.0 else "--:--:--"
				entry["display_raw_time"] = l1_t if l1_t > 0.0 else 999999.0
				var l1_pts = int(orig.get("level1_points", 0))
				if l1_pts <= 0 and l1_t > 0.0:
					l1_pts = calculate_level_1_points(l1_t)
				entry["display_score"] = l1_pts
				filtered.append(entry)

			"level_2":
				# Any run that reached or passed Level 2
				if lvl < 2 and not orig.has("level2_time"):
					continue
				var l2_t = float(orig.get("level2_time", 0.0))
				var modaks = int(orig.get("level2_modaks", 0))
				entry["display_level"] = "%d/5" % modaks
				entry["display_time"] = format_time(l2_t) if l2_t > 0.0 else "--:--:--"
				entry["display_raw_time"] = l2_t if l2_t > 0.0 else 999999.0
				var l2_pts = int(orig.get("level2_points", 0))
				if l2_pts <= 0 and l2_t > 0.0:
					l2_pts = calculate_level_2_points(l2_t, modaks)
				entry["display_score"] = l2_pts
				filtered.append(entry)

			"level_3":
				# Any run that reached Level 3 (cleared or attempted)
				if lvl < 3 and not orig.has("level3_time") and not orig.has("level3_attempts"):
					continue
				var l3_t = float(orig.get("level3_time", 0.0))
				var att = int(orig.get("level3_attempts", 1))
				var is_cleared = bool(orig.get("level3_cleared", lvl >= 3 and l3_t > 0.0))

				if not is_cleared:
					entry["display_level"] = "FAILED (3/3)" if att >= 3 else "TRY %d/3" % att
					entry["display_time"] = "--:--:--"
					entry["display_raw_time"] = 999999.0
					entry["display_score"] = "--"
				else:
					entry["display_level"] = "Att %d" % att
					entry["display_time"] = format_time(l3_t) if l3_t > 0.0 else "--:--:--"
					entry["display_raw_time"] = l3_t if l3_t > 0.0 else 999999.0
					var l3_pts = int(orig.get("level3_points", 0))
					if l3_pts <= 0 and l3_t > 0.0:
						l3_pts = calculate_level_3_points(l3_t, att)
					entry["display_score"] = l3_pts
				filtered.append(entry)

			_: # "all" full playthrough
				entry["display_level"] = orig.get("level_reached_str", "%.1f" % lvl)
				entry["display_time"] = orig.get("time", "00:00:00")
				entry["display_raw_time"] = float(orig.get("raw_time", orig.get("time_seconds", 999999.0)))
				entry["display_score"] = int(orig.get("score", 0))
				filtered.append(entry)

	# Sorting logic per level category
	if level_filter == "level_1":
		# Puzzle speedrun: Fastest time ascending
		filtered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ta = float(a.get("display_raw_time", 99999.0))
			var tb = float(b.get("display_raw_time", 99999.0))
			if not is_equal_approx(ta, tb):
				return ta < tb
			return int(a.get("display_score", 0)) > int(b.get("display_score", 0))
		)
	else:
		# Primary: Highest score descending, Secondary: Fastest time ascending
		filtered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var sa_val = a.get("display_score", 0)
			var sb_val = b.get("display_score", 0)
			var sa: int = -1
			if sa_val is int or sa_val is float:
				sa = int(sa_val)
			elif sa_val is String and sa_val.is_valid_int():
				sa = int(sa_val)

			var sb: int = -1
			if sb_val is int or sb_val is float:
				sb = int(sb_val)
			elif sb_val is String and sb_val.is_valid_int():
				sb = int(sb_val)

			if sa != sb:
				return sa > sb
			var ta = float(a.get("display_raw_time", 99999.0))
			var tb = float(b.get("display_raw_time", 99999.0))
			return ta < tb
		)

	# Re-rank and assign crown medals
	for i in range(filtered.size()):
		var r = i + 1
		filtered[i]["rank"] = r
		if r == 1:
			filtered[i]["crown"] = "gold"
		elif r == 2:
			filtered[i]["crown"] = "silver"
		elif r == 3:
			filtered[i]["crown"] = "bronze"
		else:
			filtered[i]["crown"] = ""

	return filtered

# ---------------------------------------------------------------------------
# SCORING FORMULAS & TIME UTILITIES
# ---------------------------------------------------------------------------

static func calculate_level_1_points(time_sec: float) -> int:
	var base = 300
	var speed = 20
	if time_sec <= 30.0: speed = 200
	elif time_sec <= 60.0: speed = 100
	elif time_sec <= 90.0: speed = 50
	return base + speed

static func calculate_level_2_points(time_sec: float, modaks: int) -> int:
	var base = 400
	var speed = 20
	if time_sec <= 45.0: speed = 250
	elif time_sec <= 90.0: speed = 150
	elif time_sec <= 150.0: speed = 50
	return base + speed + (modaks * 50) + 100

static func calculate_level_3_points(time_sec: float, attempts: int) -> int:
	var base = 500
	var att_bonus = 500 if attempts == 1 else (300 if attempts == 2 else (150 if attempts == 3 else 50))
	var speed = 20
	if time_sec <= 60.0: speed = 300
	elif time_sec <= 120.0: speed = 150
	elif time_sec <= 180.0: speed = 50
	return base + att_bonus + speed + 250

static func format_time(seconds: float) -> String:
	if seconds < 0.0:
		seconds = 0.0
	var total_cs = int(seconds * 100.0)
	var cs = total_cs % 100
	var total_sec = int(seconds)
	var sec = total_sec % 60
	var minutes = (total_sec / 60) % 60
	var hours = total_sec / 3600

	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, sec]
	else:
		return "%02d:%02d:%02d" % [minutes, sec, cs]

static func seconds_to_time_str(seconds: float) -> String:
	return format_time(seconds)

static func time_str_to_seconds(time_str: String) -> float:
	var clean = time_str.strip_edges()
	var parts = clean.split(":")
	if parts.size() == 3:
		var h_or_m = float(parts[0])
		var m_or_s = float(parts[1])
		var s_or_cs = float(parts[2])
		if h_or_m > 0 and parts[0].length() <= 2:
			return h_or_m * 60.0 + m_or_s + (s_or_cs / 100.0)
		return h_or_m * 3600.0 + m_or_s * 60.0 + s_or_cs
	elif parts.size() == 2:
		var m = float(parts[0])
		var s = float(parts[1])
		return m * 60.0 + s
	return 999999.0

static func format_score(val: Variant) -> String:
	if val is String:
		var clean_str = val.strip_edges()
		if clean_str == "--" or clean_str == "-" or not clean_str.replace(",", "").replace(".", "").is_valid_int():
			return clean_str
		val = int(clean_str.replace(",", "").replace(".", ""))

	var int_val: int = 0
	if val is int:
		int_val = val
	elif val is float:
		int_val = int(val)

	var s = str(int_val)
	var res = ""
	var cnt = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	return res

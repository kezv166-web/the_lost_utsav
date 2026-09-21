class_name LeaderboardManager
extends RefCounted

## LeaderboardManager – Authentic Persistent Data Store & Player Profile Manager
## 100% Real Data Store: Zero fake bots.
## Dual-Layer Persistence: Saves to 'user://' on Desktop and mirrors to 'window.localStorage' via JavaScriptBridge on Web (Itch.io & Vercel).
## Multi-Stage Filtering: Supports All Stages (Full Run), Level 1 (Gate), Level 2 (Maze), Level 3 (Boss).

const DATA_FILE_PATH: String = "user://leaderboard_data.json"
const PROFILE_FILE_PATH: String = "user://player_profile.json"

const WEB_KEY_LEADERBOARD: String = "lost_utsav_leaderboard_real"
const WEB_KEY_PROFILE: String = "lost_utsav_profile_real"

# SilentWolf Global Leaderboard Backend Credentials
const SILENTWOLF_GAME_ID: String = "thelostutsav"
const SILENTWOLF_API_KEY: String = "XEiVMbvzWaAkzQDxzu5uaf7TEu3RxR28O3ScIgAg"
const SILENTWOLF_POST_SCORE_URL: String = "https://api.silentwolf.com/post_new_score"
const SILENTWOLF_GET_SCORES_URL: String = "https://api.silentwolf.com/get_scores/thelostutsav"

static var _instance: LeaderboardManager = null

var player_profile: Dictionary = {}
var leaderboard_entries: Array = []
var is_cloud_connected: bool = false

static func get_instance() -> LeaderboardManager:
	if _instance == null:
		_instance = LeaderboardManager.new()
		_instance.initialize()
	return _instance

func initialize() -> void:
	load_player_profile()
	load_leaderboard_data()
	_recalc_profile_stats()

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

func _generate_new_profile() -> Dictionary:
	randomize()
	var unique_num = randi_range(1000, 9999)
	var profile = {
		"id": "USR-%d" % unique_num,
		"name": "BraveWarrior",
		"avatar": "avatar_4",
		"best_time": "--:--:--",
		"best_level": 0,
		"best_score": 0,
		"total_runs": 0,
		"created_at": Time.get_datetime_string_from_system()
	}
	return profile

func get_player_profile() -> Dictionary:
	if player_profile.is_empty():
		load_player_profile()
	return player_profile

func update_player_name(new_name: String) -> void:
	var clean_name = new_name.strip_edges()
	if clean_name.is_empty():
		return
	player_profile["name"] = clean_name
	save_player_profile()

	# Update player's runs in leaderboard data
	var user_id = player_profile.get("id", "")
	for entry in leaderboard_entries:
		if entry.get("id") == user_id or entry.get("is_self", false):
			entry["player"] = clean_name
	save_leaderboard_data()

func _recalc_profile_stats() -> void:
	if leaderboard_entries.is_empty():
		return
	var user_id = player_profile.get("id", "")
	var best_sc: int = 0
	var best_tm: String = "--:--:--"
	var best_raw_tm: float = 999999.0
	var best_lvl: int = 0
	var count: int = 0

	for e in leaderboard_entries:
		if e.get("id") == user_id or e.get("is_self", false):
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
					var sc = int(item.get("score", 0))
					# Filter out legacy dummy bot rows or 490k test benchmark
					if not item_id.begins_with("BOT-") and sc < 50000:
						leaderboard_entries.append(item)
			sort_and_rank()
			return

	leaderboard_entries = []
	save_leaderboard_data()

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
	var p_id = run_data.get("id", player_profile.get("id", "USR-1000"))
	var p_name = run_data.get("player", player_profile.get("name", "BraveWarrior"))
	var score = int(run_data.get("score", 0))
	var raw_time = float(run_data.get("raw_time", 0.0))
	var formatted_time = str(run_data.get("time", "00:00:00"))
	var lvl = int(run_data.get("level", 1))

	var l1_t = float(run_data.get("level1_time", 0.0))
	var l2_t = float(run_data.get("level2_time", 0.0))
	var l2_m = int(run_data.get("level2_modaks", 0))
	var l3_t = float(run_data.get("level3_time", 0.0))
	var l3_a = int(run_data.get("level3_attempts", 1))

	var entry = {
		"id": p_id,
		"player": p_name,
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
		"is_self": true
	}

	leaderboard_entries.append(entry)
	sort_and_rank()
	_recalc_profile_stats()
	save_leaderboard_data()
	print("[LeaderboardManager] Added authentic run: %s, Score: %d, Time: %s" % [p_name, score, formatted_time])

	# Post authentic score to SilentWolf global leaderboard backend
	post_global_score(entry)

# ---------------------------------------------------------------------------
# SILENTWOLF GLOBAL ONLINE LEADERBOARD INTEGRATION (ITCH.IO HTTPS)
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

func post_global_score(entry: Dictionary, callback: Callable = Callable()) -> void:
	var http = _create_http_node()
	if not http:
		if callback.is_valid():
			callback.call(false)
		return

	var p_name = str(entry.get("player", player_profile.get("name", "BraveWarrior")))
	var score_val = int(entry.get("score", 0))
	var meta = {
		"id": str(entry.get("id", player_profile.get("id", "USR-1000"))),
		"time": str(entry.get("time", "00:00:00")),
		"raw_time": float(entry.get("raw_time", 0.0)),
		"avatar": str(entry.get("avatar", "avatar_4")),
		"level": int(entry.get("level", 1)),
		"level_reached_str": str(entry.get("level_reached_str", "1.0")),
		"date": str(entry.get("date", Time.get_date_string_from_system()))
	}

	var payload = {
		"game_id": SILENTWOLF_GAME_ID,
		"api_key": SILENTWOLF_API_KEY,
		"player_name": p_name,
		"score": score_val,
		"ldboard_name": "main",
		"metadata": meta
	}

	var json_payload = JSON.stringify(payload)
	var headers = [
		"Content-Type: application/json",
		"x-api-key: " + SILENTWOLF_API_KEY
	]

	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
		http.queue_free()
		var success = (response_code >= 200 and response_code < 300)
		is_cloud_connected = success
		if success:
			print("[LeaderboardManager] Successfully posted global score to SilentWolf for %s!" % p_name)
		else:
			print("[LeaderboardManager] SilentWolf post response: HTTP %d (Offline/Cached locally)" % response_code)
		if callback.is_valid():
			callback.call(success)
	)

	var err = http.request(SILENTWOLF_POST_SCORE_URL, headers, HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		print("[LeaderboardManager] SilentWolf HTTP POST dispatch failed: code %d" % err)
		http.queue_free()
		if callback.is_valid():
			callback.call(false)

func fetch_global_leaderboard(callback: Callable = Callable()) -> void:
	var http = _create_http_node()
	if not http:
		if callback.is_valid():
			callback.call(false, leaderboard_entries)
		return

	var url = "%s?api_key=%s&ldboard_name=main" % [SILENTWOLF_GET_SCORES_URL, SILENTWOLF_API_KEY]
	var headers = [
		"Content-Type: application/json",
		"x-api-key: " + SILENTWOLF_API_KEY
	]

	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		var success = false
		if response_code >= 200 and response_code < 300:
			var body_str = body.get_string_from_utf8()
			var parsed = JSON.parse_string(body_str)
			var raw_scores: Array = []
			if parsed is Array:
				raw_scores = parsed
			elif parsed is Dictionary:
				if parsed.has("top_scores") and parsed["top_scores"] is Array:
					raw_scores = parsed["top_scores"]
				elif parsed.has("scores") and parsed["scores"] is Array:
					raw_scores = parsed["scores"]
				elif parsed.has("result") and parsed["result"] is Array:
					raw_scores = parsed["result"]

			if not raw_scores.is_empty():
				_merge_cloud_scores(raw_scores)
				success = true
				is_cloud_connected = true
				print("[LeaderboardManager] Successfully synced %d global scores from SilentWolf" % raw_scores.size())

		if not success:
			print("[LeaderboardManager] SilentWolf fetch response: HTTP %d. Serving %d local authentic runs." % [response_code, leaderboard_entries.size()])

		if callback.is_valid():
			callback.call(success, leaderboard_entries)
	)

	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("[LeaderboardManager] SilentWolf HTTP GET dispatch failed: code %d" % err)
		http.queue_free()
		if callback.is_valid():
			callback.call(false, leaderboard_entries)

func _merge_cloud_scores(raw_scores: Array) -> void:
	var user_id = player_profile.get("id", "")
	for item in raw_scores:
		if not (item is Dictionary):
			continue
		var meta = item.get("metadata", {})
		if typeof(meta) == TYPE_STRING:
			meta = JSON.parse_string(meta) if not meta.is_empty() else {}
		if not (meta is Dictionary):
			meta = {}

		var p_name = str(item.get("player_name", meta.get("player", "Warrior")))
		var score_val = int(item.get("score", 0))
		var p_id = str(meta.get("id", item.get("score_id", "")))
		var is_self = (p_id == user_id or p_name == player_profile.get("name", ""))

		# Check if already present in local entries
		var found_index = -1
		for i in range(leaderboard_entries.size()):
			var e = leaderboard_entries[i]
			if (not p_id.is_empty() and e.get("id") == p_id) or (e.get("player") == p_name):
				found_index = i
				break

		var entry_dict = {
			"id": p_id if not p_id.is_empty() else "CLOUD-%d" % randi_range(1000, 9999),
			"player": p_name,
			"avatar": str(meta.get("avatar", "avatar_4")),
			"level": int(meta.get("level", 1)),
			"level_reached_str": str(meta.get("level_reached_str", "%.1f" % int(meta.get("level", 1)))),
			"time": str(meta.get("time", "00:00:00")),
			"raw_time": float(meta.get("raw_time", time_str_to_seconds(str(meta.get("time", "00:00:00"))))),
			"score": score_val,
			"date": str(meta.get("date", Time.get_date_string_from_system())),
			"is_self": is_self
		}

		if found_index >= 0:
			var existing_score = int(leaderboard_entries[found_index].get("score", 0))
			if score_val >= existing_score:
				leaderboard_entries[found_index] = entry_dict
		else:
			leaderboard_entries.append(entry_dict)

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
				if l1_t <= 0.0 and lvl >= 1:
					l1_t = float(orig.get("raw_time", 0.0))
				entry["display_level"] = "L1 GATE"
				entry["display_time"] = format_time(l1_t)
				entry["display_raw_time"] = l1_t
				var l1_pts = orig.get("level1_points", calculate_level_1_points(l1_t))
				entry["display_score"] = int(l1_pts)
				filtered.append(entry)

			"level_2":
				# Any run that reached or passed Level 2
				if lvl < 2 and not orig.has("level2_time"):
					continue
				var l2_t = float(orig.get("level2_time", 0.0))
				var modaks = int(orig.get("level2_modaks", 0))
				entry["display_level"] = "🍬 %d/5" % modaks
				entry["display_time"] = format_time(l2_t) if l2_t > 0.0 else entry.get("time", "00:00:00")
				entry["display_raw_time"] = l2_t if l2_t > 0.0 else float(orig.get("raw_time", 9999.0))
				var l2_pts = orig.get("level2_points", calculate_level_2_points(l2_t, modaks))
				entry["display_score"] = int(l2_pts)
				filtered.append(entry)

			"level_3":
				# Any run that reached Level 3
				if lvl < 3 and not orig.has("level3_time"):
					continue
				var l3_t = float(orig.get("level3_time", 0.0))
				var att = int(orig.get("level3_attempts", 1))
				entry["display_level"] = "⚔ Att %d" % att
				entry["display_time"] = format_time(l3_t) if l3_t > 0.0 else entry.get("time", "00:00:00")
				entry["display_raw_time"] = l3_t if l3_t > 0.0 else float(orig.get("raw_time", 9999.0))
				var l3_pts = orig.get("level3_points", calculate_level_3_points(l3_t, att))
				entry["display_score"] = int(l3_pts)
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
			var sa = int(a.get("display_score", 0))
			var sb = int(b.get("display_score", 0))
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
	var int_val: int = 0
	if val is int:
		int_val = val
	elif val is float:
		int_val = int(val)
	elif val is String:
		int_val = int(val.replace(",", "").replace(".", ""))

	var s = str(int_val)
	var res = ""
	var cnt = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	return res

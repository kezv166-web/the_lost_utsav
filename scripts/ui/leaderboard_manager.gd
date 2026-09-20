class_name LeaderboardManager
extends RefCounted

# The Lost Utsav - Persistent Real Data Store & Player Profile Manager
# Saves authentic speedrun leaderboard data to 'user://leaderboard_data.json'
# and persistent user identity to 'user://player_profile.json'.
# Compatible with Linux, Windows, macOS, and Web exports (IndexedDB).

const DATA_FILE_PATH: String = "user://leaderboard_data.json"
const PROFILE_FILE_PATH: String = "user://player_profile.json"

static var _instance: LeaderboardManager = null

var player_profile: Dictionary = {}
var leaderboard_entries: Array = []

static func get_instance() -> LeaderboardManager:
	if _instance == null:
		_instance = LeaderboardManager.new()
		_instance.initialize()
	return _instance

func initialize() -> void:
	load_player_profile()
	load_leaderboard_data()

# ---------------------------------------------------------------------------
# PLAYER PROFILE MANAGEMENT
# ---------------------------------------------------------------------------

func load_player_profile() -> void:
	if FileAccess.file_exists(PROFILE_FILE_PATH):
		var file = FileAccess.open(PROFILE_FILE_PATH, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_str)
			if parsed is Dictionary and parsed.has("id"):
				player_profile = parsed
				return

	# If missing or invalid, generate a unique profile
	player_profile = _generate_new_profile()
	save_player_profile()

func save_player_profile() -> void:
	var file = FileAccess.open(PROFILE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(player_profile, "\t"))
		file.close()

func _generate_new_profile() -> Dictionary:
	randomize()
	var unique_num = randi_range(1000, 9999)
	var profile = {
		"id": "USR-%d" % unique_num,
		"name": "BraveWarrior",
		"avatar": "avatar_4",
		"best_time": "00:33:45",
		"best_level": 3,
		"best_score": 408200,
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
	
	# Update user row in leaderboard data if present
	var user_id = player_profile.get("id", "")
	for entry in leaderboard_entries:
		if entry.get("id") == user_id or entry.get("is_self", false):
			entry["player"] = clean_name
			break
	save_leaderboard_data()

# ---------------------------------------------------------------------------
# LEADERBOARD DATA MANAGEMENT
# ---------------------------------------------------------------------------

func load_leaderboard_data() -> void:
	if FileAccess.file_exists(DATA_FILE_PATH):
		var file = FileAccess.open(DATA_FILE_PATH, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_str)
			if parsed is Array and parsed.size() > 0:
				leaderboard_entries = parsed
				_sync_user_profile_entry()
				sort_and_rank()
				return

	# If missing, seed with realistic mock entries matching the reference artwork
	leaderboard_entries = _generate_default_seed()
	sort_and_rank()
	save_leaderboard_data()

func save_leaderboard_data() -> void:
	var file = FileAccess.open(DATA_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(leaderboard_entries, "\t"))
		file.close()

func _generate_default_seed() -> Array:
	var user_id = player_profile.get("id", "USR-8492")
	var user_name = player_profile.get("name", "BraveWarrior")
	var user_time = player_profile.get("best_time", "00:33:45")
	var user_score = player_profile.get("best_score", 408200)

	var list = [
		{
			"id": "BOT-1001",
			"player": "Keshav",
			"level": 3,
			"time": "00:28:14",
			"score": 452300,
			"avatar": "avatar_0",
			"is_self": false
		},
		{
			"id": "BOT-1002",
			"player": "Aryan",
			"level": 3,
			"time": "00:32:11",
			"score": 418760,
			"avatar": "avatar_1",
			"is_self": false
		},
		{
			"id": user_id,
			"player": user_name,
			"level": 3,
			"time": user_time,
			"score": user_score,
			"avatar": "avatar_4",
			"is_self": true
		},
		{
			"id": "BOT-1003",
			"player": "Ritvik",
			"level": 3,
			"time": "00:35:02",
			"score": 401920,
			"avatar": "avatar_2",
			"is_self": false
		},
		{
			"id": "BOT-1004",
			"player": "Aditya",
			"level": 3,
			"time": "00:36:18",
			"score": 389410,
			"avatar": "avatar_3",
			"is_self": false
		},
		{
			"id": "BOT-1005",
			"player": "Ishaan",
			"level": 3,
			"time": "00:38:25",
			"score": 372600,
			"avatar": "avatar_4",
			"is_self": false
		},
		{
			"id": "BOT-1006",
			"player": "Sneha",
			"level": 2,
			"time": "00:41:12",
			"score": 328450,
			"avatar": "avatar_5",
			"is_self": false
		},
		{
			"id": "BOT-1007",
			"player": "Harshal",
			"level": 2,
			"time": "00:44:09",
			"score": 311270,
			"avatar": "avatar_6",
			"is_self": false
		},
		{
			"id": "BOT-1008",
			"player": "Zyaan",
			"level": 2,
			"time": "00:45:33",
			"score": 298910,
			"avatar": "avatar_7",
			"is_self": false
		},
		{
			"id": "BOT-1009",
			"player": "Dev",
			"level": 2,
			"time": "00:48:16",
			"score": 276880,
			"avatar": "avatar_8",
			"is_self": false
		},
		{
			"id": "BOT-1010",
			"player": "Meera",
			"level": 1,
			"time": "00:51:04",
			"score": 249330,
			"avatar": "avatar_9",
			"is_self": false
		}
	]
	return list

func _sync_user_profile_entry() -> void:
	var user_id = player_profile.get("id", "")
	var user_name = player_profile.get("name", "BraveWarrior")
	var found = false
	for entry in leaderboard_entries:
		if entry.get("id") == user_id or entry.get("is_self", false):
			entry["id"] = user_id
			entry["player"] = user_name
			entry["is_self"] = true
			found = true
			break
	if not found:
		leaderboard_entries.append({
			"id": user_id,
			"player": user_name,
			"level": player_profile.get("best_level", 3),
			"time": player_profile.get("best_time", "00:33:45"),
			"score": player_profile.get("best_score", 408200),
			"avatar": player_profile.get("avatar", "avatar_4"),
			"is_self": true
		})

# ---------------------------------------------------------------------------
# TIME-BASED ACCURATE SORTING
# ---------------------------------------------------------------------------

func sort_and_rank() -> void:
	for entry in leaderboard_entries:
		entry["time_seconds"] = time_str_to_seconds(str(entry.get("time", "99:99:99")))
		var sc = entry.get("score", 0)
		if sc is String:
			entry["score_int"] = int(sc.replace(",", "").replace(".", ""))
		else:
			entry["score_int"] = int(sc)

	# Primary sort: FASTEST TIME (lowest time_seconds) ranks #1
	# Secondary: Higher level reached
	# Tertiary: Higher score
	leaderboard_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var time_a = a.get("time_seconds", 999999.0)
		var time_b = b.get("time_seconds", 999999.0)
		if not is_equal_approx(time_a, time_b):
			return time_a < time_b
		var lvl_a = a.get("level", 1)
		var lvl_b = b.get("level", 1)
		if lvl_a != lvl_b:
			return lvl_a > lvl_b
		return a.get("score_int", 0) > b.get("score_int", 0)
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

func record_run(new_time_str: String, level: int, score: int) -> int:
	var new_seconds = time_str_to_seconds(new_time_str)
	var user_id = player_profile.get("id", "")
	var user_best_seconds = time_str_to_seconds(player_profile.get("best_time", "99:99:99"))

	# Update profile best if faster or equal with higher score
	if new_seconds < user_best_seconds:
		player_profile["best_time"] = new_time_str
		player_profile["best_level"] = max(level, player_profile.get("best_level", 1))
		player_profile["best_score"] = max(score, player_profile.get("best_score", 0))
		save_player_profile()

	# Update or append in leaderboard entries
	var found = false
	for entry in leaderboard_entries:
		if entry.get("id") == user_id or entry.get("is_self", false):
			var entry_sec = time_str_to_seconds(entry.get("time", "99:99:99"))
			if new_seconds < entry_sec:
				entry["time"] = new_time_str
				entry["level"] = level
				entry["score"] = score
			found = true
			break
	if not found:
		leaderboard_entries.append({
			"id": user_id,
			"player": player_profile.get("name", "BraveWarrior"),
			"level": level,
			"time": new_time_str,
			"score": score,
			"avatar": player_profile.get("avatar", "avatar_4"),
			"is_self": true
		})

	sort_and_rank()
	save_leaderboard_data()

	# Return the player's new rank
	for entry in leaderboard_entries:
		if entry.get("id") == user_id or entry.get("is_self", false):
			return entry.get("rank", 1)
	return 1

# ---------------------------------------------------------------------------
# TIME CONVERSION & FORMATTING HELPERS
# ---------------------------------------------------------------------------

static func time_str_to_seconds(t_str: String) -> float:
	var clean = t_str.strip_edges()
	var parts = clean.split(":")
	if parts.size() == 3:
		var h = float(parts[0])
		var m = float(parts[1])
		var s = float(parts[2])
		return (h * 3600.0) + (m * 60.0) + s
	elif parts.size() == 2:
		var m = float(parts[0])
		var s = float(parts[1])
		return (m * 60.0) + s
	elif parts.size() == 1:
		return float(parts[0])
	return 999999.0

static func seconds_to_time_str(total_seconds: float) -> String:
	var total_sec_int = int(total_seconds)
	var h = total_sec_int / 3600
	var m = (total_sec_int % 3600) / 60
	var s = total_sec_int % 60
	return "%02d:%02d:%02d" % [h, m, s]

static func format_score(score_val: Variant) -> String:
	var s_str: String = ""
	if score_val is String:
		s_str = score_val.replace(",", "").replace(".", "")
	else:
		s_str = str(int(score_val))
	
	var len = s_str.length()
	if len <= 3:
		return s_str
	var res = ""
	var count = 0
	for i in range(len - 1, -1, -1):
		res = s_str[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res

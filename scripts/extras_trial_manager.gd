class_name ExtrasTrialManager
extends RefCounted

## ExtrasTrialManager – Independent session manager for Asur Trials (Extras Mode)
## 100% Isolated: Zero connection to main speedrun leaderboard, zero story triggers.

const SAVE_PATH: String = "user://extras_trials.json"
const WEB_STORAGE_KEY: String = "lost_utsav_extras_trials_v1"

static var _instance = null

var is_active: bool = false
var active_tier: int = 1 # 1 = General's Duel, 2 = Enraged Asur, 3 = Overlord & Flankers
var highest_unlocked_tier: int = 1

static func get_instance():
	if _instance == null:
		_instance = load("res://scripts/extras_trial_manager.gd").new()
		_instance.load_progression()
	return _instance

func load_progression() -> void:
	highest_unlocked_tier = 1
	var loaded_data: String = ""

	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			loaded_data = file.get_as_text()
			file.close()

	if loaded_data.strip_edges().is_empty() and OS.has_feature("web"):
		var js_code = "(function() { try { return localStorage.getItem('%s') || ''; } catch(e) { return ''; } })()" % WEB_STORAGE_KEY
		var res = JavaScriptBridge.eval(js_code)
		if res != null and typeof(res) == TYPE_STRING:
			loaded_data = res

	if not loaded_data.strip_edges().is_empty():
		var parsed = JSON.parse_string(loaded_data)
		if parsed is Dictionary:
			highest_unlocked_tier = clampi(int(parsed.get("highest_unlocked_tier", 1)), 1, 3)
	
	print("[ExtrasTrialManager] Loaded progression: Highest unlocked tier = %d" % highest_unlocked_tier)

func save_progression() -> void:
	var data = {
		"highest_unlocked_tier": highest_unlocked_tier,
		"updated_at": Time.get_datetime_string_from_system()
	}
	var json_str = JSON.stringify(data, "\t")

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()

	if OS.has_feature("web"):
		var escaped = json_str.replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ")
		var js_code = "try { localStorage.setItem('%s', '%s'); } catch(e){}" % [WEB_STORAGE_KEY, escaped]
		JavaScriptBridge.eval(js_code)

func start_trial(tier: int) -> void:
	load_progression()
	if not is_tier_unlocked(tier):
		print("[ExtrasTrialManager] Access Denied: Tier %d is locked! Falling back to highest unlocked Tier %d." % [tier, highest_unlocked_tier])
		active_tier = highest_unlocked_tier
	else:
		active_tier = clampi(tier, 1, 3)
	is_active = true
	print("[ExtrasTrialManager] Starting Asur Trial Tier %d!" % active_tier)

func stop_trial() -> void:
	is_active = false
	active_tier = 1
	print("[ExtrasTrialManager] Trial stopped. Returning to standard state.")

func record_tier_victory(tier: int) -> bool:
	if tier >= highest_unlocked_tier and highest_unlocked_tier < 3:
		highest_unlocked_tier = tier + 1
		save_progression()
		print("[ExtrasTrialManager] ★ UNLOCKED TIER %d! ★" % highest_unlocked_tier)
		return true
	return false

func is_tier_unlocked(tier: int) -> bool:
	return tier <= highest_unlocked_tier

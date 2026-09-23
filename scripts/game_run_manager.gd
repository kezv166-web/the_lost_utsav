extends Node

## GameRunManager – Global Run, Speedrun Timer & Authentic Score Tracker
## Autoload singleton managing full-game playthrough stats across scene transitions.
##
## Points System:
## Strictly starts at 0 and strictly increases upon reaching objectives / milestones.
## Never decreases over time.

signal run_started
signal run_updated(time: float, points: int)
signal modak_collected(total_modaks: int, points_gained: int)
signal points_awarded(amount: int, total: int, reason: String)
signal run_completed(summary: Dictionary)

var is_run_active: bool = false
var is_timer_paused: bool = false
var current_level_num: int = 1 # 1 = Outdoor/Gate, 2 = Maze, 3 = Asur Arena

var total_time: float = 0.0
var total_points: int = 0

# Level 1 (Outdoor Great Gate Lock Puzzle)
var level1_time: float = 0.0
var level1_points: int = 0
var level1_cleared: bool = false

# Level 2 (Underground Maze & 5 Modaks)
var level2_time: float = 0.0
var level2_modaks: int = 0
const MAX_MODAKS: int = 5
const MODAK_VALUE: int = 50
var level2_points: int = 0
var level2_cleared: bool = false
var key_collected: bool = false

# Level 3 (Asur Final Boss Arena)
var level3_time: float = 0.0
var level3_attempts: int = 1 # Starts on attempt 1
var level3_points: int = 0
var level3_cleared: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not is_run_active or is_timer_paused:
		return

	total_time += delta
	match current_level_num:
		1:
			level1_time += delta
		2:
			level2_time += delta
		3:
			level3_time += delta

	run_updated.emit(total_time, total_points)

func pause_run_timer() -> void:
	is_timer_paused = true
	print("[GameRunManager] Run timer paused.")

func resume_run_timer() -> void:
	is_timer_paused = false
	print("[GameRunManager] Run timer resumed.")

func start_new_run() -> void:
	total_time = 0.0
	total_points = 0
	current_level_num = 1

	level1_time = 0.0
	level1_points = 0
	level1_cleared = false

	level2_time = 0.0
	level2_modaks = 0
	level2_points = 0
	level2_cleared = false
	key_collected = false

	level3_time = 0.0
	level3_attempts = 1
	level3_points = 0
	level3_cleared = false

	is_run_active = true
	is_timer_paused = false
	run_started.emit()
	run_updated.emit(total_time, total_points)
	print("[GameRunManager] New game run started! Points: 0, Timer running.")

func set_current_level(lvl: int) -> void:
	current_level_num = lvl
	print("[GameRunManager] Active level set to %d." % lvl)

func award_points(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	total_points += amount
	points_awarded.emit(amount, total_points, reason)
	run_updated.emit(total_time, total_points)
	print("[GameRunManager] +%d PTS awarded (%s)! New total: %d PTS" % [amount, reason, total_points])

func complete_level_1() -> void:
	if level1_cleared:
		return
	level1_cleared = true

	# Level 1 score: Base 300 + Speed Bonus
	var base_pts: int = 300
	var speed_bonus: int = 20
	if level1_time <= 30.0:
		speed_bonus = 200
	elif level1_time <= 60.0:
		speed_bonus = 100
	elif level1_time <= 90.0:
		speed_bonus = 50

	level1_points = base_pts + speed_bonus
	award_points(level1_points, "Level 1 Great Gate Puzzle Solved (Base %d + Speed %d)" % [base_pts, speed_bonus])
	save_run_to_leaderboard()

func collect_modak() -> void:
	if level2_modaks >= MAX_MODAKS:
		return
	level2_modaks += 1
	award_points(MODAK_VALUE, "Sacred Modak Collected (%d/%d)" % [level2_modaks, MAX_MODAKS])
	modak_collected.emit(level2_modaks, MODAK_VALUE)

func record_key_pickup() -> void:
	if key_collected:
		return
	key_collected = true
	award_points(100, "Golden Fortress Key Acquired")

func complete_level_2() -> void:
	if level2_cleared:
		return
	level2_cleared = true

	# Level 2 score: Base 400 + Speed Bonus + Modaks + Key
	var base_pts: int = 400
	var speed_bonus: int = 20
	if level2_time <= 45.0:
		speed_bonus = 250
	elif level2_time <= 90.0:
		speed_bonus = 150
	elif level2_time <= 150.0:
		speed_bonus = 50

	level2_points = base_pts + speed_bonus + (level2_modaks * 50) + (100 if key_collected else 0)
	award_points(base_pts + speed_bonus, "Level 2 Underground Maze Cleared (Base %d + Speed %d)" % [base_pts, speed_bonus])
	save_run_to_leaderboard()

func record_boss_hit() -> void:
	award_points(25, "Asur Stun Hit")

func record_level_3_death() -> void:
	level3_attempts += 1
	print("[GameRunManager] Level 3 player defeated. Attempt count increased to %d." % level3_attempts)

func complete_level_3() -> void:
	if level3_cleared:
		return
	level3_cleared = true
	is_run_active = false

	# Attempt bonus calculation:
	# 1 attempt: 500 pts, 2 attempts: 300 pts, 3 attempts: 150 pts, 4+ attempts: 50 pts
	var attempt_bonus: int = 50
	match level3_attempts:
		1: attempt_bonus = 500
		2: attempt_bonus = 300
		3: attempt_bonus = 150
		_: attempt_bonus = 50

	var speed_bonus: int = 20
	if level3_time <= 60.0:
		speed_bonus = 300
	elif level3_time <= 120.0:
		speed_bonus = 150
	elif level3_time <= 180.0:
		speed_bonus = 50

	var base_boss_defeat = 500
	var blessing_bonus = 250
	level3_points = base_boss_defeat + attempt_bonus + speed_bonus + blessing_bonus

	award_points(level3_points, "Level 3 Boss Defeated & Sacred Blessing Reclaimed (Base %d + Attempt %d + Speed %d + Blessing %d)" % [
		base_boss_defeat, attempt_bonus, speed_bonus, blessing_bonus
	])

	print("[GameRunManager] RUN COMPLETED! Total Time: %s, Total Points: %d" % [format_time(total_time), total_points])

	var summary = save_run_to_leaderboard()
	run_completed.emit(summary)

func save_run_to_leaderboard() -> Dictionary:
	var lm = LeaderboardManager.get_instance()
	var profile = lm.get_player_profile()
	var p_id = profile.get("id", "USR-1001")
	var p_name = profile.get("name", "BraveWarrior")
	var p_avatar = profile.get("avatar", "avatar_4")

	var lvl_reached: float = 3.0 if level3_cleared else (2.0 if level2_cleared else 1.0)
	var formatted_time = format_time(total_time)

	var run_entry = {
		"id": p_id,
		"player": p_name,
		"avatar": p_avatar,
		"level": int(lvl_reached),
		"level_reached_str": "%.1f" % lvl_reached,
		"time": formatted_time,
		"raw_time": total_time,
		"score": total_points,
		"level1_time": level1_time,
		"level1_points": level1_points,
		"level2_time": level2_time,
		"level2_points": level2_points,
		"level2_modaks": level2_modaks,
		"level3_time": level3_time,
		"level3_points": level3_points,
		"level3_attempts": level3_attempts,
		"date": Time.get_date_string_from_system(),
		"is_self": true
	}

	lm.add_run_entry(run_entry)
	return run_entry

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

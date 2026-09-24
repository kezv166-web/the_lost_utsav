extends Node

## Dynamic Game Difficulty Balancing (DDA / Adaptive Heuristic Model)
## Autoload singleton managing combat pacing using an Exponential Moving Average (EMA) Heuristic.
##
## Guarantees Strict Fairness:
## 1. Never alters player physics, movement speed, jump arcs, or hitboxes.
## 2. Smooth, bounded adjustments with hysteresis deadband (prevents rubber-banding).
## 3. Adapts boss telegraphs and attack cooldowns to prevent both player boredom and rage quits.

signal difficulty_tier_changed(tier_name: String, scaling_factor: float)

# Heuristic Score: 0.0 (struggling) <---> 0.5 (balanced flow) <---> 1.0 (mastery)
var flow_score: float = 0.50

# EMA smoothing alpha (low alpha prevents knee-jerk rubber-banding)
const EMA_ALPHA: float = 0.12

# Hysteresis Thresholds (Challenge Flow Zone)
const FLOW_LOWER_BOUND: float = 0.40
const FLOW_UPPER_BOUND: float = 0.70

# Hard Bounds for Clamped Adaptations (Never break core gameplay)
const MIN_SCALE: float = 0.85  # Max 15% easing
const MAX_SCALE: float = 1.18  # Max 18% harder

# Dynamic Output Multipliers
var damage_taken_multiplier: float = 1.0
var boss_attack_cooldown_mult: float = 1.0
var boss_windup_telegraph_mult: float = 1.0

# Performance Trackers
var consecutive_deaths: int = 0
var consecutive_clean_hits: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_recompute_multipliers()

## Call when the player successfully stuns boss, lands clean boulder hit, or executes combos
func record_player_success(intensity: float = 1.0) -> void:
	consecutive_clean_hits += 1
	var target = clampf(0.50 + (0.15 * intensity), 0.0, 1.0)
	flow_score = lerpf(flow_score, target, EMA_ALPHA)
	_recompute_multipliers()

## Call when the player takes damage (scaled by relative severity)
func record_player_damage(damage_amount: float, max_health: float) -> void:
	consecutive_clean_hits = 0
	var severity = clampf(damage_amount / maxf(max_health, 1.0), 0.1, 1.0)
	var target = clampf(0.50 - (0.35 * severity), 0.0, 1.0)
	# Ease difficulty slightly faster upon taking heavy hits
	flow_score = lerpf(flow_score, target, EMA_ALPHA * 1.5)
	_recompute_multipliers()

## Call when the player is defeated / restarts level 3 attempt
func record_attempt_failed() -> void:
	consecutive_deaths += 1
	consecutive_clean_hits = 0
	# Immediate relief on death to prevent frustration
	flow_score = clampf(flow_score - 0.18, 0.0, 1.0)
	_recompute_multipliers()

## Reset on a brand new game run
func reset_run() -> void:
	flow_score = 0.50
	consecutive_deaths = 0
	consecutive_clean_hits = 0
	_recompute_multipliers()

## Recomputes fair, bounded combat multipliers
func _recompute_multipliers() -> void:
	# Inside deadzone: Keep baseline fair challenge
	if flow_score >= FLOW_LOWER_BOUND and flow_score <= FLOW_UPPER_BOUND:
		damage_taken_multiplier = 1.0
		boss_attack_cooldown_mult = 1.0
		boss_windup_telegraph_mult = 1.0
		difficulty_tier_changed.emit("Balanced", 1.0)
		return

	# Calculate normalized offset from baseline flow (0.50)
	var delta = flow_score - 0.50 # Range [-0.5, +0.5]

	# Struggling (delta < 0):
	#   - boss cooldown increases (more breathing room)
	#   - boss telegraph increases (easier to see attack coming)
	#   - damage taken slightly reduced
	# Dominating (delta > 0):
	#   - boss cooldown tightens
	#   - boss telegraph tightens
	damage_taken_multiplier   = clampf(1.0 + (delta * 0.25), 0.88, 1.10)
	boss_attack_cooldown_mult = clampf(1.0 - (delta * 0.35), 0.85, 1.25)
	boss_windup_telegraph_mult= clampf(1.0 - (delta * 0.30), 0.88, 1.20)

	var tier_label = "Challenger" if flow_score > FLOW_UPPER_BOUND else "Novice"
	var factor = clampf(1.0 + (delta * 0.4), MIN_SCALE, MAX_SCALE)
	difficulty_tier_changed.emit(tier_label, factor)

## Helper query methods for boss and player systems
func get_boss_attack_cooldown(base_cooldown: float) -> float:
	return base_cooldown * boss_attack_cooldown_mult

func get_boss_telegraph_duration(base_windup: float) -> float:
	return base_windup * boss_windup_telegraph_mult

func get_modified_incoming_damage(raw_damage: int) -> int:
	return int(round(float(raw_damage) * damage_taken_multiplier))

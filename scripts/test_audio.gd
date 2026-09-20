extends Node

func _ready() -> void:
	print("========================================")
	print("--- MUSIC & AUDIO IMPLEMENTATION TEST ---")
	print("========================================")
	
	# Check autoload singleton
	assert(has_node("/root/MusicManager"), "MusicManager autoload must exist in scene tree")
	var mm = get_node("/root/MusicManager")
	assert(mm != null, "MusicManager must be valid instance")
	
	# Verify all tracks exist and can be loaded
	for key in mm.TRACKS:
		var path = mm.TRACKS[key]
		assert(ResourceLoader.exists(path), "Track file must exist: " + path)
		var stream = load(path)
		assert(stream != null, "Track must load successfully: " + path)
		print("PASSED: Track '%s' loads successfully from '%s'" % [key, path])
		
	# Test 1: Play Outdoor track (usal-sound.mp3)
	mm.play("outdoor")
	assert(mm.get_current_track() == "outdoor", "Current track should be 'outdoor'")
	assert(mm.is_playing(), "MusicManager should be playing")
	print("PASSED: Track 'outdoor' is playing")
	
	# Test 2: Seamless transition to Upper L1 (same sound file, no interruption)
	var active_player_before = mm._active
	mm.play("l1_upper")
	assert(mm.get_current_track() == "l1_upper", "Current track should update to 'l1_upper'")
	assert(mm._active == active_player_before, "Should seamlessly keep playing same player for same audio stream")
	assert(mm.is_playing(), "Music should continue playing seamlessly")
	print("PASSED: Seamless continuation from outdoor to upper L1 (usal-sound)")
	
	# Test 3: Crossfade to Lower L1 / Underground Maze (Om Gan Ganapataye Namah)
	mm.play("l1_lower")
	assert(mm.get_current_track() == "l1_lower", "Current track should be 'l1_lower'")
	assert(mm.is_playing(), "MusicManager should be playing lower level music")
	print("PASSED: Transition to lower level (Om Gan Ganapataye Namah)")
	
	# Test 4: Crossfade to Last Level Boss (Gajamukha_Rise_and_Blaze)
	mm.play("l3_boss")
	assert(mm.get_current_track() == "l3_boss", "Current track should be 'l3_boss'")
	assert(mm.is_playing(), "MusicManager should be playing boss fight music")
	print("PASSED: Transition to last level (Gajamukha Rise and Blaze)")
	
	# Test 5: Verify looping property
	assert(mm._active.stream != null, "Active player must have stream assigned")
	if "loop" in mm._active.stream:
		assert(mm._active.stream.loop == true, "Active stream should have loop enabled")
	print("PASSED: Looping verified on active stream")
	
	print("========================================")
	print("ALL MUSIC & AUDIO TESTS PASSED!")
	print("========================================")
	get_tree().quit(0)

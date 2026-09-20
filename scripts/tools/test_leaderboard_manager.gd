extends SceneTree

# Comprehensive Unit & Integration Test for LeaderboardManager, UISliceManager, LeaderboardPage, and StartPage

func _init() -> void:
	print("==================================================")
	print("--- BEGIN LEADERBOARD & UI INTEGRATION TEST ---")
	print("==================================================")

	var mgr = LeaderboardManager.get_instance()
	assert_true(mgr != null, "LeaderboardManager instance created")

	# ----------------------------------------------------
	# Test 1: Player profile exists and has valid unique ID
	# ----------------------------------------------------
	var profile = mgr.get_player_profile()
	print("[TEST 1] Verifying player profile: ", profile)
	assert_true(profile.has("id"), "Profile has 'id'")
	assert_true(profile.get("id", "").begins_with("USR-"), "Profile ID format is USR-XXXX")
	assert_true(profile.has("name"), "Profile has 'name'")
	assert_true(profile.has("best_time"), "Profile has 'best_time'")
	print("  PASS: Valid unique player identity verified.")

	# ----------------------------------------------------
	# Test 2: Leaderboard entries exist and are sorted by time (fastest first)
	# ----------------------------------------------------
	var entries = mgr.get_entries(10)
	print("\n[TEST 2] Verifying speedrun entries (Count: %d)..." % entries.size())
	assert_true(entries.size() >= 10, "Leaderboard has at least 10 entries")

	var prev_seconds = -1.0
	for i in range(entries.size()):
		var entry = entries[i]
		var rank = entry.get("rank", 0)
		var time_str = entry.get("time", "")
		var sec = LeaderboardManager.time_str_to_seconds(time_str)
		print("  Rank %d: %s [%s] - Time: %s (%.1fs) - Level: %d - Score: %s" % [
			rank,
			entry.get("player", ""),
			entry.get("id", ""),
			time_str,
			sec,
			entry.get("level", 1),
			LeaderboardManager.format_score(entry.get("score", 0))
		])
		assert_true(rank == i + 1, "Rank matches index + 1")
		if prev_seconds >= 0.0:
			assert_true(sec >= prev_seconds, "Time is monotonically increasing (fastest first)")
		prev_seconds = sec

	# ----------------------------------------------------
	# Test 3: Top 3 medals
	# ----------------------------------------------------
	assert_true(entries[0].get("crown") == "gold", "Rank 1 has gold crown")
	assert_true(entries[1].get("crown") == "silver", "Rank 2 has silver crown")
	assert_true(entries[2].get("crown") == "bronze", "Rank 3 has bronze crown")
	print("  PASS: Top 3 speedrunners receive gold, silver, and bronze crowns.")

	# ----------------------------------------------------
	# Test 4: Time conversion accuracy
	# ----------------------------------------------------
	print("\n[TEST 4] Verifying time conversion functions...")
	assert_true(LeaderboardManager.time_str_to_seconds("00:28:14") == 1694.0, "00:28:14 -> 1694s")
	assert_true(LeaderboardManager.time_str_to_seconds("01:00:00") == 3600.0, "01:00:00 -> 3600s")
	assert_true(LeaderboardManager.seconds_to_time_str(1694.0) == "00:28:14", "1694s -> 00:28:14")
	assert_true(LeaderboardManager.format_score(452300) == "452,300", "Score 452300 -> 452,300")
	print("  PASS: Time and score conversions accurate.")

	# ----------------------------------------------------
	# Test 5: Name update
	# ----------------------------------------------------
	print("\n[TEST 5] Testing name update...")
	mgr.update_player_name("VatsalTheBrave")
	var updated_profile = mgr.get_player_profile()
	assert_true(updated_profile.get("name") == "VatsalTheBrave", "Player name updated in profile")
	print("  PASS: Player name updated and saved.")

	# ----------------------------------------------------
	# Test 6: Speedrun record run
	# ----------------------------------------------------
	print("\n[TEST 6] Testing recording a new faster speedrun...")
	var new_rank = mgr.record_run("00:25:00", 3, 490000)
	assert_true(new_rank == 1, "Speedrun of 00:25:00 beats 00:28:14 and achieves Rank #1")
	var new_first = mgr.get_entries(1)[0]
	assert_true(new_first.get("is_self", false) == true, "User is now #1 on the leaderboard")
	assert_true(new_first.get("crown") == "gold", "User now holds the gold crown")
	print("  PASS: New speedrun ranked #1 accurately based on fastest time.")

	# ----------------------------------------------------
	# Test 7: UISliceManager modular extraction & transparency
	# ----------------------------------------------------
	print("\n[TEST 7] Verifying UISliceManager modular extraction & transparency...")
	var lb_bg = UISliceManager.get_leaderboard_bg()
	assert_true(lb_bg != null, "Leaderboard background extracted successfully")
	print("  PASS: Clean Leaderboard background texture: ", lb_bg.get_class(), " Size: ", lb_bg.get_size())

	var sp_bg = UISliceManager.get_start_page_bg()
	assert_true(sp_bg != null, "Start page background extracted successfully")
	print("  PASS: Clean Start page background texture: ", sp_bg.get_class(), " Size: ", sp_bg.get_size())

	var gold_crown = UISliceManager.get_crown("gold")
	assert_true(gold_crown != null, "Gold crown extracted")
	print("  PASS: Clean Gold crown texture: ", gold_crown.get_class(), " Size: ", gold_crown.get_size())

	var avatar_0 = UISliceManager.get_avatar("avatar_0")
	assert_true(avatar_0 != null, "Avatar 0 extracted")
	print("  PASS: Clean Avatar texture: ", avatar_0.get_class(), " Size: ", avatar_0.get_size())

	# ----------------------------------------------------
	# Test 8: Leaderboard scene live instantiation & rows verification
	# ----------------------------------------------------
	print("\n[TEST 8] Verifying Leaderboard Page live instantiation...")
	var lb_scene = load("res://scenes/ui/leaderboard.tscn")
	assert_true(lb_scene != null, "Loaded res://scenes/ui/leaderboard.tscn")
	var lb_page: LeaderboardPage = lb_scene.instantiate() as LeaderboardPage
	assert_true(lb_page != null, "Instantiated LeaderboardPage")

	root.add_child(lb_page)
	lb_page.notification(Node.NOTIFICATION_READY)

	# Verify red square glitch (CrestGlow) is absent
	assert_true(lb_page.get_node_or_null("AmbientVFX/CrestGlow") == null, "CrestGlow glitch node completely eliminated")
	print("  PASS: Red square glitch (CrestGlow) verified eliminated.")

	# Verify rows populated from real data store without crash
	var rows_count = lb_page.rows_container.get_child_count()
	print("  Dynamic rows created: ", rows_count)
	assert_true(rows_count >= 10, "Leaderboard has at least 10 dynamic rows populated")

	# Verify row 1 contents
	var row1 = lb_page.rows_container.get_child(0)
	assert_true(row1 != null, "Row 1 exists")
	var hbox = row1.get_child(0) as HBoxContainer
	assert_true(hbox != null, "Row 1 HBoxContainer exists")
	var crown_rect = hbox.get_child(1) as TextureRect
	var avatar_rect = hbox.get_child(2) as TextureRect
	var player_lbl = hbox.get_child(3) as Label
	var time_lbl = hbox.get_child(5) as Label
	assert_true(crown_rect.texture != null, "Row 1 crown texture present")
	assert_true(avatar_rect.texture != null, "Row 1 avatar texture present")
	print("  PASS: Row 1 verified: Player=%s, Time=%s, Crown=%s" % [player_lbl.text, time_lbl.text, crown_rect.texture.get_class()])

	# Verify user profile card
	assert_true(lb_page.profile_name_lbl.text == "VatsalTheBrave", "Profile card displays updated name")
	print("  PASS: Warrior profile card: ", lb_page.profile_name_lbl.text, " ", lb_page.profile_id_lbl.text)

	# Clean up lb_page
	lb_page.queue_free()

	# ----------------------------------------------------
	# Test 9: Start Page live instantiation & buttons verification
	# ----------------------------------------------------
	print("\n[TEST 9] Verifying Start Page live instantiation...")
	var sp_scene = load("res://scenes/ui/start_page.tscn")
	assert_true(sp_scene != null, "Loaded res://scenes/ui/start_page.tscn")
	var sp_page: StartPage = sp_scene.instantiate() as StartPage
	assert_true(sp_page != null, "Instantiated StartPage")

	root.add_child(sp_page)
	sp_page.notification(Node.NOTIFICATION_READY)
	assert_true(sp_page.btn_play != null, "PlayButton exists")
	assert_true(sp_page.btn_leaderboard != null, "LeaderboardButton exists")
	assert_true(sp_page.background.texture != null, "Start page background texture exists")
	print("  PASS: Start Page verified with clean background and buttons.")
	sp_page.queue_free()

	print("\n==================================================")
	print(">>> ALL LEADERBOARD & UI INTEGRATION TESTS PASSED! <<<")
	print("==================================================")
	quit(0)

func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		printerr("ASSERTION FAILED: ", msg)
		quit(1)

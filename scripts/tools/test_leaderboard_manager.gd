extends SceneTree

# Comprehensive Unit & Integration Test for LeaderboardManager, Google Auth Deduplication, and Leaderboard UI

func _init() -> void:
	print("==================================================")
	print("--- BEGIN LEADERBOARD & UI INTEGRATION TEST ---")
	print("==================================================")

	var mgr = LeaderboardManager.get_instance()
	assert_true(mgr != null, "LeaderboardManager instance created")
	mgr.clear_all_leaderboard_data()
	mgr.player_profile["is_custom_name_chosen"] = false
	mgr.player_profile["is_google_linked"] = false
	mgr.player_profile["google_id"] = ""

	# ----------------------------------------------------
	# Test 1: Player profile exists and has valid unique ID
	# ----------------------------------------------------
	var profile = mgr.get_player_profile()
	print("[TEST 1] Verifying player profile: ", profile)
	assert_true(profile.has("id"), "Profile has 'id'")
	assert_true(profile.get("id", "").begins_with("USR-"), "Profile ID format is USR-XXXX")
	assert_true(profile.has("name"), "Profile has 'name'")
	print("  PASS: Valid unique player identity verified.")

	# ----------------------------------------------------
	# Test 2: Add initial guest run
	# ----------------------------------------------------
	print("\n[TEST 2] Testing recording initial guest run...")
	mgr.add_run_entry({
		"score": 3175,
		"time": "03:15:20",
		"raw_time": 195.2,
		"level": 3,
		"level_reached_str": "3.0"
	})
	var entries = mgr.get_entries(10)
	assert_true(entries.size() >= 1, "Leaderboard has at least 1 entry")
	var self_entries = entries.filter(func(e): return e.get("is_self", false))
	assert_true(self_entries.size() == 1, "Exactly ONE entry exists for the user")
	print("  PASS: Initial run recorded, single row for user verified.")

	# ----------------------------------------------------
	# Test 3: Name update reflected everywhere in real-time
	# ----------------------------------------------------
	print("\n[TEST 3] Testing display name update...")
	mgr.get_player_profile()["is_custom_name_chosen"] = false
	var new_name = mgr.update_player_name("Yadavji")
	assert_true(new_name == "Yadavji", "Name update succeeded")
	assert_true(mgr.get_player_profile().get("name") == "Yadavji", "Profile name is Yadavji")
	for e in mgr.get_entries(10):
		if e.get("is_self", false):
			assert_true(e.get("player") == "Yadavji", "Leaderboard entry player is Yadavji")
	print("  PASS: Name updated in profile and in all leaderboard entries.")

	# ----------------------------------------------------
	# Test 4: Link Google Account & verify row collapsing
	# ----------------------------------------------------
	print("\n[TEST 4] Testing Google Account linking & deduplication...")
	var guest_id = mgr.get_player_profile().get("id", "")
	var google_sub = "116114982046131218244"
	mgr.link_talo_google_account(google_sub)
	assert_true(mgr.get_player_profile().get("is_google_linked", false) == true, "Profile is marked Google linked")
	assert_true(mgr.get_player_profile().get("google_id") == google_sub, "Profile has Google sub ID")
	
	# Verify that linking collapsed the guest row into the Google identity
	var self_after_link = mgr.get_entries(10).filter(func(e): return e.get("is_self", false))
	assert_true(self_after_link.size() == 1, "Still exactly ONE row after Google link")
	assert_true(self_after_link[0].get("id") == google_sub, "Row ID updated to Google sub")
	print("  PASS: Account successfully linked with Google and rows deduplicated.")

	# ----------------------------------------------------
	# Test 5: Cloud Sync Simulation (Multiple incoming entries from Talo)
	# ----------------------------------------------------
	print("\n[TEST 5] Simulating cloud sync with guest + Google entries + placeholders...")
	var mock_cloud_entries = [
		{
			"id": 300101,
			"createdAt": "2026-09-24T02:00:00.000Z",
			"score": 3175,
			"playerAlias": {"service": "google", "identifier": google_sub},
			"props": [{"key": "player", "value": "OldCloudName"}, {"key": "time", "value": "03:15:20"}]
		},
		{
			"id": 300102,
			"createdAt": "2026-09-24T02:00:00.000Z",
			"score": 3100,
			"playerAlias": {"service": "username", "identifier": guest_id},
			"props": [{"key": "player", "value": "OldGuestName"}, {"key": "time", "value": "03:30:00"}]
		},
		{
			"id": 300103,
			"createdAt": "2026-09-24T02:00:00.000Z",
			"score": 2650,
			"playerAlias": {"service": "username", "identifier": "USR-test-placeholder"},
			"props": [{"key": "player", "value": "BraveWarrior"}, {"key": "time", "value": "05:00:00"}]
		},
		{
			"id": 300104,
			"createdAt": "2026-09-24T02:00:00.000Z",
			"score": 3025,
			"playerAlias": {"service": "google", "identifier": "105008778298121843897"},
			"props": [{"key": "player", "value": "Yuvraj"}, {"key": "time", "value": "03:45:00"}]
		},
		{
			"id": 300105,
			"createdAt": "2026-09-24T02:00:00.000Z",
			"score": 2800,
			"playerAlias": {
				"service": "username",
				"identifier": "USR-other-player",
				"player": {
					"id": "other-uuid",
					"props": [{"key": "player", "value": "LiveUpdatedName"}]
				}
			},
			"props": [{"key": "player", "value": "StaleEntryName"}, {"key": "time", "value": "04:00:00"}]
		}
	]
	mgr._merge_talo_scores(mock_cloud_entries)

	var entries_after_merge = mgr.get_entries(10)
	print("  Entries after cloud merge: ", entries_after_merge.size())
	
	# Verify BraveWarrior placeholder was removed
	var placeholders = entries_after_merge.filter(func(e): return e.get("player") == "BraveWarrior")
	assert_true(placeholders.is_empty(), "All legacy BraveWarrior placeholders purged")

	# Verify other player's live updated name took precedence over stale score snapshot
	var other_entry = entries_after_merge.filter(func(e): return e.get("id") == "USR-other-player")
	assert_true(other_entry.size() == 1, "Other player entry exists")
	assert_true(other_entry[0].get("player") == "LiveUpdatedName", "Other player's live name ('LiveUpdatedName') prioritized over stale score name ('StaleEntryName')")

	# Verify user has EXACTLY 1 row, holding the Yadavji name and 3175 score
	var my_rows = entries_after_merge.filter(func(e): return e.get("is_self", false))
	assert_true(my_rows.size() == 1, "Only ONE row exists for the user after cloud merge (No duplicates!)")
	assert_true(my_rows[0].get("player") == "Yadavji", "Active profile name 'Yadavji' was preserved against stale cloud name")
	assert_true(my_rows[0].get("score") == 3175, "Highest score preserved")
	print("  PASS: Cloud sync deduplication and live player name synchronization verified.")

	# ----------------------------------------------------
	# Test 6: Time & Score Utilities
	# ----------------------------------------------------
	print("\n[TEST 6] Verifying time conversion functions...")
	assert_true(LeaderboardManager.time_str_to_seconds("00:28:14") == 1694.0, "00:28:14 -> 1694s")
	assert_true(LeaderboardManager.format_time(1694.0) == "28:14:00" or LeaderboardManager.format_time(1694.0).contains("28:14"), "Format time working")
	assert_true(LeaderboardManager.seconds_to_time_str(1694.0) != "", "seconds_to_time_str alias working")
	assert_true(LeaderboardManager.format_score(452300) == "452,300", "Score formatting working")
	print("  PASS: Time & score utilities verified.")

	# ----------------------------------------------------
	# Test 7: UISliceManager modular extraction
	# ----------------------------------------------------
	print("\n[TEST 7] Verifying UISliceManager...")
	assert_true(UISliceManager.get_leaderboard_bg() != null, "Leaderboard bg exists")
	assert_true(UISliceManager.get_start_page_bg() != null, "Start page bg exists")
	assert_true(UISliceManager.get_crown("gold") != null, "Gold crown exists")
	print("  PASS: UISliceManager verified.")

	# ----------------------------------------------------
	# Test 8: Leaderboard Scene Live Instantiation
	# ----------------------------------------------------
	print("\n[TEST 8] Verifying Leaderboard Page live instantiation & UI rendering...")
	var lb_scene = load("res://scenes/ui/leaderboard.tscn")
	assert_true(lb_scene != null, "Loaded res://scenes/ui/leaderboard.tscn")
	var lb_page: LeaderboardPage = lb_scene.instantiate() as LeaderboardPage
	root.add_child(lb_page)
	lb_page.notification(Node.NOTIFICATION_READY)

	# Verify profile card badge
	assert_true(lb_page.profile_name_lbl.text == "Yadavji", "Profile card shows 'Yadavji'")
	assert_true(lb_page.profile_id_lbl.text == "[GOOGLE]", "Profile card shows '[GOOGLE]' tag (not raw 21-digit UID!)")
	assert_true(lb_page.btn_edit_name.visible == false, "Change Name button is hidden on Leaderboard page")
	print("  PASS: Profile card badge displays clean '[GOOGLE]' tag and edit name button is hidden.")

	# Verify row labels
	var row_count = lb_page.rows_container.get_child_count()
	assert_true(row_count >= 1, "Leaderboard has rows rendered")
	for child in lb_page.rows_container.get_children():
		var row_hbox = child.get_child(0) as HBoxContainer
		if row_hbox and row_hbox.get_child_count() >= 4:
			var player_label = row_hbox.get_child(3) as Label
			if player_label:
				# Should NEVER contain raw google uid in brackets!
				assert_true(not player_label.text.contains(google_sub), "Row label does NOT contain raw Google UID")
				if player_label.text.contains("[YOU]"):
					assert_true(player_label.text.begins_with("Yadavji"), "User row starts with 'Yadavji [YOU]'")
				print("  Row player text: ", player_label.text)
	
	lb_page.queue_free()
	print("  PASS: Leaderboard page rows verified clean with 0 raw UID exposures.")

	# ----------------------------------------------------
	# Test 9: Start Page Live Instantiation
	# ----------------------------------------------------
	print("\n[TEST 9] Verifying Start Page live instantiation & profile badge...")
	var sp_scene = load("res://scenes/ui/start_page.tscn")
	assert_true(sp_scene != null, "Loaded res://scenes/ui/start_page.tscn")
	var sp_page: StartPage = sp_scene.instantiate() as StartPage
	root.add_child(sp_page)
	sp_page.notification(Node.NOTIFICATION_READY)

	assert_true(sp_page._profile_name_lbl != null, "Profile name label exists")
	assert_true(sp_page._profile_name_lbl.text.contains("[GOOGLE]"), "Start page badge displays '[GOOGLE]' tag")
	assert_true(not sp_page._profile_name_lbl.text.contains(google_sub), "Start page badge does not expose raw Google UID")
	print("  Start page badge text: ", sp_page._profile_name_lbl.text)

	sp_page.queue_free()
	print("  PASS: Start Page profile badge verified clean.")

	# ----------------------------------------------------
	# Test 10: One-Time Custom Name Lock & Specific Level Metrics
	# ----------------------------------------------------
	print("\n[TEST 10] Verifying name locking and level-specific data/modak formatting...")
	mgr.lock_custom_name()
	assert_true(mgr.get_player_profile().get("is_custom_name_chosen") == true, "Name is marked chosen/locked")
	var attempted_change = mgr.update_player_name("HackerAttempt")
	assert_true(attempted_change == "Yadavji", "update_player_name rejected modification when name is locked")
	assert_true(mgr.get_player_profile().get("name") == "Yadavji", "Profile name remains 'Yadavji'")

	# Add run with specific level data and 5 Modaks collected
	mgr.add_run_entry({
		"score": 4500,
		"time": "03:10:00",
		"raw_time": 190.0,
		"level": 3,
		"level_reached_str": "3.0",
		"level1_time": 25.4,
		"level1_points": 500,
		"level2_time": 48.0,
		"level2_points": 800,
		"level2_modaks": 5,
		"level3_time": 72.0,
		"level3_points": 950,
		"level3_attempts": 1
	})

	# Test Level 1 Filter
	var l1_entries = mgr.get_filtered_entries("level_1", "all_time")
	assert_true(not l1_entries.is_empty(), "Level 1 entries exist")
	var my_l1 = l1_entries.filter(func(e): return e.get("is_self", false))[0]
	assert_true(my_l1.get("display_level") == "GATE 1", "Level 1 display is 'GATE 1'")
	assert_true(my_l1.get("display_time").contains("25:40") or my_l1.get("display_time").contains("00:25"), "Level 1 gate time is accurate")

	# Test Level 2 Filter (Modaks & Maze Time)
	var l2_entries = mgr.get_filtered_entries("level_2", "all_time")
	assert_true(not l2_entries.is_empty(), "Level 2 entries exist")
	var my_l2 = l2_entries.filter(func(e): return e.get("is_self", false))[0]
	assert_true(my_l2.get("display_level") == "5/5", "Level 2 display is clean '5/5' without broken emoji glyphs")
	assert_true(not my_l2.get("display_level").contains("🍬"), "No broken emoji glyph in Level 2")
	assert_true(my_l2.get("display_time").contains("48:00") or my_l2.get("display_time").contains("00:48"), "Level 2 maze time is accurate")

	# Test Level 3 Filter (Attempts & Boss Time)
	var l3_entries = mgr.get_filtered_entries("level_3", "all_time")
	assert_true(not l3_entries.is_empty(), "Level 3 entries exist")
	var my_l3 = l3_entries.filter(func(e): return e.get("is_self", false))[0]
	assert_true(my_l3.get("display_level") == "Att 1", "Level 3 display is clean 'Att 1'")
	assert_true(not my_l3.get("display_level").contains("⚔"), "No broken glyph in Level 3")
	print("  PASS: Name lock and level-specific data/modak formatting verified.")

	print("\n==================================================")
	print(">>> ALL LEADERBOARD & UI INTEGRATION TESTS PASSED! <<<")
	print("==================================================")
	quit(0)

func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		printerr("ASSERTION FAILED: ", msg)
		quit(1)

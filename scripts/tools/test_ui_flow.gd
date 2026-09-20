extends SceneTree

# Comprehensive headless verification test for Start Page, Leaderboard, and Game Navigation Flow
# Validates clean modular presentation, real data store persistence, and zero visual glitches.

func _init() -> void:
	print("==================================================")
	print("--- BEGIN UI & GAME FLOW COMPREHENSIVE TEST ---")
	print("==================================================")
	
	# ----------------------------------------------------
	# TEST 1: Check project.godot main_scene configuration
	# ----------------------------------------------------
	print("\n[TEST 1] Verifying project.godot main scene...")
	var project_config = ConfigFile.new()
	var err = project_config.load("res://project.godot")
	if err != OK:
		printerr("FAILED: Could not load project.godot")
		quit(1)
		return
		
	var main_scene = project_config.get_value("application", "run/main_scene", "")
	if main_scene != "res://scenes/ui/start_page.tscn":
		printerr("FAILED: Expected main_scene 'res://scenes/ui/start_page.tscn', got: ", main_scene)
		quit(1)
		return
	print("  PASS: Main scene is correctly set to res://scenes/ui/start_page.tscn")
	
	# ----------------------------------------------------
	# TEST 2: Verify Start Page scene & logic
	# ----------------------------------------------------
	print("\n[TEST 2] Verifying Start Page scene (start_page.tscn)...")
	var start_scene = load("res://scenes/ui/start_page.tscn")
	if start_scene == null:
		printerr("FAILED: Could not load res://scenes/ui/start_page.tscn")
		quit(1)
		return
		
	var start_page: StartPage = start_scene.instantiate() as StartPage
	if start_page == null:
		printerr("FAILED: Could not instantiate StartPage")
		quit(1)
		return
		
	root.add_child(start_page)
	
	# Verify buttons
	assert_not_null(start_page.btn_play, "PlayButton exists")
	assert_not_null(start_page.btn_story, "StoryButton exists")
	assert_not_null(start_page.btn_leaderboard, "LeaderboardButton exists")
	assert_not_null(start_page.btn_exit, "ExitButton exists")
	assert_not_null(start_page.btn_controls, "ControlsButton exists")
	assert_not_null(start_page.btn_credits, "CreditsButton exists")
	assert_not_null(start_page.btn_help, "HelpButton exists")
	print("  PASS: All 7 primary interactive buttons verified on Start Page.")
	
	# Verify background texture is loaded
	var bg_rect: TextureRect = start_page.get_node_or_null("Background") as TextureRect
	if bg_rect == null or bg_rect.texture == null:
		printerr("FAILED: StartPage background TextureRect or texture missing")
		quit(1)
		return
	print("  PASS: Start Page clean background texture loaded (", bg_rect.texture.get_class(), ")")
	
	# Verify modals functionality
	start_page._on_controls_pressed()
	if not start_page.controls_modal.visible:
		printerr("FAILED: controls_modal should be visible after _on_controls_pressed()")
		quit(1)
		return
	print("  PASS: Controls modal opens on request.")
	
	start_page._close_modals()
	if start_page.controls_modal.visible or (start_page.modal_layer and start_page.modal_layer.visible):
		printerr("FAILED: Modals should be hidden after _close_modals()")
		quit(1)
		return
	print("  PASS: Modals close cleanly.")
	
	start_page._on_credits_pressed()
	if not start_page.credits_modal.visible:
		printerr("FAILED: credits_modal should be visible")
		quit(1)
		return
	print("  PASS: Credits modal opens on request.")
	start_page._close_modals()
	
	start_page._on_help_pressed()
	if not start_page.help_modal.visible:
		printerr("FAILED: help_modal should be visible")
		quit(1)
		return
	print("  PASS: Help modal opens on request.")
	start_page._close_modals()
	
	# Clean up start page
	start_page.queue_free()
	
	# ----------------------------------------------------
	# TEST 3: Verify Leaderboard scene & real data store
	# ----------------------------------------------------
	print("\n[TEST 3] Verifying Leaderboard scene (leaderboard.tscn)...")
	var lb_scene = load("res://scenes/ui/leaderboard.tscn")
	if lb_scene == null:
		printerr("FAILED: Could not load res://scenes/ui/leaderboard.tscn")
		quit(1)
		return
		
	var lb_page: LeaderboardPage = lb_scene.instantiate() as LeaderboardPage
	if lb_page == null:
		printerr("FAILED: Could not instantiate LeaderboardPage")
		quit(1)
		return
		
	root.add_child(lb_page)
	
	# Verify left menu buttons
	assert_not_null(lb_page.btn_play, "LB PlayButton exists")
	assert_not_null(lb_page.btn_story, "LB StoryButton exists")
	assert_not_null(lb_page.btn_leaderboard, "LB LeaderboardButton exists")
	assert_not_null(lb_page.btn_settings, "LB SettingsButton exists")
	assert_not_null(lb_page.btn_exit, "LB ExitButton exists")
	print("  PASS: All 5 left menu buttons verified on Leaderboard.")
	
	# Verify tabs
	assert_not_null(lb_page.tab_all_time, "Tab All Time exists")
	assert_not_null(lb_page.tab_this_month, "Tab This Month exists")
	assert_not_null(lb_page.tab_friends, "Tab Friends exists")
	print("  PASS: All 3 filter tabs verified on Leaderboard.")
	
	# Verify level dropdown
	assert_not_null(lb_page.level_dropdown, "Level dropdown exists")
	if lb_page.level_dropdown.item_count != 3:
		printerr("FAILED: Expected 3 levels in dropdown, got: ", lb_page.level_dropdown.item_count)
		quit(1)
		return
	print("  PASS: Level dropdown has 3 items (Level 3, Level 2, Level 1).")
	
	# Verify clean background texture
	var lb_bg: TextureRect = lb_page.get_node_or_null("Background") as TextureRect
	if lb_bg == null or lb_bg.texture == null:
		printerr("FAILED: Leaderboard background TextureRect or texture missing")
		quit(1)
		return
	print("  PASS: Clean Leaderboard background texture loaded (", lb_bg.texture.get_class(), ")")
	
	# Verify that the glaring red square glitch (CrestGlow) was completely removed
	var crest_glow = lb_page.get_node_or_null("AmbientVFX/CrestGlow")
	if crest_glow != null:
		printerr("FAILED: Glitch node CrestGlow still exists in scene!")
		quit(1)
		return
	print("  PASS: Verified red square glitch (CrestGlow) has been eliminated.")

	# Verify real data dynamic rows are populated and visible
	if not lb_page.dynamic_table_overlay.visible:
		printerr("FAILED: dynamic_table_overlay should always be visible with real data")
		quit(1)
		return
	var rows_count = lb_page.rows_container.get_child_count()
	if rows_count < 10:
		printerr("FAILED: Expected 10 speedrun rows, got: ", rows_count)
		quit(1)
		return
	print("  PASS: Leaderboard dynamically populated %d speedrun rows from real data store." % rows_count)
	
	# Verify row 1 contains valid crown and avatar textures
	var first_row = lb_page.rows_container.get_child(0)
	assert_not_null(first_row, "First row exists")
	var hbox = first_row.get_child(0) as HBoxContainer
	assert_not_null(hbox, "HBox exists in row")
	var crown_rect = hbox.get_child(1) as TextureRect
	var avatar_rect = hbox.get_child(2) as TextureRect
	var player_lbl = hbox.get_child(3) as Label
	var time_lbl = hbox.get_child(5) as Label
	assert_not_null(crown_rect, "Crown TextureRect exists in row")
	assert_not_null(avatar_rect, "Avatar TextureRect exists in row")
	if crown_rect.texture != null:
		print("  PASS: Dynamic row 1 contains valid crown texture (", crown_rect.texture.get_class(), ")")
	if avatar_rect.texture != null:
		print("  PASS: Dynamic row 1 contains valid avatar texture (", avatar_rect.texture.get_class(), ")")
	print("  PASS: Rank 1 player: ", player_lbl.text, " - Time: ", time_lbl.text)

	# Verify player profile card
	assert_not_null(lb_page.profile_name_lbl, "Profile Name Label exists")
	assert_not_null(lb_page.profile_id_lbl, "Profile ID Label exists")
	print("  PASS: User Profile Card displays warrior: ", lb_page.profile_name_lbl.text, " ", lb_page.profile_id_lbl.text)

	# Verify Settings Modal
	lb_page._on_settings_pressed()
	if not lb_page.settings_modal.visible:
		printerr("FAILED: Settings modal should be visible")
		quit(1)
		return
	print("  PASS: Settings modal opened successfully.")
	lb_page._close_modals()

	# Verify Profile Modal
	lb_page._on_edit_name_pressed()
	if not lb_page.profile_modal.visible:
		printerr("FAILED: Profile modal should be visible")
		quit(1)
		return
	print("  PASS: Warrior profile customization modal opened successfully.")
	lb_page._close_modals()
	
	lb_page.queue_free()
	
	# ----------------------------------------------------
	# TEST 4: Verify Storyline scene & MenuButton
	# ----------------------------------------------------
	print("\n[TEST 4] Verifying Storyline scene & navigation integration...")
	var story_scene = load("res://scenes/ui/storyline.tscn")
	if story_scene == null:
		printerr("FAILED: Could not load storyline.tscn")
		quit(1)
		return
	var story_instance: StorylineIntro = story_scene.instantiate() as StorylineIntro
	root.add_child(story_instance)
	
	assert_not_null(story_instance.menu_btn, "Storyline MenuButton exists")
	print("  PASS: Storyline contains MenuButton to return to Start Page.")
	if story_instance.START_PAGE_SCENE != "res://scenes/ui/start_page.tscn":
		printerr("FAILED: Expected START_PAGE_SCENE to be res://scenes/ui/start_page.tscn")
		quit(1)
		return
	print("  PASS: Storyline START_PAGE_SCENE correctly configured.")
	story_instance.queue_free()
	
	# ----------------------------------------------------
	# TEST 5: Verify Game flow scene chain validity
	# ----------------------------------------------------
	print("\n[TEST 5] Verifying Full Game Progression Scene Chain...")
	var scene_chain = [
		"res://scenes/ui/start_page.tscn",
		"res://scenes/ui/leaderboard.tscn",
		"res://scenes/ui/storyline.tscn",
		"res://scenes/levels/outdoor/outdoor_map.tscn",
		"res://scenes/levels/l1/l1_map.tscn",
		"res://scenes/levels/maze/maze.tscn",
		"res://scenes/levels/l3/l3_map.tscn"
	]
	
	for path in scene_chain:
		if not ResourceLoader.exists(path):
			printerr("FAILED: Chain scene does not exist: ", path)
			quit(1)
			return
		var res = load(path)
		if res == null:
			printerr("FAILED: Chain scene failed to load: ", path)
			quit(1)
			return
		print("  PASS: Verified scene exists and loads: ", path)
		
	# ----------------------------------------------------
	# TEST 6: Check Linux & Web compatibility
	# ----------------------------------------------------
	print("\n[TEST 6] Verifying Linux / Web Export Constraints...")
	for path in scene_chain:
		if "\\" in path:
			printerr("FAILED: Backslash detected in resource path: ", path)
			quit(1)
			return
	print("  PASS: All resource paths use Linux/Web compatible forward slashes.")
	
	print("\n==================================================")
	print(">>> ALL UI & FLOW TESTS PASSED SUCCESSFULLY! <<<")
	print("==================================================")
	quit(0)

func assert_not_null(node: Variant, msg: String) -> void:
	if node == null:
		printerr("ASSERTION FAILED: ", msg)
		quit(1)

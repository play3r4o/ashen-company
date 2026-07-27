extends SceneTree

const Saves = preload("res://src/save_service.gd")

var failures: int = 0

func _init() -> void:
	call_deferred("run_smoke")

func run_smoke() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Control = packed.instantiate()
	root.add_child(game)
	await process_frame
	game._start_new_run("spear")
	check(game.actor_textures.size() == 20, "all player and enemy facing sprites load")
	check(game.actor_frames.size() == 2 and game.health_bar != null, "class sprite frames and in-run health bar load")
	game._spawn_enemy("raider", false)
	var thrust_target = game.enemies.back()
	game.player_position = thrust_target.position - Vector2(30.0, 0.0)
	game.nearest_target = thrust_target
	game.weapon_timers["spear"] = 0.0
	var thrust_health: float = thrust_target.health
	game._fire_weapon("spear")
	check(game.projectiles.is_empty() and thrust_target.health < thrust_health, "spear attacks in contact range without spawning a projectile")
	game.player_hp = 100000.0
	game.player_max_hp = 100000.0
	game.run_elapsed = 360.0
	for index: int in 180:
		game._spawn_enemy(game._choose_wave_enemy(), false)
	var started: int = Time.get_ticks_msec()
	for frame: int in 120:
		game._process_run(1.0 / 60.0)
	var elapsed_ms: int = Time.get_ticks_msec() - started
	check(game.enemies.size() <= game.MAX_ENEMIES + game.MAX_SPECIALS, "enemy cap remains bounded")
	check(game.projectiles.size() <= game.MAX_PROJECTILES, "projectile cap remains bounded")
	check(game.pickups.size() <= game.MAX_PICKUPS, "pickup cap remains bounded")
	var contract_overlay: Control = game.ui_root.get_node_or_null("ContractOverlay")
	if contract_overlay != null:
		game._decline_contract(contract_overlay)
	game.player_position = Vector2(195.0, 430.0)
	game.joystick_vector = Vector2.RIGHT
	game._update_player(0.1)
	game.joystick_vector = Vector2.ZERO
	var released_position: Vector2 = game.player_position
	game._update_player(0.1)
	check(game.player_position.is_equal_approx(released_position), "player stops immediately when movement input is released")
	game.guard_cooldown = 0.0
	game._guard_step()
	check(game.guard_cooldown > 5.9 and game.guard_timer > 0.0, "Guard Step activates and enters cooldown")
	game.joystick_touch_id = 7
	game.joystick_vector = Vector2.RIGHT
	game._show_upgrade_choices()
	check(game.joystick_touch_id == -1 and game.joystick_vector == Vector2.ZERO, "opening an upgrade clears the active joystick touch")
	var upgrade_overlay: Control = game.ui_root.get_node_or_null("UpgradeOverlay")
	check(upgrade_overlay != null, "upgrade overlay is created for the level-up choice")
	if upgrade_overlay != null:
		game._apply_upgrade({"type": "heal", "id": "rations"}, upgrade_overlay)
		check(not game.choosing_upgrade and game.joystick_touch_id == -1 and game.joystick_vector == Vector2.ZERO, "returning from an upgrade accepts fresh movement input")
	check(elapsed_ms < 4000, "two simulated heavy seconds complete within the smoke-test budget")
	var saved_elapsed: float = game.run_elapsed
	game._snapshot_run()
	check(not game.save.active_run.is_empty(), "active expedition creates a resumable snapshot")
	Saves.save_data(game.save)
	game.save = Saves.load_data()
	game._resume_run()
	check(absf(game.run_elapsed - saved_elapsed) < 0.01 and game.weapons.has("spear"), "serialized expedition restores its timer and build")
	game.run_elapsed = 479.0
	game.run_kills = 120
	game.run_elites = 2
	game.boss_defeated = true
	game._finish_run(true)
	check(game.screen == game.Screen.RESULTS and not game.save.profile.veteran.is_empty(), "victory creates results and a Veteran Record")
	game._show_camp()
	check(game.ui_root.get_node_or_null("CampScroll") != null, "camp menu remains reachable in a scroll container")
	game._show_weapon_picker()
	check(game.get_node_or_null("WeaponPickerOverlay") != null, "weapon picker opens from the camp flow")
	game._show_settings()
	check(game.ui_root.find_child("SettingsScroll", true, false) != null, "settings menu remains reachable in a scroll container")
	check(game.ui_root.find_child("ReloadAppButton", true, false) != null, "settings exposes a PWA reload control")
	print("Ashen Company combat smoke: %d ms, %d failures" % [elapsed_ms, failures])
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

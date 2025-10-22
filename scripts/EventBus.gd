extends Node

## EventBus Singleton
## Central hub for all game events and signals

# Game State Signals
signal score_changed(new_score: int)
signal health_changed(new_health: int)
signal citizens_changed(new_citizens: int)
signal game_state_changed(new_state: GameState)

# Turret Signals
@warning_ignore("unused_signal")
signal turret_activated(turret: Node2D)
@warning_ignore("unused_signal")
signal turret_deactivated(turret: Node2D)
@warning_ignore("unused_signal")
signal turret_fired(turret: Node2D, ammo_type: Const.AMMO)
@warning_ignore("unused_signal")
signal turret_reloaded(turret: Node2D)
@warning_ignore("unused_signal")
signal turret_ammo_changed(turret: Node2D, new_amount: int)

# Enemy Signals
@warning_ignore("unused_signal")
signal enemy_spawned(enemy: Node2D)
@warning_ignore("unused_signal")
signal enemy_destroyed(enemy: Node2D, enemy_type: Const.ENEMY_TYPE)
@warning_ignore("unused_signal")
signal enemy_reached_ground(enemy: Node2D)
@warning_ignore("unused_signal")
signal enemy_hit(enemy: Node2D, damage: int)
@warning_ignore("unused_signal")
signal enemy_shield_broken(enemy: Node2D)

# Combat Signals
@warning_ignore("unused_signal")
signal bullet_fired(bullet: Node2D, from_turret: Node2D)
@warning_ignore("unused_signal")
signal bullet_hit(bullet: Node2D, target: Node2D)
@warning_ignore("unused_signal")
signal explosion_triggered(position: Vector2, damage: int, radius: float)

# UI Signals
@warning_ignore("unused_signal")
signal ui_update_requested(element: String, data: Variant)
@warning_ignore("unused_signal")
signal debug_info_changed(info: String)
@warning_ignore("unused_signal")
signal screen_shake_requested(intensity: float, duration: float)

# Input Signals
@warning_ignore("unused_signal")
signal touch_started(touch_index: int, position: Vector2)
@warning_ignore("unused_signal")
signal touch_ended(touch_index: int, position: Vector2)
@warning_ignore("unused_signal")
signal touch_moved(touch_index: int, position: Vector2)

# Spawner Signals
@warning_ignore("unused_signal")
signal spawner_activated(spawner: Node)
@warning_ignore("unused_signal")
signal spawner_deactivated(spawner: Node)
@warning_ignore("unused_signal")
signal wave_started(wave_number: int)
@warning_ignore("unused_signal")
signal wave_completed(wave_number: int)

# Save/Load Signals
@warning_ignore("unused_signal")
signal save_requested()
@warning_ignore("unused_signal")
signal save_completed(success: bool)
@warning_ignore("unused_signal")
signal load_requested()
@warning_ignore("unused_signal")
signal load_completed(success: bool, data: Dictionary)

# Performance Signals
@warning_ignore("unused_signal")
signal object_pool_requested(object_type: String, count: int)
@warning_ignore("unused_signal")
signal object_returned_to_pool(object: Node, pool_type: String)

# Game Flow Signals
@warning_ignore("unused_signal")
signal level_started(level_id: int)
@warning_ignore("unused_signal")
signal level_completed(level_id: int, score: int)
@warning_ignore("unused_signal")
signal game_over(final_score: int, reason: String)
@warning_ignore("unused_signal")
signal pause_requested()
@warning_ignore("unused_signal")
signal resume_requested()

## Game State Enum
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	LEVEL_COMPLETE,
	LOADING
}

## Helper Functions

# Emit score change with validation
func emit_score_changed(new_score: int) -> void:
	if new_score >= 0:
		score_changed.emit(new_score)
	else:
		push_error("Invalid score value: " + str(new_score))

# Emit health change with validation
func emit_health_changed(new_health: int) -> void:
	if new_health >= 0:
		health_changed.emit(new_health)
	else:
		push_error("Invalid health value: " + str(new_health))

# Emit citizens change with validation
func emit_citizens_changed(new_citizens: int) -> void:
	if new_citizens >= 0:
		citizens_changed.emit(new_citizens)
	else:
		push_error("Invalid citizens value: " + str(new_citizens))

# Emit turret activation with validation
func emit_turret_activated(turret: Node2D) -> void:
	if turret and is_instance_valid(turret):
		turret_activated.emit(turret)
	else:
		push_error("Invalid turret reference for activation")

# Emit enemy destruction with validation
func emit_enemy_destroyed(enemy: Node2D, enemy_type: Const.ENEMY_TYPE) -> void:
	if enemy and is_instance_valid(enemy):
		enemy_destroyed.emit(enemy, enemy_type)
	else:
		push_error("Invalid enemy reference for destruction")

# Emit debug info with formatting
func emit_debug_info(info: String) -> void:
	if not info.is_empty():
		debug_info_changed.emit(info)

# Emit screen shake with validation
func emit_screen_shake(intensity: float, duration: float) -> void:
	if intensity > 0.0 and duration > 0.0:
		screen_shake_requested.emit(intensity, duration)
	else:
		push_error("Invalid screen shake parameters: intensity=" + str(intensity) + ", duration=" + str(duration))

## Connection Management

# Connect to all game state signals
func connect_game_state_signals(target: Node) -> void:
	if not target:
		push_error("Cannot connect to null target")
		return
		
	# Connect basic game state signals
	score_changed.connect(target._on_score_changed, CONNECT_ONE_SHOT if target.has_method("_on_score_changed") else 0)
	health_changed.connect(target._on_health_changed, CONNECT_ONE_SHOT if target.has_method("_on_health_changed") else 0)
	citizens_changed.connect(target._on_citizens_changed, CONNECT_ONE_SHOT if target.has_method("_on_citizens_changed") else 0)
	game_state_changed.connect(target._on_game_state_changed, CONNECT_ONE_SHOT if target.has_method("_on_game_state_changed") else 0)

# Connect to all UI signals
func connect_ui_signals(target: Node) -> void:
	if not target:
		push_error("Cannot connect to null target")
		return
		
	ui_update_requested.connect(target._on_ui_update_requested, CONNECT_ONE_SHOT if target.has_method("_on_ui_update_requested") else 0)
	debug_info_changed.connect(target._on_debug_info_changed, CONNECT_ONE_SHOT if target.has_method("_on_debug_info_changed") else 0)
	screen_shake_requested.connect(target._on_screen_shake_requested, CONNECT_ONE_SHOT if target.has_method("_on_screen_shake_requested") else 0)

# Disconnect all signals from target
func disconnect_all_signals(target: Node) -> void:
	if not target:
		return
		
	# Disconnect all signals that might be connected to this target
	for signal_info in get_signal_list():
		var signal_name = signal_info["name"]
		var signal_obj = get(signal_name)
		if signal_obj and signal_obj.is_connected(target):
			signal_obj.disconnect(target)

## Debug Functions

# Print all connected signals for debugging
func debug_print_connections() -> void:
	print("=== EventBus Signal Connections ===")
	for signal_info in get_signal_list():
		var signal_name = signal_info["name"]
		var signal_obj = get(signal_name)
		if signal_obj:
			var connections = signal_obj.get_connections()
			if connections.size() > 0:
				print("Signal: " + signal_name + " - Connections: " + str(connections.size()))
				for connection in connections:
					print("  -> " + str(connection["callable"]))

# Get connection count for a specific signal
func get_signal_connection_count(signal_name: String) -> int:
	var signal_obj = get(signal_name)
	if signal_obj:
		return signal_obj.get_connections().size()
	return 0

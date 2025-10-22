extends Node

## Debug Manager
## Centralized debug utilities and development tools
## Only active in debug builds

var debug_enabled: bool = OS.is_debug_build()
var show_debug_overlay: bool = false
var debug_stats: Dictionary = {}


func _ready() -> void:
	if debug_enabled:
		print("DebugManager initialized (Debug Build)")
	else:
		print("DebugManager initialized (Release Build - debug disabled)")


func _input(event: InputEvent) -> void:
	if not debug_enabled:
		return
	
	# Toggle debug overlay with F3
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			toggle_debug_overlay()
		elif event.keycode == KEY_F4:
			print_debug_stats()
		elif event.keycode == KEY_F5:
			reset_game_progress()


# Toggle debug overlay visibility
func toggle_debug_overlay() -> void:
	show_debug_overlay = not show_debug_overlay
	print("Debug overlay: ", "ON" if show_debug_overlay else "OFF")
	# Emit signal for UI to update
	EventBus.debug_overlay_toggled.emit(show_debug_overlay)


# Reset game progress (for testing)
func reset_game_progress() -> void:
	if not debug_enabled:
		push_warning("Debug function called in release build")
		return
	
	print("Resetting game progress...")
	GlobalVars.nulify_progress()
	print("Game progress reset complete")


# Print all debug statistics
func print_debug_stats() -> void:
	if not debug_enabled:
		return
	
	print("\n=== Debug Statistics ===")
	
	# Memory stats
	if MemoryMonitor:
		var mem_stats = MemoryMonitor.get_memory_stats()
		print("Memory: ", mem_stats["current_mb"], " MB (Peak: ", mem_stats["peak_mb"], " MB)")
		print("Objects: ", mem_stats["object_count"], " | Orphans: ", mem_stats["orphan_nodes"])
	
	# Visibility stats
	if VisibilityManager:
		var vis_stats = VisibilityManager.get_stats()
		print("Entities - Visible: ", vis_stats["visible_entities"], " | Culled: ", vis_stats["culled_entities"])
		print("Cull Rate: ", vis_stats["cull_percentage"], "%")
	
	# Particle stats
	if ParticleOptimizer:
		var particle_stats = ParticleOptimizer.get_stats()
		print("Particles: ", particle_stats["total_particles"], "/", particle_stats["budget"])
		print("Budget Usage: ", particle_stats["budget_usage_percent"], "%")
	
	# Resource stats
	if ResourceManager:
		var res_stats = ResourceManager.get_cache_stats()
		print("Cached Resources: ", res_stats["total_cached"])
		print("Scene Cache: ", res_stats["scene_cache_size"], " | Texture Cache: ", res_stats["texture_cache_size"])
	
	# Game stats
	print("\nGame State:")
	print("Score: ", GlobalVars.score)
	print("Health: ", GlobalVars.health)
	print("Citizens: ", GlobalVars.citizens)
	print("FPS: ", Engine.get_frames_per_second())
	print("========================\n")


# Add debug stat
func add_stat(key: String, value: Variant) -> void:
	debug_stats[key] = value


# Get debug stat
func get_stat(key: String) -> Variant:
	return debug_stats.get(key, null)


# Clear all debug stats
func clear_stats() -> void:
	debug_stats.clear()


# Check if debug mode is enabled
func is_debug_enabled() -> bool:
	return debug_enabled


# Print detailed performance report
func print_performance_report() -> void:
	if not debug_enabled:
		return
	
	print("\n=== Performance Report ===")
	print("FPS: ", Engine.get_frames_per_second())
	print("Time Scale: ", Engine.time_scale)
	print("Process Time: ", Performance.get_monitor(Performance.TIME_PROCESS), " ms")
	print("Physics Time: ", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS), " ms")
	print("Draw Calls: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("Objects Drawn: ", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	print("==========================\n")


# Spawn test enemy (for testing)
func spawn_test_enemy(enemy_type: Const.ENEMY_TYPE = Const.ENEMY_TYPE.TRAINING) -> void:
	if not debug_enabled:
		return
	
	print("Debug: Spawning test enemy of type ", enemy_type)
	# Implementation would go here
	# EventBus.debug_spawn_enemy.emit(enemy_type)


# Give resources (for testing)
func give_resources(amount: int = 1000) -> void:
	if not debug_enabled:
		return
	
	print("Debug: Adding ", amount, " to score")
	GlobalVars.add_score(amount)


# Godmode toggle
var godmode_enabled: bool = false

func toggle_godmode() -> void:
	if not debug_enabled:
		return
	
	godmode_enabled = not godmode_enabled
	print("Godmode: ", "ON" if godmode_enabled else "OFF")
	# Implementation would modify damage calculations


# Print help
func print_debug_help() -> void:
	if not debug_enabled:
		return
	
	print("\n=== Debug Commands ===")
	print("F3 - Toggle debug overlay")
	print("F4 - Print debug stats")
	print("F5 - Reset game progress")
	print("======================\n")


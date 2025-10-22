extends Node

## Resource Management System
## Handles loading, caching, and unloading of game resources to optimize memory usage

# Cached resources with usage tracking
var cached_scenes: Dictionary = {}  # path -> {"resource": PackedScene, "last_used": int, "ref_count": int}
var cached_textures: Dictionary = {}  # path -> {"resource": Texture2D, "last_used": int, "ref_count": int}

# Configuration
const MAX_CACHE_AGE_SECONDS: int = 300  # Unload resources not used for 5 minutes
const CLEANUP_INTERVAL_SECONDS: float = 60.0  # Run cleanup every minute

var cleanup_timer: Timer = null
var current_frame: int = 0


func _ready() -> void:
	# Setup automatic cleanup timer
	cleanup_timer = Timer.new()
	cleanup_timer.wait_time = CLEANUP_INTERVAL_SECONDS
	cleanup_timer.timeout.connect(_on_cleanup_timer_timeout)
	add_child(cleanup_timer)
	cleanup_timer.start()
	
	print("ResourceManager initialized")


func _exit_tree() -> void:
	# Clean up timer
	if cleanup_timer and is_instance_valid(cleanup_timer):
		cleanup_timer.stop()
		cleanup_timer.queue_free()
	
	# Unload all cached resources
	unload_all_resources()


func _process(_delta: float) -> void:
	current_frame += 1


# Load a scene with caching
func load_scene_cached(path: String) -> PackedScene:
	if path.is_empty():
		push_error("ResourceManager: Cannot load scene with empty path")
		return null
	
	# Check if already cached
	if cached_scenes.has(path):
		var cache_entry = cached_scenes[path]
		cache_entry["last_used"] = Time.get_ticks_msec()
		cache_entry["ref_count"] += 1
		return cache_entry["resource"]
	
	# Load the scene
	var scene = load(path) as PackedScene
	if not scene:
		push_error("ResourceManager: Failed to load scene: " + path)
		return null
	
	# Cache it
	cached_scenes[path] = {
		"resource": scene,
		"last_used": Time.get_ticks_msec(),
		"ref_count": 1
	}
	
	return scene


# Load a texture with caching
func load_texture_cached(path: String) -> Texture2D:
	if path.is_empty():
		push_error("ResourceManager: Cannot load texture with empty path")
		return null
	
	# Check if already cached
	if cached_textures.has(path):
		var cache_entry = cached_textures[path]
		cache_entry["last_used"] = Time.get_ticks_msec()
		cache_entry["ref_count"] += 1
		return cache_entry["resource"]
	
	# Load the texture
	var texture = load(path) as Texture2D
	if not texture:
		push_error("ResourceManager: Failed to load texture: " + path)
		return null
	
	# Cache it
	cached_textures[path] = {
		"resource": texture,
		"last_used": Time.get_ticks_msec(),
		"ref_count": 1
	}
	
	return texture


# Release a reference to a scene
func release_scene(path: String) -> void:
	if cached_scenes.has(path):
		cached_scenes[path]["ref_count"] -= 1
		# Don't unload immediately, let the cleanup timer handle it


# Release a reference to a texture
func release_texture(path: String) -> void:
	if cached_textures.has(path):
		cached_textures[path]["ref_count"] -= 1
		# Don't unload immediately, let the cleanup timer handle it


# Manually unload a specific scene
func unload_scene(path: String) -> bool:
	if cached_scenes.has(path):
		cached_scenes.erase(path)
		return true
	return false


# Manually unload a specific texture
func unload_texture(path: String) -> bool:
	if cached_textures.has(path):
		cached_textures.erase(path)
		return true
	return false


# Unload all resources
func unload_all_resources() -> void:
	cached_scenes.clear()
	cached_textures.clear()
	print("ResourceManager: All resources unloaded")


# Automatic cleanup of unused resources
func _on_cleanup_timer_timeout() -> void:
	var current_time = Time.get_ticks_msec()
	var removed_count = 0
	
	# Clean up unused scenes
	var scenes_to_remove: Array[String] = []
	for path in cached_scenes:
		var cache_entry = cached_scenes[path]
		var age_seconds = (current_time - cache_entry["last_used"]) / 1000.0
		
		# Unload if not referenced and old enough
		if cache_entry["ref_count"] <= 0 and age_seconds > MAX_CACHE_AGE_SECONDS:
			scenes_to_remove.append(path)
	
	for path in scenes_to_remove:
		cached_scenes.erase(path)
		removed_count += 1
	
	# Clean up unused textures
	var textures_to_remove: Array[String] = []
	for path in cached_textures:
		var cache_entry = cached_textures[path]
		var age_seconds = (current_time - cache_entry["last_used"]) / 1000.0
		
		# Unload if not referenced and old enough
		if cache_entry["ref_count"] <= 0 and age_seconds > MAX_CACHE_AGE_SECONDS:
			textures_to_remove.append(path)
	
	for path in textures_to_remove:
		cached_textures.erase(path)
		removed_count += 1
	
	if removed_count > 0:
		print("ResourceManager: Cleaned up " + str(removed_count) + " unused resources")


# Get current cache statistics
func get_cache_stats() -> Dictionary:
	return {
		"scenes_cached": cached_scenes.size(),
		"textures_cached": cached_textures.size(),
		"total_cached": cached_scenes.size() + cached_textures.size()
	}


# Print detailed cache information (for debugging)
func print_cache_info() -> void:
	print("\n=== ResourceManager Cache Info ===")
	print("Cached Scenes: " + str(cached_scenes.size()))
	for path in cached_scenes:
		var entry = cached_scenes[path]
		print("  " + path + " (refs: " + str(entry["ref_count"]) + ")")
	
	print("\nCached Textures: " + str(cached_textures.size()))
	for path in cached_textures:
		var entry = cached_textures[path]
		print("  " + path + " (refs: " + str(entry["ref_count"]) + ")")
	
	print("==================================\n")


# Force cleanup now (useful for scene transitions)
func force_cleanup() -> void:
	_on_cleanup_timer_timeout()


# Preload commonly used resources at game start
func preload_common_resources() -> void:
	# This can be called at game start to preload frequently used resources
	# Example:
	# load_scene_cached(Const.PATH_TURRETS + "MachinegunAmmo.tscn")
	# load_texture_cached(Const.PATH_SPRITESHEET)
	pass


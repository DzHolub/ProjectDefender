extends Node

## Particle Optimizer
## Manages particle system settings for optimal performance

# Configuration
const MAX_ACTIVE_PARTICLES: int = 200  # Limit total active particles
const LOD_DISTANCE_NEAR: float = 500.0  # Full quality
const LOD_DISTANCE_FAR: float = 1000.0  # Reduced quality
const CULL_DISTANCE: float = 1500.0  # Stop emitting entirely

var active_particle_systems: Array[CPUParticles2D] = []
var total_particle_count: int = 0


func _ready() -> void:
	print("ParticleOptimizer initialized")


func _process(_delta: float) -> void:
	update_particle_systems()


# Register a particle system for management
func register_particle_system(particles: CPUParticles2D) -> void:
	if particles and not active_particle_systems.has(particles):
		active_particle_systems.append(particles)


# Unregister a particle system
func unregister_particle_system(particles: CPUParticles2D) -> void:
	var index = active_particle_systems.find(particles)
	if index >= 0:
		active_particle_systems.remove_at(index)


# Update all particle systems
func update_particle_systems() -> void:
	cleanup_invalid_particles()
	total_particle_count = 0
	
	var viewport = get_viewport()
	if not viewport:
		return
	
	var camera_pos = Vector2.ZERO
	if viewport.get_camera_2d():
		camera_pos = viewport.get_camera_2d().global_position
	
	for particles in active_particle_systems:
		if not particles or not is_instance_valid(particles):
			continue
		
		var distance = camera_pos.distance_to(particles.global_position)
		apply_lod(particles, distance)
		total_particle_count += particles.amount


# Apply Level of Detail based on distance
func apply_lod(particles: CPUParticles2D, distance: float) -> void:
	if not particles or not is_instance_valid(particles):
		return
	
	if distance > CULL_DISTANCE:
		# Too far, disable particles
		if particles.emitting:
			particles.emitting = false
			particles.process_mode = Node.PROCESS_MODE_DISABLED
	elif distance > LOD_DISTANCE_FAR:
		# Far: Reduce quality significantly
		particles.process_mode = Node.PROCESS_MODE_INHERIT
		if particles.amount > 10:
			particles.amount = 10  # Minimum particles
	elif distance > LOD_DISTANCE_NEAR:
		# Medium: Reduce quality moderately  
		particles.process_mode = Node.PROCESS_MODE_INHERIT
		# Reduce by 50%
		var original_amount = get_original_particle_amount(particles)
		particles.amount = max(10, int(original_amount * 0.5))
	else:
		# Near: Full quality
		particles.process_mode = Node.PROCESS_MODE_INHERIT
		# Restore original amount if it was reduced
		var original_amount = get_original_particle_amount(particles)
		if particles.amount != original_amount:
			particles.amount = original_amount


# Get original particle amount (store in metadata if needed)
func get_original_particle_amount(particles: CPUParticles2D) -> int:
	if particles.has_meta("original_amount"):
		return particles.get_meta("original_amount")
	else:
		# Store current amount as original
		particles.set_meta("original_amount", particles.amount)
		return particles.amount


# Optimize a single particle system
func optimize_particle_system(particles: CPUParticles2D) -> void:
	if not particles or not is_instance_valid(particles):
		return
	
	# Store original settings
	if not particles.has_meta("original_amount"):
		particles.set_meta("original_amount", particles.amount)
	
	# Optimize settings for better performance
	particles.fixed_fps = 30  # Reduce FPS for particles
	
	# Use simpler emission shapes when possible
	if particles.emission_shape == CPUParticles2D.EMISSION_SHAPE_SPHERE:
		# Sphere is fine, but could be simplified
		pass
	
	# Limit lifetime for one-shot particles
	if particles.one_shot and particles.lifetime > 2.0:
		particles.lifetime = 2.0  # Cap at 2 seconds


# Limit total particle count across all systems
func enforce_particle_budget() -> void:
	if total_particle_count <= MAX_ACTIVE_PARTICLES:
		return
	
	# Need to reduce particles
	var reduction_factor = float(MAX_ACTIVE_PARTICLES) / float(total_particle_count)
	
	for particles in active_particle_systems:
		if not particles or not is_instance_valid(particles):
			continue
		
		particles.amount = max(5, int(particles.amount * reduction_factor))


# Clean up invalid particle systems
func cleanup_invalid_particles() -> void:
	var to_remove: Array[CPUParticles2D] = []
	
	for particles in active_particle_systems:
		if not particles or not is_instance_valid(particles):
			to_remove.append(particles)
	
	for particles in to_remove:
		unregister_particle_system(particles)


# Get particle statistics
func get_stats() -> Dictionary:
	return {
		"active_systems": active_particle_systems.size(),
		"total_particles": total_particle_count,
		"budget": MAX_ACTIVE_PARTICLES,
		"budget_usage_percent": (float(total_particle_count) / MAX_ACTIVE_PARTICLES) * 100.0
	}


# Print particle report
func print_particle_report() -> void:
	var stats = get_stats()
	print("\n=== Particle Optimizer Report ===")
	print("Active Systems: " + str(stats["active_systems"]))
	print("Total Particles: " + str(stats["total_particles"]))
	print("Budget: " + str(stats["budget"]))
	print("Budget Usage: " + str(stats["budget_usage_percent"]) + "%")
	print("================================\n")


# Reduce quality for all particles (emergency performance mode)
func reduce_all_particle_quality() -> void:
	for particles in active_particle_systems:
		if not particles or not is_instance_valid(particles):
			continue
		
		particles.amount = max(5, int(particles.amount * 0.5))
		particles.fixed_fps = 15


# Restore normal quality
func restore_particle_quality() -> void:
	for particles in active_particle_systems:
		if not particles or not is_instance_valid(particles):
			continue
		
		var original_amount = get_original_particle_amount(particles)
		particles.amount = original_amount
		particles.fixed_fps = 30


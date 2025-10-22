extends Area2D

var type: Const.AMMO_TYPE
var hit_particles: PackedScene = null
var health: int = 0
var speed: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var damage: int = 0
var rot: float = 0.0
var destruction_time: float = 10.0
var detonation_area_multiplier: float = 0.0
var ammo_gravity: float = 0.0

@onready var destruction_timer: Timer = $DestructionTimer
@onready var explosion_area: Area2D = $ExplosionArea

var start_position: Vector2 = Vector2.ZERO
var bomb_flicker_timer: Timer = null


func _ready() -> void:
	# Validate critical node references
	if not validate_node_references():
		push_error("Ammo missing critical node references")
		queue_free()
		return
	
	# Configure collision layers
	collision_layer = Const.COLLISION_LAYER_BULLET
	collision_mask = Const.COLLISION_MASK_BULLET
	
	# Configure explosion area
	explosion_area.collision_layer = Const.COLLISION_LAYER_EXPLOSION
	explosion_area.collision_mask = Const.COLLISION_MASK_EXPLOSION
	
	# Configure render layer for optimization
	z_index = Const.RENDER_LAYER_PROJECTILES
	
	velocity = Vector2(speed,0).rotated(rot)
	start_position = get_global_position()
	destruction_timer.start(destruction_time)
	match type:
		Const.AMMO_TYPE.EXPLOSIVE:
			bomb_flicker_timer = Timer.new()
			add_child(bomb_flicker_timer)
			bomb_flicker_timer.start(0.4)


func _exit_tree() -> void:
	# Stop and disconnect destruction timer
	if destruction_timer and is_instance_valid(destruction_timer):
		destruction_timer.stop()
		if destruction_timer.timeout.is_connected(_on_DestructionTimer_timeout):
			destruction_timer.timeout.disconnect(_on_DestructionTimer_timeout)
	
	# Clean up dynamically created bomb flicker timer
	if bomb_flicker_timer and is_instance_valid(bomb_flicker_timer):
		bomb_flicker_timer.stop()
		bomb_flicker_timer.queue_free()
		bomb_flicker_timer = null
	
	# Clear hit particles reference
	hit_particles = null


# Validate all required node references exist
func validate_node_references() -> bool:
	var all_valid = true
	
	if not destruction_timer:
		push_error("Ammo missing destruction_timer reference")
		all_valid = false
	
	if not explosion_area:
		push_error("Ammo missing explosion_area reference")
		all_valid = false
	
	return all_valid


func _process(delta: float) -> void:
	velocity.y += ammo_gravity * delta
	position += velocity * delta
	rotation = velocity.angle()
	
	# Only redraw if visible and has custom draw content
	if visible and (type == Const.AMMO_TYPE.LASER or type == Const.AMMO_TYPE.EXPLOSIVE):
		queue_redraw()


func _draw() -> void:
	# Early exit if not visible
	if not visible:
		return
	
	match type:
		Const.AMMO_TYPE.LASER: 
			draw_line(to_local(start_position), to_local(position), Color(0, 0, 0, 
				lerp(0.0, 1.0, destruction_timer.time_left/destruction_timer.wait_time)), 10, true)
		Const.AMMO_TYPE.EXPLOSIVE: 
			if bomb_flicker_timer and is_instance_valid(bomb_flicker_timer):
				draw_circle(to_local(position), 40, Color(0, 0, 0, 
					lerp(0.0, 0.5, bomb_flicker_timer.time_left/bomb_flicker_timer.wait_time)))


func _on_DestructionTimer_timeout() -> void:
	match type:
		Const.AMMO_TYPE.EXPLOSIVE:
			init_explosion()
		_:
			queue_free()


func _on_Bullet_area_entered(area: Area2D) -> void:
	# Check collision layer instead of group for better performance
	if (area.collision_layer & Const.COLLISION_LAYER_ENEMY) != 0:
		if detonation_area_multiplier > 0.0:
			init_explosion()
		else:
			on_hit_behaviour(area)


func on_hit_behaviour(area: Area2D) -> void:
	init_damage(area)
	destroy_behaviour()


func init_explosion() -> void:
	for area in explosion_area.get_overlapping_areas():
		if area is Area2D:
			on_hit_behaviour(area)


func init_damage(area: Area2D) -> void:
	if area.get_parent().has_method("get_damage"):
		area.get_parent().get_damage(damage)
	emit_hit_particles()


func emit_hit_particles() -> void:
	if hit_particles:
		var emitted_particles = hit_particles.instantiate()
		if emitted_particles and is_instance_valid(emitted_particles):
			emitted_particles.global_position = global_position
			
			# Set emitting if it's a particle system
			if emitted_particles is GPUParticles2D or emitted_particles is CPUParticles2D:
				emitted_particles.emitting = true
			
			emitted_particles.rotation_degrees = rotation_degrees
			get_node("/root/").add_child(emitted_particles)


func destroy_behaviour() -> void:
	match type:
		Const.AMMO_TYPE.LASER:
			pass
		_:
			queue_free()

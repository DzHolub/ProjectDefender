extends Area2D

var type: Const.AMMO_TYPE
var hit_particles: Node = null
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
	
	velocity = Vector2(speed,0).rotated(rot)
	start_position = get_global_position()
	destruction_timer.start(destruction_time)
	match type:
		Const.AMMO_TYPE.EXPLOSIVE:
			bomb_flicker_timer = Timer.new()
			add_child(bomb_flicker_timer)
			bomb_flicker_timer.start(0.4)


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
	queue_redraw()


func _draw() -> void:
	match type:
		Const.AMMO_TYPE.LASER: 
			draw_line(to_local(start_position), to_local(position), Color(0, 0, 0, 
				lerp(0.0, 1.0, destruction_timer.time_left/destruction_timer.wait_time)), 10, true)
		Const.AMMO_TYPE.EXPLOSIVE: 
			draw_circle(to_local(position), 40, Color(0, 0, 0, 
				lerp(0.0, 0.5, bomb_flicker_timer.time_left/bomb_flicker_timer.wait_time))) #draw activation zone around the turrent


func _on_DestructionTimer_timeout() -> void:
	match type:
		Const.AMMO_TYPE.EXPLOSIVE:
			init_explosion()
		_:
			queue_free()


func _on_Bullet_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
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
	if hit_particles and is_instance_valid(hit_particles):
		hit_particles.global_position = global_position
		hit_particles.emitting = true
		hit_particles.rotation_degrees = rotation_degrees
	else:
		push_warning("Hit particles are null or invalid")


func destroy_behaviour() -> void:
	match type:
		Const.AMMO_TYPE.LASER:
			pass
		_:
			queue_free()

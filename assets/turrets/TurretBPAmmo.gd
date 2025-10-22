extends Area2D

var type
var hit_particles
var health
var speed
var velocity
var damage
var rot
var destruction_time = 10.0
var detonation_area_multiplier = 0.0

@onready var destruction_timer = $DestructionTimer
@onready var explosion_area = $ExplosionArea

var start_position = null
var bomb_flicker_timer = null


func _ready():
	velocity = Vector2(speed,0).rotated(rot)
	start_position = get_global_position()
	destruction_timer.start(destruction_time)
	match type:
		Const.AMMO_TYPE.EXPLOSIVE:
			bomb_flicker_timer = Timer.new()
			add_child(bomb_flicker_timer)
			bomb_flicker_timer.start(0.4)


func _process(delta):
	velocity.y += gravity * delta
	position += velocity * delta
	rotation = velocity.angle()
	queue_redraw()


func _draw():
	match type:
		Const.AMMO_TYPE.LASER: 
			draw_line(to_local(start_position), to_local(position), Color(0, 0, 0, 
				lerp(0.0, 1.0, destruction_timer.time_left/destruction_timer.wait_time)), 10, true)
		Const.AMMO_TYPE.EXPLOSIVE: 
			draw_circle(to_local(position), 40, Color(0, 0, 0, 
				lerp(0.0, 0.5, bomb_flicker_timer.time_left/bomb_flicker_timer.wait_time))) #draw activation zone around the turrent


func _on_DestructionTimer_timeout():
	match type:
		Const.AMMO_TYPE.EXPLOSIVE: init_explosion()
		_: queue_free()


func _on_Bullet_area_entered(area):
	if area.is_in_group("enemy"):
		if detonation_area_multiplier > 0.0:
			init_explosion()
		else:
			on_hit_behaviour(area)


func on_hit_behaviour(area):
	init_damage(area)
	destroy_behaviour()


func init_explosion():
	for area in explosion_area.get_overlapping_areas():
		on_hit_behaviour(area)


func init_damage(area):
	if area.get_parent().has_method("get_damage"):
		area.get_parent().get_damage(damage)
	emit_hit_particles()


func emit_hit_particles():
	if hit_particles and is_instance_valid(hit_particles):
		hit_particles.global_position = global_position
		hit_particles.emitting = true
		hit_particles.rotation_degrees = rotation_degrees
	else:
		push_warning("Hit particles are null or invalid")


func destroy_behaviour():
	match type:
		Const.AMMO_TYPE.LASER: pass
		_: queue_free()

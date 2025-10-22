extends Node2D

@export var type: Const.ENEMY_TYPE
var start_position
var speed = 10
var rot_speed = 0
var direction_speed = 0
var size_multiplier = 1
var velocity = 0
var health = 10
var shield = 0
var shield_radius = 0
var destruction_time = 50
var turret_damage = 0
var city_damage = 0
var detonation_area_multiplier = 0
var bomb_flicker_timer = 100

var hit_particles = preload(Const.PATH_TURRETS + "MachinegunPrtlHit.tscn")
var death_particles

@onready var sprite = $EnemyBody/EnemySprite
@onready var body = $EnemyBody
@onready var shield_collizion_zone = $EnemyBody/EnemyCollisionZoneD
@onready var destruction_timer = $EnemyDeathTimer
@onready var explosion_area = $EnemyBody/ExplosionArea
@onready var text_label = $EnemyLabel #health and shield info


func _ready():
	body.gravity = 0.01
	GlobalEnemyData.init_enemy(self)
	velocity = Vector2(direction_speed, speed)
	text_label.text = str(health) + "/" + str(shield)
	if shield > 0: #activate collision zone if shield is active
		shield_radius = Helper.get_bigger_vector2_side(sprite.region_rect.size) + Const.ENEMY_SHIELD_SIZE
		shield_collizion_zone.shape = CapsuleShape2D.new()
		shield_collizion_zone.get_shape().radius = shield_radius
	#ammo logic
	start_position = get_global_position()
	destruction_timer.start(destruction_time)
	match type:
		Const.ENEMY_TYPE.BOMB:
			bomb_flicker_timer = Timer.new()
			add_child(bomb_flicker_timer)
			bomb_flicker_timer.start(0.4)


func get_damage(damage: int):
	# Emit enemy hit signal
	EventBus.enemy_hit.emit(self, damage)
	
	if shield > 0:
		shield -= damage
		if shield <= 0:
			health += shield
			shield = 0
			shield_collizion_zone.get_shape().radius = 0
			# Emit shield broken signal
			EventBus.enemy_shield_broken.emit(self)
	elif shield <= 0:
		health -= damage
		
	if health <= 0:
		# Emit enemy destruction signal
		EventBus.enemy_destroyed.emit(self, type)
		
		death_particles.global_position = body.global_position
		death_particles.emitting = true
		get_node('/root').add_child(death_particles)
		
		# Use EventBus for score update instead of direct access
		GlobalVars.add_score(1)
		
		queue_free()
		
	text_label.text = str(health) + "/" + str(shield) + "/" + str(shield_collizion_zone.get_shape().radius)
	queue_redraw()


func _process(delta):
	velocity.y += body.gravity * delta #ammo logic
	position += velocity * delta
	if rot_speed > 0:
		body.rotation += rot_speed * delta
	#ammo logic
	#body.rotation = velocity.angle()
	queue_redraw()


func _on_DeathTimer_timeout():
	match type:
		Const.ENEMY_TYPE.BOMB: explosion()
		_: queue_free()

func explosion():
	for area in explosion_area.get_overlapping_areas():
		make_damage(area)


func _draw():
	var object_pos = to_local(get_global_position())
	if shield > 0:
		draw_circle(object_pos, shield_radius, Const.COLOR_ENEMY_SHIELD_INNER) 
		draw_arc(object_pos, shield_radius, 0, 360, 24, Const.COLOR_ENEMY_SHIELD_OUTER, 5, false)
	#ammo logic
	match type:
		Const.ENEMY_TYPE.TRAINING: 
			draw_line(to_local(start_position), to_local(position), Color(0, 0, 0, 
				lerp(0, 1, destruction_timer.time_left/destruction_timer.wait_time)), 10, true)
		Const.ENEMY_TYPE.BOMB: 
			draw_circle(to_local(position), 40, Color(0, 0, 0, 
				lerp(0.0, 0.5, bomb_flicker_timer.time_left/bomb_flicker_timer.wait_time)))


func movement_behaviour():
	pass


func _on_enemy_body_area_entered(area): # if enemy touches the ground
	if area.is_in_group(Const.GROUND_GROUP) && city_damage != 0:
		# Emit enemy reached ground signal
		EventBus.enemy_reached_ground.emit(self)
		# Use EventBus for citizens update instead of direct access
		GlobalVars.change_citizens(-city_damage)
		get_damage(100000)
	if area.is_in_group(Const.TURRET_GROUP) && turret_damage != 0:
		# Use EventBus for health update instead of direct access
		GlobalVars.change_health(-turret_damage)
		get_damage(100000)
	#ammo logic
	if area.is_in_group(Const.TURRET_GROUP) || area.is_in_group(Const.GROUND_GROUP):
		make_damage(area)

#ammo logic
func make_damage(area):
	if area.has_method("get_damage"):
		area.get_damage(turret_damage)
		area.get_damage(city_damage)
	var emitted_particles = hit_particles.instantiate()
	emitted_particles.global_position = global_position
	emitted_particles.emitting = true
	emitted_particles.rotation_degrees = rotation_degrees
	get_node("/root/").add_child(emitted_particles)
	match type:
		Const.ENEMY_TYPE.TRAINING: pass
		_: queue_free()

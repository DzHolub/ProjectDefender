extends Node2D

const NodeValidator = preload("res://scripts/NodeValidator.gd")

@export var type: Const.ENEMY_TYPE

var start_position: Vector2
var speed: float = 10.0
var rot_speed: float = 0.0
var direction_speed: float = 0.0
var size_multiplier: float = 1.0
var velocity: Vector2 = Vector2.ZERO
var health: int = 10
var shield: int = 0
var shield_radius: float = 0.0
var destruction_time: float = 50.0
var turret_damage: int = 0
var city_damage: int = 0
var detonation_area_multiplier: float = 0.0
var bomb_flicker_timer: Timer = null

var hit_particles: PackedScene = preload(Const.PATH_TURRETS + "MachinegunPrtlHit.tscn")
var death_particles: Node = null

@onready var sprite: Sprite2D = $EnemyBody/EnemySprite
@onready var body: Area2D = $EnemyBody
@onready var shield_collizion_zone: CollisionShape2D = $EnemyBody/EnemyCollisionZoneD
@onready var destruction_timer: Timer = $EnemyDeathTimer
@onready var explosion_area: Area2D = $EnemyBody/ExplosionArea
@onready var text_label: Label = $EnemyLabel # Health and shield info


func _ready() -> void:
	# Validate critical node references
	if not validate_node_references():
		push_error("Enemy missing critical node references")
		return
	
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
	_setup_bomb_timer()


# Validate all required node references exist
func validate_node_references() -> bool:
	var all_valid = true
	
	if not sprite:
		push_error("Enemy missing sprite reference")
		all_valid = false
	
	if not body:
		push_error("Enemy missing body reference")
		all_valid = false
	
	if not shield_collizion_zone:
		push_error("Enemy missing shield_collizion_zone reference")
		all_valid = false
	
	if not destruction_timer:
		push_error("Enemy missing destruction_timer reference")
		all_valid = false
	
	if not explosion_area:
		push_error("Enemy missing explosion_area reference")
		all_valid = false
	
	if not text_label:
		push_error("Enemy missing text_label reference")
		all_valid = false
	
	return all_valid


func _setup_bomb_timer() -> void:
	match type:
		Const.ENEMY_TYPE.BOMB:
			bomb_flicker_timer = Timer.new()
			add_child(bomb_flicker_timer)
			bomb_flicker_timer.start(0.4)


func get_damage(damage: int) -> void:
	# Emit enemy hit signal
	EventBus.enemy_hit.emit(self, damage)
	
	if shield > 0:
		shield -= damage
		if shield <= 0:
			health += shield
			shield = 0
			if shield_collizion_zone and shield_collizion_zone.get_shape():
				shield_collizion_zone.get_shape().radius = 0
			# Emit shield broken signal
			EventBus.enemy_shield_broken.emit(self)
	elif shield <= 0:
		health -= damage
		
	if health <= 0:
		# Emit enemy destruction signal
		EventBus.enemy_destroyed.emit(self, type)
		
		# Safely add death particles
		if death_particles and is_instance_valid(death_particles):
			if body and is_instance_valid(body):
				death_particles.global_position = body.global_position
			death_particles.emitting = true
			
			# Use NodeValidator for safe root access
			var root = NodeValidator.get_root_safe()
			if root:
				root.add_child(death_particles)
		
		# Use EventBus for score update instead of direct access
		GlobalVars.add_score(1)
		
		queue_free()
		return
		
	# Update label with null checks
	if text_label and is_instance_valid(text_label):
		var radius_str = "0"
		if shield_collizion_zone and shield_collizion_zone.get_shape():
			radius_str = str(shield_collizion_zone.get_shape().radius)
		text_label.text = str(health) + "/" + str(shield) + "/" + radius_str
	
	queue_redraw()


func _process(delta: float) -> void:
	velocity.y += body.gravity * delta # Ammo logic
	position += velocity * delta
	if rot_speed > 0:
		body.rotation += rot_speed * delta
	# Ammo logic
	# body.rotation = velocity.angle()
	queue_redraw()


func _on_DeathTimer_timeout() -> void:
	match type:
		Const.ENEMY_TYPE.BOMB:
			explosion()
		_:
			queue_free()


func explosion() -> void:
	for area in explosion_area.get_overlapping_areas():
		make_damage(area)


func _draw() -> void:
	var object_pos: Vector2 = to_local(get_global_position())
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


func _on_enemy_body_area_entered(area: Area2D) -> void: # If enemy touches the ground
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
	# Ammo logic
	if area.is_in_group(Const.TURRET_GROUP) || area.is_in_group(Const.GROUND_GROUP):
		make_damage(area)


# Ammo logic
func make_damage(area: Area2D) -> void:
	# Validate area node
	if not area or not is_instance_valid(area):
		push_warning("Invalid area in make_damage")
		return
	
	if area.has_method("get_damage"):
		area.get_damage(turret_damage)
		area.get_damage(city_damage)
	
	# Safely instantiate and add particles
	if hit_particles:
		var emitted_particles = hit_particles.instantiate()
		if emitted_particles and is_instance_valid(emitted_particles):
			emitted_particles.global_position = global_position
			emitted_particles.emitting = true
			emitted_particles.rotation_degrees = rotation_degrees
			
			# Use NodeValidator for safe root access
			var root = NodeValidator.get_root_safe()
			if root:
				root.add_child(emitted_particles)
	
	match type:
		Const.ENEMY_TYPE.TRAINING: pass
		_: queue_free()

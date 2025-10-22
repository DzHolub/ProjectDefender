extends Area2D

const NodeValidator = preload("res://scripts/NodeValidator.gd")

@export var type: Const.TURRET_TYPE
@export var ammo_amount: int = 50

var rotation_speed: float = 1.0
var fire_rate: float = 1.0 # Faster if less
var sway: float = 0.0
var is_chargeable: bool = false # If weapon needs to be charged before shoot
var is_reload_indicator_on: bool = true
var ammo_type: Const.AMMO = Const.AMMO.MACHINEGUN_BASIC

@onready var textures: Texture2D = GlobalVars.textures
@onready var raycast_line: RayCast2D = $RayCast3D
@onready var ammo_label: Label = $AmmoLabel
@onready var muzzle_particle: CPUParticles2D = $MuzzleShotParticle
@onready var muzzle_point: Marker2D = $EndPoint
@onready var reload_timer: Timer = $ReloadTimer
@onready var charge_timer: Timer = $ChargeTimer

var is_activated: bool = false
var is_shooting: bool = false
var can_shoot: bool = true
var is_charged: bool = false # Check charge of beam weapon
var is_returning_to_base: bool = false

var finger_id: int = -1 # Check exact finger for exact turret to shoot
var turret_start_position: Transform2D
var turret_ui_start_position: Vector2


func _ready() -> void:
	# Validate critical node references
	if not validate_node_references():
		push_error("Turret missing critical node references")
		return
	
	# Configure collision layers
	collision_layer = Const.COLLISION_LAYER_TURRET
	collision_mask = Const.COLLISION_MASK_TURRET
	
	# Configure raycast for enemy detection
	raycast_line.collision_mask = Const.COLLISION_LAYER_ENEMY
	
	# Configure render layer for optimization
	z_index = Const.RENDER_LAYER_TURRETS
	
	GlobalTurretData.init_turret(self)
	reload_timer.set_wait_time(fire_rate)
	ammo_label.text = str(ammo_amount)
	turret_start_position = get_global_transform()
	turret_ui_start_position = ammo_label.global_position
	queue_redraw()


func _exit_tree() -> void:
	# Stop and disconnect timers
	if reload_timer and is_instance_valid(reload_timer):
		reload_timer.stop()
		if reload_timer.timeout.is_connected(_on_ReloadTimer_timeout):
			reload_timer.timeout.disconnect(_on_ReloadTimer_timeout)
	
	if charge_timer and is_instance_valid(charge_timer):
		charge_timer.stop()
		if charge_timer.timeout.is_connected(_on_ChargeTimer_timeout):
			charge_timer.timeout.disconnect(_on_ChargeTimer_timeout)
	
	# Stop particle emissions
	if muzzle_particle and is_instance_valid(muzzle_particle):
		muzzle_particle.emitting = false
	
	# Clear raycast
	if raycast_line and is_instance_valid(raycast_line):
		raycast_line.enabled = false


# Validate all required node references exist
func validate_node_references() -> bool:
	var all_valid = true
	
	if not muzzle_point:
		push_error("Turret missing muzzle_point reference")
		all_valid = false
	
	if not reload_timer:
		push_error("Turret missing reload_timer reference")
		all_valid = false
	
	if not charge_timer:
		push_error("Turret missing charge_timer reference")
		all_valid = false
	
	if not ammo_label:
		push_error("Turret missing ammo_label reference")
		all_valid = false
	
	if not muzzle_particle:
		push_error("Turret missing muzzle_particle reference")
		all_valid = false
	
	return all_valid


func _physics_process(_delta: float) -> void:
	GlobalVars.additional_debug_info = str(is_activated)
	if is_activated && ammo_amount > 0:
		turret_movement()
		turret_fire()
		turret_sway(sway)
	else:
		turret_disable()
		if is_returning_to_base:
			turret_return_to_base()
	if is_activated || is_returning_to_base:
		queue_redraw()


func turret_movement() -> void: # Allows to move turret if it's activated
	# Safely iterate through touch points with validation
	for i in range(GlobalVars.touch_points.size()):
		if i >= 0 and i < GlobalVars.touch_points.size():
			var touch_point = GlobalVars.get_touch_point(i)
			if touch_point.has("assigned_id") and str(touch_point.assigned_id) == str(self):
				if touch_point.has("pos") and touch_point.pos is Vector2:
					rotation = lerp_angle(rotation, (touch_point.pos - global_position).normalized().angle(), rotation_speed)
					turret_ui(touch_point)

	#temporary functionality for mouse
	if OS.get_name() != "Android": 
		rotation = lerp_angle(rotation, (get_global_mouse_position() - global_position).normalized().angle(), rotation_speed)
		var mouse_id = []
		mouse_id.append({pos=Vector2()})
		mouse_id[0].pos = get_global_mouse_position()
		turret_ui(mouse_id[0])


func turret_return_to_base() -> void:
	rotation = lerp_angle(rotation, turret_start_position.get_rotation(), rotation_speed)
	ammo_label.global_position = turret_ui_start_position
	ammo_label.set_rotation(turret_start_position.get_rotation())
	if rotation == turret_start_position.get_rotation():
		is_returning_to_base = false


func turret_disable() -> void:
	muzzle_particle.emitting = false
	is_activated = false
	is_shooting = false
	is_charged = false
	is_returning_to_base = true
	charge_timer.stop()
	if ammo_amount <= 0:
		reload_timer.stop()
	queue_redraw()


func turret_fire() -> void:
	if is_shooting && can_shoot:
		var bullet: Node2D = GlobalAmmoData.ammo(ammo_type)
		bullet.global_position = muzzle_point.global_position
		bullet.rot = rotation
		
		# Use safe root access instead of hard-coded path
		var root: Node = NodeValidator.get_root_safe()
		if root:
			root.add_child(bullet)
		else:
			push_error("Failed to get root node for bullet spawning")
			bullet.queue_free()
			return
		
		muzzle_particle.emitting = true
		is_charged = false
		can_shoot = false
		if ammo_amount >= 1:
			reload_timer.start()
			ammo_amount -= 1
			ammo_label.text = str(ammo_amount)


func turret_sway(sway_amount: float) -> void:
	if (is_charged && type == Const.TURRET_TYPE.LASER) || type == Const.TURRET_TYPE.MACHINEGUN:
		global_rotation += sway_amount * (2.0 * randf() - 1.0) # Bullet spread


func turret_ui(id: Dictionary) -> void:
	ammo_label.set_rotation(-rotation) # Prevent label's rotation
	# Create margin to prevent fix indicator position inside the visible screen area
	var label_margin: Vector2 = Const.UI_ACTIVE_AMMO_INDICATOR_POS
	if id.pos.x >= Helper.get_screen_border_margin(Const.UI_SCREEN_MARGIN_PERCENT, Vector2.RIGHT):
		label_margin.x = -Const.UI_SCREEN_MARGIN_POS
	if id.pos.y <= Helper.get_screen_border_margin(Const.UI_SCREEN_MARGIN_PERCENT, Vector2.UP):
		label_margin.y = +Const.UI_SCREEN_MARGIN_POS
	ammo_label.global_position = id.pos + label_margin


func _draw() -> void:
	var weapon_pos: Vector2 = to_local(get_global_position())
	if is_activated: # Draw shooting line if turret is active
		draw_circle(weapon_pos, Const.UI_TURRET_ACTIVATION_ZONE, Const.COLOR_ACTIVATION_ZONE_ON) # Draw activation zone around the turret
		draw_aim_sight()
	else:
		draw_circle(weapon_pos, Const.UI_TURRET_ACTIVATION_ZONE, Const.COLOR_ACTIVATION_ZONE_OFF) # Draw activation zone around the turret
	if is_reload_indicator_on:
		draw_reload_indicator()
	# draw_health()


func _input(event: InputEvent) -> void:
	# Calculate if finger is within radius, check touches and drags for the exact turret. Activates it
	var touch_distance = self.get_position().distance_to(event.get_position())
	if event is InputEventScreenTouch:
		var touch_index = event.get_index()
		
		# Validate touch index before accessing touch_points array
		if not GlobalVars.validate_touch_index(touch_index):
			push_warning("Invalid touch index in turret input: " + str(touch_index))
			return
		
		# Handle touch press
		if event.is_pressed() and touch_distance <= Const.UI_TURRET_ACTIVATION_ZONE:
			finger_id = touch_index
			GlobalVars.touch_points[finger_id].assigned_id = self
			is_activated = true
		
		# Handle touch release
		if not event.is_pressed() and touch_index == finger_id:
			if is_chargeable and is_charged and touch_distance > Const.UI_TURRET_ACTIVATION_ZONE:
				is_shooting = true
				turret_fire()
			turret_disable()
			GlobalVars.touch_points[finger_id].assigned_id = 0
			finger_id = -1
			Engine.time_scale = 1
		if is_activated && touch_distance > Const.UI_TURRET_ACTIVATION_ZONE:
			if !is_chargeable:
				is_shooting = true
			else: 
				charging_beam()

	if (event is InputEventScreenDrag && event.get_index()==finger_id):
		if is_activated && touch_distance > Const.UI_TURRET_ACTIVATION_ZONE:
			if !is_chargeable:
				is_shooting = true
			else: 
				charging_beam()
		elif is_activated && touch_distance < Const.UI_TURRET_ACTIVATION_ZONE:
			is_shooting = false

	if (event is InputEventMouseButton && OS.get_name() != "Android"): #temporary functionality for mouse tests
		if touch_distance <= Const.UI_TURRET_ACTIVATION_ZONE:
			is_activated = true
		if !event.is_pressed():
			if type == Const.TURRET_TYPE.LASER && is_charged && touch_distance > Const.UI_TURRET_ACTIVATION_ZONE:
				is_shooting = true
				turret_fire()
			turret_disable()
			Engine.time_scale = 1
	if (event is InputEventMouseMotion && OS.get_name() != "Android"):
		if is_activated && touch_distance > Const.UI_TURRET_ACTIVATION_ZONE:
			if type != Const.TURRET_TYPE.LASER:
				is_shooting = true
			else:
				if (is_chargeable):
					charging_beam()


func charging_beam() -> void: # Laser gun mechanics
	Engine.time_scale = lerp(0.3, 1.0, charge_timer.time_left / charge_timer.wait_time)
	if not is_charged and charge_timer.is_stopped():
		charge_timer.start()


func _on_ChargeTimer_timeout() -> void:
	is_charged = true


func _on_ReloadTimer_timeout() -> void:
	can_shoot = true


func draw_reload_indicator() -> void:
	var reload_growth: Vector2 = Vector2(0, ammo_label.size.y).lerp(ammo_label.size, lerp(0.0, 1.0, reload_timer.time_left / fire_rate))
	draw_set_transform(to_local(ammo_label.global_position), -rotation, scale)
	draw_rect(Rect2(Vector2.ZERO, reload_growth), Const.COLOR_RELOAD_INDICATOR, true)


func draw_aim_sight() -> void:
	var muzzle_pos: Vector2 = to_local(muzzle_point.global_position)
	var aim_end_point: Vector2
	if raycast_line.is_colliding():
		# RayCast2D returns Vector2 directly
		aim_end_point = to_local(raycast_line.get_collision_point())
	else:
		aim_end_point = to_local(muzzle_point.global_position) * 2000.0 # Draw laser sight outside of the screen
	if is_chargeable && is_charged: # Darker line for charged laser turret
		draw_line(muzzle_pos, aim_end_point, Const.COLOR_LASER_CHARGED, 2.0)
	else:
		draw_line(to_local(get_global_position()), aim_end_point, Const.COLOR_SIGHT, 2.0)

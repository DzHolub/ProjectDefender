extends Node2D

@export var type: Const.TURRET_TYPE
@export var ammo_amount = 50

var rotation_speed = 1.0
var fire_rate = 1.0 #faster if less
var sway = 0.0
var is_chargeable = false #if weapon need to be charged before shoot
var is_reload_indicator_on = true
var ammo_type = Const.AMMO.MACHINEGUN_BASIC

@onready var textures = GlobalVars.textures
@onready var raycast_line = $RayCast3D
@onready var ammo_label = $AmmoLabel
@onready var muzzle_particle = $MuzzleShotParticle
@onready var muzzle_point = $EndPoint
@onready var reload_timer = $ReloadTimer
@onready var charge_timer = $ChargeTimer

var is_activated = false
var is_shooting = false
var can_shoot = true
var is_charged = false #check charge of beam weapon
var is_returning_to_base = false

var finger_id = -1 #check exact finger for exact turret to shoot
var turret_start_position 
var turret_ui_start_position


func _ready():
	GlobalTurretData.init_turret(self)
	reload_timer.set_wait_time(fire_rate)
	ammo_label.text = str(ammo_amount)
	turret_start_position = get_global_transform()
	turret_ui_start_position = ammo_label.global_position
	queue_redraw()


func _physics_process(_delta):
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


func turret_movement(): #allows to move turret if it's activated
	for id in GlobalVars.touch_points:
		if str(id.assigned_id) == str(self):
			rotation = lerp_angle(rotation, (id.pos - global_position).normalized().angle(), rotation_speed)
			turret_ui(id)

	#temporary functionality for mouse
	if OS.get_name() != "Android": 
		rotation = lerp_angle(rotation, (get_global_mouse_position() - global_position).normalized().angle(), rotation_speed)
		var mouse_id = []
		mouse_id.append({pos=Vector2()})
		mouse_id[0].pos = get_global_mouse_position()
		turret_ui(mouse_id[0])


func turret_return_to_base():
	rotation = lerp_angle(rotation, turret_start_position.get_rotation(), rotation_speed)
	ammo_label.global_position = turret_ui_start_position
	ammo_label.set_rotation(turret_start_position.get_rotation())
	if (rotation == turret_start_position.get_rotation()):
		is_returning_to_base = false


func turret_disable():
	muzzle_particle.emitting = false
	is_activated = false
	is_shooting = false
	is_charged = false
	is_returning_to_base = true
	charge_timer.stop()
	if ammo_amount <= 0:
		reload_timer.stop()
	queue_redraw()


func turret_fire(): 
	if is_shooting && can_shoot:
		var bullet = GlobalAmmoData.ammo(ammo_type)
		bullet.global_position = muzzle_point.global_position
		bullet.rot = rotation
		get_node("/root/").add_child(bullet)
		muzzle_particle.emitting = true
		is_charged = false
		can_shoot = false
		if ammo_amount >= 1:
			reload_timer.start()
			ammo_amount -= 1
			ammo_label.text = str(ammo_amount)


func turret_sway(sway_amount):
	if (is_charged && type == Const.TURRET_TYPE.LASER) || type == Const.TURRET_TYPE.MACHINEGUN:
		global_rotation += sway_amount * (2 * randf() - 1) #bullet spread


func turret_ui(id):
	ammo_label.set_rotation(-rotation) #prevent label's rotation
	#create margin to prevent fix indicator position inside the visible screen area
	var label_margin = Const.UI_ACTIVE_AMMO_INDICATOR_POS
	if id.pos.x >= Helper.get_screen_border_margin(Const.UI_SCREEN_MARGIN_PERCENT, Vector2.RIGHT):
		label_margin.x = -Const.UI_SCREEN_MARGIN_POS
	if id.pos.y <= Helper.get_screen_border_margin(Const.UI_SCREEN_MARGIN_PERCENT, Vector2.UP):
		label_margin.y = +Const.UI_SCREEN_MARGIN_POS
	ammo_label.global_position = id.pos + label_margin


func _draw():
	var weapon_pos = to_local(get_global_position())
	if is_activated: # draw shooting line if turret is active
		draw_circle(weapon_pos, Const.UI_TURRET_ACTIVATION_ZONE, Const.COLOR_ACTIVATION_ZONE_ON) #draw activation zone around the turrent
		draw_aim_sight()
	else:
		draw_circle(weapon_pos, Const.UI_TURRET_ACTIVATION_ZONE, Const.COLOR_ACTIVATION_ZONE_OFF) #draw activation zone around the turrent
	if is_reload_indicator_on:
		draw_reload_indicator()
	#draw_health()


func _input(event):
	#calculate if finger is within radius check touches and drags for the exact turret. Activates it
	var touch_distance = self.get_position().distance_to(event.get_position())
	if (event is InputEventScreenTouch):
		if touch_distance <= Const.UI_TURRET_ACTIVATION_ZONE:
			finger_id = event.get_index()
			GlobalVars.touch_points[finger_id].assigned_id = self
			is_activated = true
		if !event.is_pressed() && event.get_index() == finger_id:
			if is_chargeable && is_charged && touch_distance > Const.UI_TURRET_ACTIVATION_ZONE:
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


func charging_beam(): #laser gun mechanics
	Engine.time_scale = lerp(0.3, 1.0, charge_timer.time_left/charge_timer.wait_time)
	if !is_charged and charge_timer.is_stopped():
		charge_timer.start()


func _on_ChargeTimer_timeout():
	is_charged = true


func _on_ReloadTimer_timeout():
	can_shoot = true


func draw_reload_indicator():
	var reload_growth = Vector2(0, ammo_label.size.y).lerp(ammo_label.size, lerp(0.0, 1.0, reload_timer.time_left/fire_rate))
	draw_set_transform(to_local(ammo_label.global_position), -rotation, scale)
	draw_rect(Rect2(Vector2.ZERO, reload_growth), Const.COLOR_RELOAD_INDICATOR, true)


func draw_aim_sight():
	var muzzle_pos = to_local(muzzle_point.global_position)
	var aim_end_point
	if raycast_line.is_colliding():
		aim_end_point = to_local(raycast_line.get_collision_point())
	else:
		aim_end_point = to_local(muzzle_point.global_position) * 2000 #draw laser sight outside of the screen
	if is_chargeable && is_charged: #darker line for charged laser turret
		draw_line(muzzle_pos, aim_end_point, Const.COLOR_LASER_CHARGED, 2)
	else: 
		draw_line(to_local(get_global_position()), aim_end_point, Const.COLOR_SIGHT, 2)

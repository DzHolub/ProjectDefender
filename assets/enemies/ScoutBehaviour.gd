extends Node2D

const NodeValidator = preload("res://scripts/NodeValidator.gd")

var ammo: PackedScene = load(Const.PATH_ENEMIES + "Bomb.tscn")
var border: Vector2 = GlobalVars.project_resolution
var enemy: Node2D = null
@onready var tween: Tween = null
var pos_x: float = 0.0
var pos_y: float = 0.0
var repeats: int = 0

var muzzle_point: Node2D = null
var bullet_speed: float = 100.0
var damage: int = 1


func init(obj: Node2D) -> void:
	enemy = obj
	tween = enemy.create_tween()
	pos_x = randf_range(20.0, border.x - 20.0)
	pos_y = randf_range(20.0, border.y - 200.0)
	
	# Use safe node access instead of hard-coded path
	muzzle_point = NodeValidator.get_node_safe(enemy, "EnemyBody/EndPoint")
	if not muzzle_point:
		push_error("Failed to find EndPoint node in Scout enemy")
		# Create a fallback position at enemy position
		muzzle_point = enemy
	
	entry()


func entry():
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(enemy, "global_position", Vector2(enemy.global_position.x, 200), 1.0)
	tween.tween_interval(1.5)
	await tween.finished
	tween.kill()
	movement()


func movement():
	var rot = enemy.global_position.direction_to(
		Vector2(pos_x, pos_y)).angle() - PI / 2.0
	tween = enemy.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if repeats < 5:
		repeats += 1
		tween.tween_property(enemy, "global_position", Vector2(pos_x, pos_y), 1.0)
		tween.parallel().tween_property(enemy, "rotation", rot, 0.5)
		await tween.finished
		tween.kill()
		change_position()
	else:
		tween.tween_property(enemy, "rotation", 
			enemy.global_position.direction_to(
		Vector2(enemy.global_position.x, border.y)).angle() - PI / 2.0, 1.0)
		tween.tween_interval(1.5)
		tween.tween_property(enemy, "global_position", 
			Vector2(0, 0 + 10000), 1.0).as_relative()


func change_position():
	if randf() > 0.5: shoot()
	pos_x = randf_range(20.0, border.x - 20.0)
	pos_y = randf_range(20.0, border.y - 200)
	movement()


func shoot():
	if not ammo:
		push_warning("Ammo scene is null in scout behaviour")
		return
	
	var bullet = ammo.instantiate()
	if not bullet or not is_instance_valid(bullet):
		push_error("Failed to instantiate bullet in scout behaviour")
		return
	
	bullet.type = Const.ENEMY_TYPE.BOMB
	
	if muzzle_point and is_instance_valid(muzzle_point):
		bullet.global_position = muzzle_point.global_position
	
	# Use NodeValidator for safe root access
	var root = NodeValidator.get_root_safe()
	if root:
		root.add_child(bullet)
	else:
		if bullet:
			bullet.queue_free()

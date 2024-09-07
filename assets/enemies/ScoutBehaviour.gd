extends Node2D

var ammo = load(Const.PATH_ENEMIES + "Bomb.tscn")
var border = GlobalVars.project_resolution
var enemy = null
@onready var tween = null
var pos_x = 0.0
var pos_y = 0.0
var repeats = 0

var muzzle_point = null
var bullet_speed = 100
var damage = 1


func init(obj):
	enemy = obj
	tween = enemy.create_tween()
	pos_x = randf_range(20.0, border.x - 20.0)
	pos_y = randf_range(20.0, border.y - 200.0)
	muzzle_point = enemy.get_node("EnemyBody/EndPoint")
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
	var bullet = ammo.instantiate()
	bullet.type = Const.ENEMY_TYPE.BOMB
	bullet.global_position = muzzle_point.global_position
	enemy.get_node("/root").add_child(bullet)

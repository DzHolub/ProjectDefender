extends Node


func init_enemy(enemy):
	match(enemy.type):
		Const.ENEMY_TYPE.ASTEROID:
			enemy.health = 110
			enemy.shield = 150
			enemy.rot_speed = 0.8
			enemy.city_damage = 1000
			enemy.turret_damage = 5
			enemy.body.gravity = 5
			enemy.direction_speed = 5
			enemy.death_particles = load(Const.PATH_ENEMIES + "AsteroidPrtlDestroy.tscn").instantiate()
		Const.ENEMY_TYPE.SCOUT:
			enemy.health = 50
			enemy.shield = 50
			enemy.speed = 80
			enemy.turret_damage = 5
			enemy.city_damage = 1000
			load(Const.PATH_ENEMIES + "ScoutBehaviour.gd").new().init(enemy)
			enemy.death_particles = load(Const.PATH_ENEMIES + "AsteroidPrtlDestroy.tscn").instantiate()
		Const.ENEMY_TYPE.BOMB:
			enemy.health = 5
			enemy.speed = 80
			enemy.turret_damage = 5
			enemy.city_damage = 1000
			enemy.death_particles = load(Const.PATH_ENEMIES + "AsteroidPrtlDestroy.tscn").instantiate()
		_:
			pass

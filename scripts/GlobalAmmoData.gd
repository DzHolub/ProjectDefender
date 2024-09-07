extends Node

var ammo_instance: Node

var machinegun_ammo = preload(Const.PATH_TURRETS + "MachinegunAmmo.tscn")
var laser_ammo = preload(Const.PATH_TURRETS + "LaserAmmo.tscn")
var artillery_ammo = preload(Const.PATH_TURRETS + "ArtilleryAmmo.tscn")
var machinegun_hit_particles = preload(Const.PATH_TURRETS + "MachinegunPrtlHit.tscn")
var laser_hit_particles = preload(Const.PATH_TURRETS + "MachinegunPrtlHit.tscn")
var artillery_hit_particles = preload(Const.PATH_TURRETS + "ArtilleryPrtlExplode.tscn")


func ammo(ammo_name):
	match(ammo_name):
		Const.AMMO.MACHINEGUN_BASIC:
			ammo_instance = machinegun_ammo.instantiate()
			ammo_instance.type = Const.AMMO_TYPE.BULLET
			ammo_instance.speed = 5000
			ammo_instance.damage = 50
			ammo_instance.hit_particles = machinegun_hit_particles.instantiate()
		Const.AMMO.LASER_BASIC:
			ammo_instance = laser_ammo.instantiate()
			ammo_instance.type = Const.AMMO_TYPE.LASER
			ammo_instance.speed = 5000
			ammo_instance.damage = 800
			ammo_instance.hit_particles = laser_hit_particles.instantiate()
		Const.AMMO.ARTILLERY_BASIC:
			ammo_instance = artillery_ammo.instantiate()
			ammo_instance.type = Const.AMMO_TYPE.EXPLOSIVE
			ammo_instance.speed = 500
			ammo_instance.damage = 1800
			ammo_instance.hit_particles = artillery_hit_particles.instantiate()
	return ammo_instance

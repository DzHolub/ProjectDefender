extends Node


func init_turret(turret):
	match(turret.type):
		Const.TURRET_TYPE.MACHINEGUN:
			turret.rotation_speed = 0.2
			turret.fire_rate = 0.25
			turret.sway = 0.001
			turret.ammo_type = Const.AMMO.MACHINEGUN_BASIC
		Const.TURRET_TYPE.LASER:
			turret.rotation_speed = 0.015
			turret.fire_rate = 1.0
			turret.sway = 0.003
			turret.is_chargeable = true
			turret.ammo_type = Const.AMMO.LASER_BASIC
		Const.TURRET_TYPE.ARTILLERY:
			turret.rotation_speed = 0.1
			turret.fire_rate = 3.0
			turret.ammo_type = Const.AMMO.ARTILLERY_BASIC
		_:
			pass

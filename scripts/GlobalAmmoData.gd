extends Node

var ammo_instance: Node

var machinegun_ammo: PackedScene
var laser_ammo: PackedScene
var artillery_ammo: PackedScene
var machinegun_hit_particles: PackedScene
var laser_hit_particles: PackedScene
var artillery_hit_particles: PackedScene

var resources_loaded: bool = false


func _ready():
	load_ammo_resources()


func load_ammo_resources() -> void:
	# Load ammunition scenes with validation
	machinegun_ammo = ResourceValidator.load_scene(Const.PATH_TURRETS + "MachinegunAmmo.tscn")
	laser_ammo = ResourceValidator.load_scene(Const.PATH_TURRETS + "LaserAmmo.tscn")
	artillery_ammo = ResourceValidator.load_scene(Const.PATH_TURRETS + "ArtilleryAmmo.tscn")
	
	# Load particle effect scenes with validation
	machinegun_hit_particles = ResourceValidator.load_scene(Const.PATH_TURRETS + "MachinegunPrtlHit.tscn")
	laser_hit_particles = ResourceValidator.load_scene(Const.PATH_TURRETS + "MachinegunPrtlHit.tscn")
	artillery_hit_particles = ResourceValidator.load_scene(Const.PATH_TURRETS + "ArtilleryPrtlExplode.tscn")
	
	# Validate all resources loaded successfully
	resources_loaded = validate_all_resources()
	
	if not resources_loaded:
		push_error("Some ammunition resources failed to load")
	else:
		print("All ammunition resources loaded successfully")


func validate_all_resources() -> bool:
	var all_valid = true
	
	if machinegun_ammo == null:
		push_error("Machinegun ammo scene missing")
		all_valid = false
	if laser_ammo == null:
		push_error("Laser ammo scene missing")
		all_valid = false
	if artillery_ammo == null:
		push_error("Artillery ammo scene missing")
		all_valid = false
	if machinegun_hit_particles == null:
		push_warning("Machinegun hit particles missing")
	if laser_hit_particles == null:
		push_warning("Laser hit particles missing")
	if artillery_hit_particles == null:
		push_warning("Artillery hit particles missing")
	
	return all_valid


func ammo(ammo_name: Const.AMMO) -> Node:
	if not resources_loaded:
		push_error("Ammo resources not loaded, attempting to reload")
		load_ammo_resources()
		if not resources_loaded:
			return null
	
	match(ammo_name):
		Const.AMMO.MACHINEGUN_BASIC:
			ammo_instance = safe_instantiate_ammo(machinegun_ammo, "Machinegun")
			if ammo_instance:
				ammo_instance.type = Const.AMMO_TYPE.BULLET
				ammo_instance.speed = 5000
				ammo_instance.damage = 50
				ammo_instance.hit_particles = safe_instantiate_particles(machinegun_hit_particles)
				
		Const.AMMO.LASER_BASIC:
			ammo_instance = safe_instantiate_ammo(laser_ammo, "Laser")
			if ammo_instance:
				ammo_instance.type = Const.AMMO_TYPE.LASER
				ammo_instance.speed = 5000
				ammo_instance.damage = 800
				ammo_instance.hit_particles = safe_instantiate_particles(laser_hit_particles)
				
		Const.AMMO.ARTILLERY_BASIC:
			ammo_instance = safe_instantiate_ammo(artillery_ammo, "Artillery")
			if ammo_instance:
				ammo_instance.type = Const.AMMO_TYPE.EXPLOSIVE
				ammo_instance.speed = 500
				ammo_instance.damage = 1800
				ammo_instance.hit_particles = safe_instantiate_particles(artillery_hit_particles)
	
	return ammo_instance


func safe_instantiate_ammo(scene: PackedScene, ammo_name: String) -> Node:
	if scene == null:
		push_error("Cannot instantiate null ammo scene: " + ammo_name)
		return null
	
	var instance = ResourceValidator.instantiate_scene(scene, ammo_name)
	if instance == null:
		push_error("Failed to instantiate ammo: " + ammo_name)
		return null
	
	return instance


func safe_instantiate_particles(scene: PackedScene) -> Node:
	if scene == null:
		push_warning("Particle scene is null, skipping")
		return null
	
	var instance = scene.instantiate()
	return instance

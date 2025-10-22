extends Node

const ResourceValidator = preload("res://scripts/ResourceValidator.gd")

# Cache particle scenes to avoid repeated loading
var asteroid_particles: PackedScene
var scout_behaviour_script: Script


func _ready():
	load_enemy_resources()


func load_enemy_resources() -> void:
	# Load particle effects with validation
	asteroid_particles = ResourceValidator.load_scene(Const.PATH_ENEMIES + "AsteroidPrtlDestroy.tscn")
	if asteroid_particles == null:
		push_error("Failed to load asteroid destruction particles")
	
	# Load scout behavior script with validation
	var script_path = Const.PATH_ENEMIES + "ScoutBehaviour.gd"
	if ResourceValidator.resource_exists(script_path):
		scout_behaviour_script = load(script_path)
		if scout_behaviour_script == null:
			push_error("Failed to load scout behaviour script")
	else:
		push_error("Scout behaviour script does not exist: " + script_path)


func init_enemy(enemy: Node2D) -> void:
	if enemy == null:
		push_error("Cannot initialize null enemy")
		return
	
	match(enemy.type):
		Const.ENEMY_TYPE.ASTEROID:
			enemy.health = 110
			enemy.shield = 150
			enemy.rot_speed = 0.8
			enemy.city_damage = 1000
			enemy.turret_damage = 5
			enemy.body.gravity = 5
			enemy.direction_speed = 5
			enemy.death_particles = safe_load_particles(asteroid_particles, "Asteroid")
			
		Const.ENEMY_TYPE.SCOUT:
			enemy.health = 50
			enemy.shield = 50
			enemy.speed = 80
			enemy.turret_damage = 5
			enemy.city_damage = 1000
			
			# Initialize scout behaviour with validation
			if scout_behaviour_script != null:
				var behaviour = scout_behaviour_script.new()
				if behaviour != null and behaviour.has_method("init"):
					behaviour.init(enemy)
				else:
					push_error("Scout behaviour script invalid or missing init method")
			else:
				push_error("Cannot initialize scout behaviour - script not loaded")
			
			enemy.death_particles = safe_load_particles(asteroid_particles, "Scout")
			
		Const.ENEMY_TYPE.BOMB:
			enemy.health = 5
			enemy.speed = 80
			enemy.turret_damage = 5
			enemy.city_damage = 1000
			enemy.death_particles = safe_load_particles(asteroid_particles, "Bomb")
		_:
			push_warning("Unknown enemy type: " + str(enemy.type))


func safe_load_particles(particle_scene: PackedScene, enemy_name: String) -> Node:
	if particle_scene == null:
		push_warning("Particle scene is null for enemy: " + enemy_name)
		# Return a dummy node so the game doesn't crash
		return Node2D.new()
	
	var particles = particle_scene.instantiate()
	if particles == null:
		push_error("Failed to instantiate particles for enemy: " + enemy_name)
		return Node2D.new()
	
	return particles

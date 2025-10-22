extends Node

const ResourceValidator = preload("res://scripts/ResourceValidator.gd")

@export var queue_position: int = 0
@export var delay_time: float = 0.0
@export var random: bool = false
@export var enemy_type: Dictionary = {}
@export var spawn_queue: GDScript = null

@onready var spawn_timer: Timer = $SpawnTimer
@onready var delay_timer: Timer = $DelayTimer

var spawn_index: int = 0
var left_scr_margin: float = 0.0
var right_scr_margin: float = 0.0
var get_all_enemies: Dictionary = {}


func _ready() -> void:
	# Validate critical node references
	if not validate_node_references():
		push_error("Spawner missing critical node references")
		return
	
	left_scr_margin = Helper.get_screen_border_margin(10, Vector2.LEFT)
	right_scr_margin = Helper.get_screen_border_margin(10, Vector2.RIGHT)
	Helper.get_screen_border_margin(15, Vector2.LEFT)
	
	# Load enemy scenes with validation
	load_enemy_scenes()
	
	check_queue()
	init_spawner_index_data()


func _exit_tree() -> void:
	# Stop and disconnect timers
	if spawn_timer and is_instance_valid(spawn_timer):
		spawn_timer.stop()
		if spawn_timer.timeout.is_connected(_on_SpawnTimer_timeout):
			spawn_timer.timeout.disconnect(_on_SpawnTimer_timeout)
	
	if delay_timer and is_instance_valid(delay_timer):
		delay_timer.stop()
		if delay_timer.timeout.is_connected(_on_DelayTimer_timeout):
			delay_timer.timeout.disconnect(_on_DelayTimer_timeout)
	
	# Clear loaded enemy scenes dictionary
	get_all_enemies.clear()


# Validate all required node references exist
func validate_node_references() -> bool:
	var all_valid = true
	
	if not spawn_timer:
		push_error("Spawner missing spawn_timer reference")
		all_valid = false
	
	if not delay_timer:
		push_error("Spawner missing delay_timer reference")
		all_valid = false
	
	return all_valid


func load_enemy_scenes() -> void:
	# Load enemy scenes with validation
	var meteor_scene = ResourceValidator.load_scene(Const.PATH_ENEMIES + "Meteor.tscn")
	var asteroid_scene = ResourceValidator.load_scene(Const.PATH_ENEMIES + "Asteroid.tscn")
	var scout_scene = ResourceValidator.load_scene(Const.PATH_ENEMIES + "Scout.tscn")
	
	# Only add successfully loaded scenes to the dictionary
	if meteor_scene != null:
		get_all_enemies[Const.ENEMY_TYPE.METEOR] = meteor_scene
	else:
		push_error("Failed to load Meteor scene")
	
	if asteroid_scene != null:
		get_all_enemies[Const.ENEMY_TYPE.ASTEROID] = asteroid_scene
	else:
		push_error("Failed to load Asteroid scene")
	
	if scout_scene != null:
		get_all_enemies[Const.ENEMY_TYPE.SCOUT] = scout_scene
	else:
		push_error("Failed to load Scout scene")
	
	print("Loaded " + str(get_all_enemies.size()) + " enemy types in spawner")


func check_queue() -> void:
	for i in GlobalVars.spawner_nodes: # Check which spawner must be on right now
		if i.queue_position == GlobalVars.spawner_queue:
			if i.delay_timer.is_stopped():
				i.delay_timer.start(delay_time)


func init_spawner_index_data() -> void:
	enemy_type.clear()
	var inner_dict: Dictionary = spawn_queue.QUEUE[spawn_index]
	for q in inner_dict.keys():
		enemy_type[q] = inner_dict[q]


func _on_SpawnTimer_timeout() -> void:
	var randomizer: Array = [] # Array to randomize existing ships' spawn
	for i in enemy_type:
		if enemy_type[i] > 0:
			randomizer.append(i)
	if !randomizer.is_empty(): #if these are still some ships - spawn them
		var rand_enemy = randomizer[randi()%randomizer.size()]
		
		# Validate enemy scene exists before instantiating
		if not get_all_enemies.has(rand_enemy):
			push_error("Enemy type not found in spawner: " + str(rand_enemy))
			enemy_type[rand_enemy] = 0  # Skip this enemy type
			return
		
		var enemy_scene = get_all_enemies[rand_enemy]
		if enemy_scene == null:
			push_error("Enemy scene is null: " + str(rand_enemy))
			enemy_type[rand_enemy] = 0  # Skip this enemy type
			return
		
		# Safe instantiation with validation
		var e = ResourceValidator.instantiate_scene(enemy_scene, "Enemy_" + str(rand_enemy))
		if e == null:
			push_error("Failed to instantiate enemy: " + str(rand_enemy))
			enemy_type[rand_enemy] = 0  # Skip this enemy type
			return
		
		if random: #if random is on - then mix spawn time and place
			spawn_timer.set_wait_time(randf_range(0.4, 3))
			e.global_position.x = randf_range(left_scr_margin, right_scr_margin)
		
		add_child(e)
		
		# Emit enemy spawned signal
		EventBus.enemy_spawned.emit(e)
		
		enemy_type[rand_enemy] -= 1 #decrease one spawned ship from the pool
	else:
		if spawn_index < (spawn_queue.QUEUE.size() - 1):
			spawn_index += 1
			init_spawner_index_data()
		else:
			spawn_timer.stop()
			GlobalVars.spawner_queue += 1
			check_queue()


func _on_DelayTimer_timeout() -> void: # Delay between different spawners - "next wave"
	spawn_timer.start(1.5)

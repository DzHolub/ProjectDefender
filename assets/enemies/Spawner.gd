extends Node

@export var queue_position: int
@export var delay_time: float
@export var random: bool
@export var enemy_type: Dictionary
@export var spawn_queue: GDScript
@onready var spawn_timer = $SpawnTimer
@onready var delay_timer = $DelayTimer
var spawn_index = 0
var left_scr_margin
var right_scr_margin
var get_all_enemies = {
		Const.ENEMY_TYPE.METEOR: preload(Const.PATH_ENEMIES + "Meteor.tscn"), 
		Const.ENEMY_TYPE.ASTEROID: preload(Const.PATH_ENEMIES + "Asteroid.tscn"), 
		Const.ENEMY_TYPE.SCOUT: preload(Const.PATH_ENEMIES + "Scout.tscn")
}

func _ready():
	left_scr_margin = Helper.get_screen_border_margin(10, Vector2.LEFT)
	right_scr_margin = Helper.get_screen_border_margin(10, Vector2.RIGHT)
	Helper.get_screen_border_margin(15, Vector2.LEFT)
	check_queue()
	init_spawner_index_data()


func check_queue():
	for i in GlobalVars.spawner_nodes: #check which spawner must be on right now
		if i.queue_position == GlobalVars.spawner_queue:
			if i.delay_timer.is_stopped():
				i.delay_timer.start(delay_time)


func init_spawner_index_data():
	enemy_type.clear()
	var inner_dict = spawn_queue.QUEUE[spawn_index]
	for q in inner_dict.keys():
		enemy_type[q] = inner_dict[q]


func _on_SpawnTimer_timeout():
	var randomizer = [] #array to randomize existing ships' spawn
	for i in enemy_type:
		if enemy_type[i] > 0:
			randomizer.append(i)
	if !randomizer.is_empty(): #if these are still some ships - spawn them
		var rand_enemy = randomizer[randi()%randomizer.size()]
		var e = get_all_enemies[rand_enemy].instantiate() #spawn randomized enemy
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


func _on_DelayTimer_timeout(): #delay between different spawners - "next wave"
	spawn_timer.start(1.5)

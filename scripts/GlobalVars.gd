extends Node2D
class_name Helper

@onready var debug_label = get_node("/root/LevelMockup/UIIngame/DebugLabel")
var textures = preload(Const.PATH_SPRITESHEET)
var additional_debug_info = ''

var selected_level = 0 #pass here info regarding level to load
var score = 0
var health = 3
var citizens = 45000

var touch_points = []
var max_touches = 2 #means max are 2 touches at once
var current_touches = 0 #how many touches are now
var project_resolution = Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height")
	)

#collect all enemyspawner nodes
@onready var spawner_nodes = get_tree().get_nodes_in_group("Spawner")
var spawner_queue = 0
	
func _ready():
	#save data for positions in multitouch
	for _x in range(max_touches):
		touch_points.append({pos=Vector2(), start_pos=Vector2(), 
		state = false, assigned_id = 0})
	load_progress()


func _input(event):
	if event is InputEventScreenDrag:
		touch_points[event.index].pos  = event.position
	if event is InputEventScreenTouch:
		touch_points[event.index].state = event.pressed
		touch_points[event.index].pos  = event.position
		if event.pressed:
			touch_points[event.index].start_pos = event.position
	current_touches = 0
	for point in touch_points:
		if point.state:
			current_touches += 1


func _process(_delta): 
	debug_label.text = str("Score: ", score, " || Time=", Engine.time_scale, additional_debug_info)
	if health <= 0:
		pass


func save_progress():
	var save_dict = {
		"score" : score,
		"health" : health,
		"citizens" : citizens
	}
	var save_game = FileAccess.open(Const.PATH_DATA, FileAccess.WRITE)
	save_game.store_line(JSON.stringify(save_dict))
	save_game.close()


func load_progress():
	if FileAccess.file_exists(Const.PATH_DATA):
		var data_file = FileAccess.open(Const.PATH_DATA, FileAccess.READ)
		var test_json_conv = JSON.new()
		test_json_conv.parse(data_file.get_line())
		var progress_data = test_json_conv.get_data()
		for i in progress_data.keys():
			set(i, progress_data[i])
		data_file.close()
		print(progress_data)
	else: #if data doesnt exist - create it and repeat procedure
		save_progress()
		load_progress()


func nulify_progress(): #for debug - delete it later
	score = 0
	health = 4
	citizens = 45000
	save_progress()


#HELPER FUNCTIONS START

static func get_bigger_vector2_side(size: Vector2):
	if size.x > size.y:
		return size.x
	else:
		return size.y

#side vector can be left, right, top, bottom
static func get_screen_border_margin(margin_percent: float, side: Vector2):
	var axis_pos
	if (side == Vector2.RIGHT || side == Vector2.LEFT):
		axis_pos = GlobalVars.project_resolution.x
	else: 
		axis_pos = GlobalVars.project_resolution.y
	var calculated_margin = (axis_pos / 100) * margin_percent
	match side:
		Vector2.RIGHT:
			return axis_pos - calculated_margin
		Vector2.LEFT:
			return 0 + calculated_margin
		Vector2.UP:
			return 0 + calculated_margin
		Vector2.DOWN:
			return axis_pos - calculated_margin

#HELPER FUNCTIONS END

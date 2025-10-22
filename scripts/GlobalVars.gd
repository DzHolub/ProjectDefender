extends Node2D
class_name Helper

var textures = preload(Const.PATH_SPRITESHEET)
var additional_debug_info = ''

var selected_level = 0 #pass here info regarding level to load
var score: int = 0
var health: int = 3
var citizens: int = 45000

var touch_points: Array[Dictionary] = []
var max_touches: int = 2 #means max are 2 touches at once
var current_touches: int = 0 #how many touches are now
var project_resolution: Vector2 = Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height")
	)

#collect all enemyspawner nodes
@onready var spawner_nodes = get_tree().get_nodes_in_group("Spawner")
var spawner_queue: int = 0
	
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
	# Emit debug info via EventBus instead of direct label access
	var debug_text = str("Score: ", score, " || Time=", Engine.time_scale, additional_debug_info)
	EventBus.emit_debug_info(debug_text)
	
	if health <= 0:
		EventBus.game_over.emit(score, "Health depleted")

## Game State Management Functions

# Update score and emit signal
func add_score(amount: int) -> void:
	if amount > 0:
		score += amount
		EventBus.emit_score_changed(score)

# Update health and emit signal
func change_health(amount: int) -> void:
	health += amount
	if health < 0:
		health = 0
	EventBus.emit_health_changed(health)

# Update citizens and emit signal
func change_citizens(amount: int) -> void:
	citizens += amount
	if citizens < 0:
		citizens = 0
	EventBus.emit_citizens_changed(citizens)

# Set additional debug info
func set_debug_info(info: String) -> void:
	additional_debug_info = info

func save_progress():
	EventBus.save_requested.emit()
	
	# Validate save data before attempting to save
	if not validate_save_data():
		push_error("Save data validation failed")
		EventBus.save_completed.emit(false)
		return
	
	var save_dict = {
		"score" : score,
		"health" : health,
		"citizens" : citizens,
		"version" : "1.0",  # Add version for future compatibility
		"timestamp" : Time.get_unix_time_from_system()
	}
	
	# Attempt to serialize data
	var json_string = JSON.stringify(save_dict)
	if json_string.is_empty():
		push_error("Failed to serialize save data - data may be corrupted")
		EventBus.save_completed.emit(false)
		return
	
	# Try to open file with error handling
	var save_game = FileAccess.open(Const.PATH_DATA, FileAccess.WRITE)
	if save_game == null:
		var error_code = FileAccess.get_open_error()
		push_error("Failed to open save file. Error code: " + str(error_code))
		EventBus.save_completed.emit(false)
		return
	
	# Write data with error checking
	save_game.store_line(json_string)
	save_game.close()
	
	# Verify file was written correctly
	if not verify_save_file():
		push_error("Save file verification failed")
		EventBus.save_completed.emit(false)
		return
	
	print("Save completed successfully")
	EventBus.save_completed.emit(true)


func load_progress():
	EventBus.load_requested.emit()
	
	if not FileAccess.file_exists(Const.PATH_DATA):
		print("No save file found, creating new save")
		save_progress()
		return
	
	# Try to open file with error handling
	var data_file = FileAccess.open(Const.PATH_DATA, FileAccess.READ)
	if data_file == null:
		var error_code = FileAccess.get_open_error()
		push_error("Failed to open load file. Error code: " + str(error_code))
		handle_corrupted_save()
		return
	
	# Read file content with error checking
	if data_file.eof_reached():
		push_error("Save file is empty")
		data_file.close()
		handle_corrupted_save()
		return
	
	var file_content = data_file.get_line()
	data_file.close()
	
	if file_content.is_empty():
		push_error("Save file contains no data")
		handle_corrupted_save()
		return
	
	# Parse JSON with comprehensive error handling
	var json_parser = JSON.new()
	var parse_result = json_parser.parse(file_content)
	
	if parse_result != OK:
		push_error("Failed to parse save data. JSON error: " + str(parse_result))
		handle_corrupted_save()
		return
	
	var progress_data = json_parser.get_data()
	if progress_data == null:
		push_error("Parsed save data is null")
		handle_corrupted_save()
		return
	
	# Validate loaded data
	if not validate_loaded_data(progress_data):
		push_error("Loaded save data failed validation")
		handle_corrupted_save()
		return
	
	# Apply loaded data with error checking
	if not apply_loaded_data(progress_data):
		push_error("Failed to apply loaded data")
		handle_corrupted_save()
		return
	
	print("Load completed successfully: ", progress_data)
	EventBus.load_completed.emit(true, progress_data)


## Data Validation Functions

func validate_save_data() -> bool:
	# Check if current data is valid before saving
	if score < 0:
		push_error("Invalid score value: " + str(score))
		return false
	if health < 0 or health > 10:  # Reasonable health range
		push_error("Invalid health value: " + str(health))
		return false
	if citizens < 0 or citizens > 100000:  # Reasonable citizens range
		push_error("Invalid citizens value: " + str(citizens))
		return false
	return true


func validate_loaded_data(data: Dictionary) -> bool:
	# Check if loaded data has required fields
	var required_fields = ["score", "health", "citizens"]
	for field in required_fields:
		if not data.has(field):
			push_error("Missing required field in save data: " + field)
			return false
	
	# Validate data ranges
	if not data["score"] is int or data["score"] < 0:
		push_error("Invalid score in save data: " + str(data["score"]))
		return false
	if not data["health"] is int or data["health"] < 0 or data["health"] > 10:
		push_error("Invalid health in save data: " + str(data["health"]))
		return false
	if not data["citizens"] is int or data["citizens"] < 0 or data["citizens"] > 100000:
		push_error("Invalid citizens in save data: " + str(data["citizens"]))
		return false
	
	# Check version compatibility if present
	if data.has("version"):
		var version = data["version"]
		if version != "1.0":
			print("Warning: Save file version mismatch. Expected 1.0, got " + str(version))
	
	return true


func apply_loaded_data(data: Dictionary) -> bool:
	# Safely apply loaded data with error checking
	if not data.has("score") or not data.has("health") or not data.has("citizens"):
		push_error("Missing required data fields")
		return false
		
	score = data["score"]
	health = data["health"]
	citizens = data["citizens"]
	
	# Emit signals for loaded data
	EventBus.emit_score_changed(score)
	EventBus.emit_health_changed(health)
	EventBus.emit_citizens_changed(citizens)
	
	return true


func verify_save_file() -> bool:
	# Verify the save file was written correctly
	if not FileAccess.file_exists(Const.PATH_DATA):
		return false
	
	var verify_file = FileAccess.open(Const.PATH_DATA, FileAccess.READ)
	if verify_file == null:
		return false
	
	var content = verify_file.get_line()
	verify_file.close()
	
	if content.is_empty():
		return false
	
	# Try to parse the content to verify it's valid JSON
	var json_parser = JSON.new()
	var parse_result = json_parser.parse(content)
	return parse_result == OK


func handle_corrupted_save():
	# Handle corrupted save files gracefully
	push_error("Save file is corrupted, creating backup and resetting")
	
	# Create backup of corrupted file
	if FileAccess.file_exists(Const.PATH_DATA):
		var backup_path = Const.PATH_DATA + ".backup." + str(Time.get_unix_time_from_system())
		var corrupted_file = FileAccess.open(Const.PATH_DATA, FileAccess.READ)
		var backup_file = FileAccess.open(backup_path, FileAccess.WRITE)
		
		if corrupted_file != null and backup_file != null:
			backup_file.store_string(corrupted_file.get_as_text())
			backup_file.close()
			corrupted_file.close()
			print("Corrupted save backed up to: " + backup_path)
	
	# Reset to default values
	reset_to_defaults()
	
	# Create new save file
	save_progress()
	
	EventBus.load_completed.emit(false, {})


func reset_to_defaults():
	# Reset game state to default values
	score = 0
	health = 3
	citizens = 45000
	
	# Emit signals for reset values
	EventBus.emit_score_changed(score)
	EventBus.emit_health_changed(health)
	EventBus.emit_citizens_changed(citizens)
	
	print("Game state reset to defaults")


func nulify_progress(): #for debug - delete it later
	score = 0
	health = 4
	citizens = 45000
	EventBus.emit_score_changed(score)
	EventBus.emit_health_changed(health)
	EventBus.emit_citizens_changed(citizens)
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

extends Control

var current_score: int = 0
var current_citizens: int = 0
var critical_number_citizens: int = 0
var tween_node: Tween = null

@onready var low_lives_timer: Timer = $LowLivesTimer
@onready var citizens_info: Node2D = $CitizensInfo
@onready var citizens_count: Label = $CitizensInfo/CitizensCount
@onready var debug_label: Label = $DebugLabel


func _ready() -> void:
	# Validate critical node references
	if not validate_node_references():
		push_error("UI missing critical node references")
		return
	
	current_citizens = GlobalVars.citizens
	current_score = GlobalVars.score
	citizens_count.text = format_number_with_k(current_citizens)
	critical_number_citizens = int((GlobalVars.citizens / 100.0) * 20.0)
	
	# Connect to EventBus signals instead of polling
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.citizens_changed.connect(_on_citizens_changed)
	EventBus.debug_info_changed.connect(_on_debug_info_changed)
	EventBus.game_over.connect(_on_game_over)


func _exit_tree() -> void:
	# Disconnect all EventBus signals
	if EventBus.score_changed.is_connected(_on_score_changed):
		EventBus.score_changed.disconnect(_on_score_changed)
	
	if EventBus.citizens_changed.is_connected(_on_citizens_changed):
		EventBus.citizens_changed.disconnect(_on_citizens_changed)
	
	if EventBus.debug_info_changed.is_connected(_on_debug_info_changed):
		EventBus.debug_info_changed.disconnect(_on_debug_info_changed)
	
	if EventBus.game_over.is_connected(_on_game_over):
		EventBus.game_over.disconnect(_on_game_over)
	
	# Stop timer
	if low_lives_timer and is_instance_valid(low_lives_timer):
		low_lives_timer.stop()
	
	# Clean up tween
	if tween_node and is_instance_valid(tween_node):
		tween_node.kill()
		tween_node = null


# Validate all required node references exist
func validate_node_references() -> bool:
	var all_valid = true
	
	if not low_lives_timer:
		push_error("UI missing low_lives_timer reference")
		all_valid = false
	
	if not citizens_info:
		push_error("UI missing citizens_info reference")
		all_valid = false
	
	if not citizens_count:
		push_error("UI missing citizens_count reference")
		all_valid = false
	
	if not debug_label:
		push_warning("UI missing debug_label reference (non-critical)")
		# Don't mark as invalid since debug_label is checked before use
	
	return all_valid


func _on_score_changed(new_score: int):
	current_score = new_score
	# Update any score-related UI elements here if needed


func _on_citizens_changed(new_citizens: int):
	current_citizens = new_citizens
	citizens_count.text = format_number_with_k(current_citizens)
	
	# Check if citizens are critically low
	if current_citizens <= critical_number_citizens:
		on_citizens_changed()


func _on_debug_info_changed(info: String):
	if debug_label:
		debug_label.text = info


func _on_game_over(final_score: int, reason: String):
	print("Game Over! Score: ", final_score, " Reason: ", reason)
	# Handle game over UI here


func _on_Button_pressed() -> void: # FOR DEBUG - DELETE IT LATER
	GlobalVars.nulify_progress()


func on_citizens_changed() -> void:
	var tween: Tween = self.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.stop()
	## Shake effect
	# tween.tween_property(citizens_info, "shake_offset:x", 15, 3)
	# tween.tween_property(citizens_info, "shake_offset:y", 15, 3)
	# Zoom effect
	tween.tween_property(citizens_info, "scale", Vector2(2.0, 2.0), 0.1)
	tween.tween_property(citizens_info, "scale", Vector2(1.0, 1.0), 0.1)
	tween.play()


func format_number_with_k(number: int) -> String:
	if number >= 1000:
		var thousands: int = int(number / 1000.0)
		return str(thousands) + "k"
	else:
		return str(number)

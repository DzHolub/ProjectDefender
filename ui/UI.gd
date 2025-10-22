extends Control

var current_score: int
var current_citizens: int
var critical_number_citizens: int
var tween_node = null
@onready var low_lives_timer = $LowLivesTimer
@onready var citizens_info = $CitizensInfo
@onready var citizens_count = $CitizensInfo/CitizensCount
@onready var debug_label = $DebugLabel


func _ready():
	current_citizens = GlobalVars.citizens
	current_score = GlobalVars.score
	citizens_count.text = format_number_with_k(current_citizens)
	critical_number_citizens = int((GlobalVars.citizens / 100.0) * 20.0)
	
	# Connect to EventBus signals instead of polling
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.citizens_changed.connect(_on_citizens_changed)
	EventBus.debug_info_changed.connect(_on_debug_info_changed)
	EventBus.game_over.connect(_on_game_over)


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


func _on_Button_pressed(): #FOR DEBUG - DELETE IT LATER
	GlobalVars.nulify_progress()


func on_citizens_changed():
	var tween = self.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.stop()
	## Shake effect
	#tween.tween_property(citizens_info, "shake_offset:x", 15, 3)
	#tween.tween_property(citizens_info, "shake_offset:y", 15, 3)
	# Zoom effect
	tween.tween_property(citizens_info, "scale", Vector2(2,2), 0.1)
	tween.tween_property(citizens_info, "scale", Vector2(1,1), 0.1)
	tween.play()


func format_number_with_k(number: int) -> String:
	if number >= 1000:
		var thousands = int(number / 1000.0)
		return str(thousands) + "k"
	else:
		return str(number)

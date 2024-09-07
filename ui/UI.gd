extends Control

var current_score
var current_citizens
var critical_number_citizens
var tween_node = null
@onready var low_lives_timer = $LowLivesTimer
@onready var citizens_info = $CitizensInfo
@onready var citizens_count = $CitizensInfo/CitizensCount


func _ready():
	current_citizens = GlobalVars.citizens
	current_score = GlobalVars.score
	citizens_count.text = format_number_with_k(current_citizens)
	critical_number_citizens = int((GlobalVars.citizens / 100.0) * 20.0)


func _process(_delta):
	if current_citizens != GlobalVars.citizens or current_citizens <= critical_number_citizens or current_score != GlobalVars.score:
		current_citizens = GlobalVars.citizens
		current_score = GlobalVars.score
		citizens_count.text = format_number_with_k(current_citizens)
		on_citizens_changed()


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

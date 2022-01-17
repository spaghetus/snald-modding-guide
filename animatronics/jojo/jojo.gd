extends AnimatronicBase
onready var night = $"/root/EventMan".night_index
export var office_door_circuit = "office_door_toggle"
func difficulty_offset():
	return 69
var difficulty_offset_2 = 0
	# heat and noise makes the funny
func _ready():
	animation_player = get_node("AnimationPlayer")
	$MovementTimer.wait_time = rand_range(30 - difficulty, 70 - difficulty)
	assume_state(0)

func state_machine():
	if state in [0,1,2,3]:
		$MovementTimer.wait_time = rand_range(30 - difficulty, 70 - difficulty)
		return state + 1 
	match state:
		4:
			$MovementTimer.wait_time = 3
			return 5
		5:
			if (office_door_circuit in $"/root/EventMan".circuit_states) and ($"/root/EventMan".circuit_states[office_door_circuit]):
				$"/root/EventMan".jumpscare("jojo", "door")
				return 0
			else:
				$DogSoundsPlayer.play()   #actually add that sound ok???
				return 6

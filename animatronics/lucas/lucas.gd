extends AnimatronicBase

export var window_circuit = "window_toggle"
export var office_door_circuit = "office_door_toggle"
export var office_vent_flash = "office_vent_flash_momentary"
export var camera_entrance = "camera.foyer"

var hunt_accumulation = 0.0
var hunt_target = null
var have_hunted = false

onready var night = $"/root/EventMan".night_index

onready var HUNT_TARGETS = [
	{"window": 1},
	{"window": 0.7, "door": 0.2, "vent": 0.1},
	{"window": 0.5, "door": 0.35, "vent": 0.15},
	{"window": 0.4, "door": 0.35, "vent": 0.25},
	{"window": 0.4, "door": 0.35, "vent": 0.25}
][night]

var ROOM_CANDIDATES = {
	0: [1],
	1: [0, 2, 7],
	2: [1, 3],
	3: [2, 4],
	4: [3, 5, 6],
	5: [4],
	6: [4, 7],
	7: [1, 6, 8],
	8: [7]
}

var HUNT_PATHS = {
	"window": {
		0: 1,
		1: 2,
		2: 3,
		3: 4,
		4: 9,
		5: 4,
		6: 4,
		7: 6,
		8: 7,
		9: 10,
	},
	"door": {
		0: 1,
		1: 13,
		2: 1,
		3: 2,
		4: 6,
		5: 4,
		6: 7,
		7: 13,
		8: 7
	},
	"vent": {
		0: 1,
		1: 2,
		2: 14,
		3: 2,
		4: 3,
		5: 4,
		6: 7,
		7: 8,
		8: 15,
		14: 16,
		15: 16
	}
}

func _ready():
	call_deferred("assume_state", 0)
	animation_player = get_node("lucas/AnimationPlayer")

	
func state_machine():
	animation_player = $lucas/AnimationPlayer
	if hunt_target == "window" and night == 0 and not have_hunted and state in [3,4,5,6]:
		have_hunted = true
		$"/root/EventMan".connect("off", self, "wait_for_camera_entrance")
		return 18
	if state in [2,8] and hunt_target == "vent" and EventMan.circuit("gabe.vent"):
		return state
	match state:
		9:
			play_approach_sound()
			
			return 10
		10:
			# animation_player.connect("animation_finished", self, "walked_up_to_window")
			# return 10
			$"/root/EventMan".connect("on", self, "attack_if_window_opens_circuit_handler")
			if EventMan.circuit(window_circuit):
				$"/root/EventMan".jumpscare("lucas", "window")
			return 11
		11:
			$"/root/EventMan".disconnect("on", self, "attack_if_window_opens_circuit_handler")
			animation_player.connect("animation_finished", self, "walked_away_from_window")
			play_depart_sound()
			return 12
		12:
			# return 12
			hunt_target = null
			hunt_accumulation = 0.0
			return go_back()
		13:
			if (office_door_circuit in $"/root/EventMan".circuit_states) and ($"/root/EventMan".circuit_states[office_door_circuit]):
				$"/root/EventMan".jumpscare("lucas", "door")
				return 0
			else:
				hunt_target = null
				hunt_accumulation = 0
				return go_back()
		16:
			$GunFumblePlayer2.play()
			$"/root/EventMan".connect("on", self, "vent_flashbang")
			return 17
		17:
			$"/root/EventMan".disconnect("on", self, "vent_flashbang")
			hunt_target = null
			hunt_accumulation = 0.0
			return go_back()
		18:
			return 18
	check_hunting()
	if hunt_target == null:
		return roll_wander()
	else:
		return hunt_path()
	
	
func go_back():
	if randf() <.4:
		return 0
	else:
		return int(round(rand_range(1,8)))
	
func check_hunting():
	if hunt_target == null:
		if randf() < hunt_accumulation:
			var hunt_target_number = randf()
			var accumulator = 0
			for key in HUNT_TARGETS.keys():
				if key == "vent" and "gabe.vent" in $"/root/EventMan".circuit_states and $"/root/EventMan".circuit_states["gabe.vent"]:
					continue
				if hunt_target_number < HUNT_TARGETS[key]+accumulator:
					hunt_target = key
					break
				else:
					accumulator += HUNT_TARGETS[key]
			print("Lucas begins hunting for ", hunt_target)
		else:
			hunt_accumulation += 0.01 * difficulty
func play_approach_sound():
	if 0 == floor(rand_range(0,1)):
		$approach1.play()
	else:
		$approach2.play()
func play_depart_sound():
	if 0 == floor(rand_range(0,1)):
		$depart1.play()
	else:
		$depart2.play()
		
func roll_wander():
	var possibilities = ROOM_CANDIDATES[state]
	var index = floor(rand_range(0, len(possibilities)))
	return possibilities[index]

func hunt_path():
	return HUNT_PATHS[hunt_target][state]

func attack_if_window_opens_circuit_handler(circuit: String):
	if circuit == window_circuit:
		$"/root/EventMan".jumpscare("lucas", "window")

func walked_up_to_window():
	#animation_player.disconnect("animation_finished", self, "walked_up_to_window")
	play_approach_sound()
	$"/root/EventMan".connect("on", self, "attack_if_window_opens_circuit_handler")
	assume_state(11)

func walked_away_from_window():
	#animation_player.disconnect("animation_finished", self, "walked_away_from_window")
	play_depart_sound()
	hunt_target = null
	hunt_accumulation = 0.0
	assume_state(0)

func vent_flashbang(circuit: String):
	if circuit == office_vent_flash:
		$"/root/EventMan".jumpscare("lucas", "vent")

func wait_for_camera_entrance(circuit: String):
	if circuit == camera_entrance:
		$"/root/EventMan".disconnect("off", self, "wait_for_camera_entrance")
		assume_state(9)

func difficulty_offset():
	var heat_increase = 0
	var noise_increase = 0
	if $"/root/EventMan".temperature >= 90:
		heat_increase = ($"/root/EventMan".temperature - 90) / 6
	if $"/root/EventMan".circuit("noisy") == true:
		noise_increase = 8
	#if the music playin do the thin
	return (heat_increase + noise_increase + 3)

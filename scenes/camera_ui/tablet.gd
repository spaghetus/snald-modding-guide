extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var interp_target = 1
var active = false
var suppress = false
var depleted = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = get_tree().get_root().connect("size_changed", self, "resize")
	_err = $"/root/EventMan".connect("jumpscare", self, "jumpscare")
	_err = $"/root/EventMan".connect("power_tick", self, "power_tick")
	_err = $"/root/EventMan".connect("push_camera_pad", self, "push_camera_pad")
	resize();
	anchor_top = interp_target
	anchor_bottom = interp_target
	anchor_right = 0
	pass # Replace with function body.
# Add the thing so the camera cannot be activated unless the player looks at the monitor
func _process(_delta):
	anchor_top = lerp(anchor_top, interp_target, 0.5)
	anchor_bottom = lerp(anchor_bottom, interp_target, 0.5)
	var mouse_pos = get_viewport().get_mouse_position()
	mouse_pos /= get_viewport().size
	if ((mouse_pos.y > 0.9 and mouse_pos.x > 0.3 and mouse_pos.x < 0.7) or Input.is_action_pressed("ui_down")) and not depleted and not CutsceneMan.player_cutscene_mode:
		if not suppress:
			suppress = true
			if active:
				down()
			else:
				up()
	else:
		suppress = false

func up():
	interp_target = 0
	active = true
	$"/root/EventMan".circuit_on("player_camera_pad")

func down():
	interp_target = 1
	active = false
	$"/root/EventMan".circuit_off("player_camera_pad")
	var focused = $TabletScreen/MapTexture/Viewport/Control.get_focus_owner()
	if focused != null:
		focused.release_focus()

func resize():
	margin_right = get_viewport_rect().size.x
	margin_bottom = get_viewport_rect().size.y

func jumpscare(_character, _scene):
	down()

func power_tick():
	if $"/root/EventMan".power <= 0 and not depleted:
		depleted = true
		down()
	if active == true:
		$"/root/EventMan".power -= .1

func push_camera_pad(up: bool):
	if up:
		up()
	else:
		down()

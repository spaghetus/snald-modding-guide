extends QodotEntity

var height = -INF
var starting_position = Vector3.ZERO
var open = false
var since_updated = 0.0
var open_time = 1.0
var easing = -2
var circuit = "default"
var depleted = false

func _ready():
	yield(get_parent(), "build_complete")
	starting_position = global_transform.origin
	var highest = -INF
	var lowest = INF
	for i in get_children():
		if i is CollisionShape and i.shape is ConvexPolygonShape:
			for p in i.shape.points:
				highest = max(p.y, highest)
				lowest = min(p.y, lowest)
	height = highest - lowest
	open_time = properties["open_time"] if "open_time" in properties else open_time
	easing = properties["easing"] if "easing" in properties else easing
	circuit = properties["circuit"] if "circuit" in properties else circuit
	$"/root/EventMan".connect("on", self, "on")
	$"/root/EventMan".connect("off", self, "off")
	$"/root/EventMan".connect("power_tick", self, "power_tick")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if height != -INF && since_updated < open_time:
		var power = ease(min(since_updated / open_time, 1), easing)
		var from = Vector3.UP * height * (0 if open else 1)
		var offset = Vector3.UP * height * (1 if open else -1) * power
		global_transform.origin = starting_position + from + offset
		since_updated += delta
	
func on(name: String):
	if name == circuit and not depleted:
		open = true
		since_updated = 0
func off(name: String):
	if name == circuit and not depleted:
		open = false
		since_updated = 0

func power_tick():
	if $"/root/EventMan".power <= 0:
		open = true
		since_updated = 0
		depleted = true
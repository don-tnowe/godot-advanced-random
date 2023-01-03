extends Label

@export var items_owned : Array[DynamicWheelItem] = []
@export var items_available : Array[DynamicWheelItem] = []

var current_options := [-1, -1, -1]
var rng := FortuneWheel.new()


func roll():
	var counts = FortuneWheel.count_tags_items(items_owned)
	text = ""
	for k in counts[1]:
		text += k.resource_path.get_file().get_basename() + ": x" + str(counts[1][k]) + "\n"
	
	text += "\n"
	for k in counts[0]:
		text += "#" + k + ": x" + str(counts[0][k]) + "\n"

	$"../Debug/Label".text = "\n\n".join(rng.get_dynamic_weights_debug(
		items_available,
		counts[0],
		counts[1]
	))
	current_options = rng.spin_dynamic_batch(items_available, items_owned, 3)
	$"../1".text = items_available[current_options[0]].resource_name
	$"../2".text = items_available[current_options[1]].resource_name
	$"../3".text = items_available[current_options[2]].resource_name


func _ready():
	roll()


func _on_3_pressed():
	var item = items_available[current_options[2]]
	items_owned.append(item)
	roll()


func _on_2_pressed():
	var item = items_available[current_options[1]]
	items_owned.append(item)
	roll()


func _on_1_pressed():
	var item = items_available[current_options[0]]
	items_owned.append(item)
	roll()


func _on_reset_pressed():
	text = ""
	items_owned.clear()
	roll()

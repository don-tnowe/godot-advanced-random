extends Label

export(Array, Resource) var items_owned := []
export(Array, Resource) var items_available := []

var current_options := [null, null, null]
var rng := FortuneWheel.new()


func roll():
	var counts = FortuneWheel.count_tags(items_owned)
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
	text += item.resource_name + "\n"
	roll()


func _on_2_pressed():
	var item = items_available[current_options[1]]
	items_owned.append(item)
	text += item.resource_name + "\n"
	roll()


func _on_1_pressed():
	var item = items_available[current_options[0]]
	items_owned.append(item)
	text += item.resource_name + "\n"
	roll()


func _on_reset_pressed():
	text = ""
	items_owned.clear()
	roll()

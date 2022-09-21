extends Control

export(Array, Texture) var symbol_textures := []
export(Array, String) var symbol_chars := []
export(Array, Resource) var dice := []

var symbol_nodes := []
var rng := DiceArray.new()

func _ready():
	var line_edit = $"Center/Grid/LineEdit"
	for i in 6:
		# Keep in mind any resources loaded from disk should be duplicated before they are edited.
		for j in 4:
			var new_node = line_edit.duplicate()
			$"Center/Grid".add_child(new_node)
			new_node.connect("text_changed", self, "_on_edit_cell", [j, i])
			new_node.text = dice[j].faces[i]

	for i in 4:
		dice[i] = dice[i].duplicate()

	line_edit.queue_free()
	
	for x in $"Dice".get_children():
		symbol_nodes.append(x.get_node("Die/CenterContainer/GridContainer").get_children())
		
	roll()


func _on_edit_cell(new_text : String, row : int, col : int):
	dice[row].faces[col] = new_text


func roll():
	rng.roll(dice)
	var result_arr = rng.get_rolled_faces()
	for i in dice.size():
		for j in symbol_nodes[i].size():
			symbol_nodes[i][j].visible = result_arr[i].size() > j
			if result_arr[i].size() > j:
				symbol_nodes[i][j].texture = symbol_textures[symbol_chars.find(result_arr[i][j])]

	# Another method is making one of a die's nodes visible.
	# Though you will still need to generate the symbols on each beforehand.
	# var result_arr = rng.get_rolled_face_indices()
	# for i in dice.size():
	# 	for j in face_nodes.size():
	# 		face_nodes[i].visible = result_arr[i] == i

	$"Sums".text =  (
		"C: " + str(rng.get_symbol_count("C"))
		+ "\nM: " + str(rng.get_symbol_count("M"))
		+ "\nY: " + str(rng.get_symbol_count("Y"))
	)

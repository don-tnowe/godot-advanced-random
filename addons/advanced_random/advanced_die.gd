tool
class_name AdvancedDie
extends Resource

export(String, MULTILINE) var description := """Standard D6 die.
For face values, you can use numbers (1, 85, 9.5)
or strings of characters/\"symbols\" (A, BBB, XXYY).
"""
export(Array, String) var faces := ["1", "2", "3", "4", "5", "6"] setget _set_faces
export var symbol_char_if_number := "" setget _set_symbol_char_if_number
export var use_numbers_as_symbols := false


func _set_symbol_char_if_number(v):
	symbol_char_if_number = v[0] if v != "" else ""


func _set_faces(v):
	faces = v
	for i in v.size():
		if v[i] == "Null":
			v[i] = str(i)


func _init(face_values : Array = ["1", "2", "3", "4", "5", "6"]):
	faces = face_values


func get_symbols_on_face(face_index : int) -> Array:
	if face_index >= faces.size():
		return []
	
	var string : String = faces[face_index]
	if !use_numbers_as_symbols && string.is_valid_float():
		var value_number = float(string)
		string = ""
		for x in int(value_number):
			string += symbol_char_if_number

	return string_to_char_array(string)


static func string_to_char_array(string : String) -> Array:
	var arr := []
	arr.resize(string.length())
	for i in string.length():
		arr[i] = string[i]

	return arr


func get_all_symbols() -> Array:
	var arr := []
	arr.resize(faces.size())
	for i in faces.size():
		arr[i] = get_symbols_on_face(i)

	return arr


func add_up_face_symbols(face_index : int, to_dict : Dictionary):
	add_up_symbols(faces[face_index], to_dict, symbol_char_if_number, use_numbers_as_symbols)


static func add_up_symbols(string : String, to_dict : Dictionary, symbol_char_if_number : String = " ", use_numbers_as_symbols : bool = false):
	if !use_numbers_as_symbols && string.is_valid_float():
		to_dict[symbol_char_if_number] = to_dict.get("", 0) + float(string)

	else:
		var symbol := ""
		for i in string.length():
			symbol = string[i]
			to_dict[symbol] = to_dict.get(symbol, 0) + 1

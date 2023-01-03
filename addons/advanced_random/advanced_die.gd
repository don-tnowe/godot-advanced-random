@tool
class_name AdvancedDie
extends Resource

## A set of values to use in a [DiceArray].
## This only stores data and has methods to access and format it - RNG not included.

## Symbol lists on faces can be, besides numbers and one-character symbol sequences, lists separated by this character.
const SYMBOL_DELIMITER = ";"

## Unused in code - use this to write notes on this for yourself.
@export_multiline var description := ""
## Values or symbols on faces. You can use integer numbers, sequences of letters, or semicolon [code];[/code]-separated words.
@export var faces : Array = ["1", "2", "3", "4", "5", "6"]:
	set(v):
		faces = v
		for i in v.size():
			if v[i] == "Null":
				v[i] = str(i)

## If not used, numbers get converted into strings of [member symbol_char_if_number], length equal to number.[br]
## "6" with [code]symbol_char_if_number = "X"[/code] becomes [code]["X", "X", "X", "X", "X", "X"][/code]. [br]
## If used, numbers are read as symbols: "8925" gets read as [code]["8", "9", "2", "5"][/code].
@export var use_numbers_as_symbols := false
## See [member use_numbers_as_symbols].
@export var symbol_char_if_number := "":
	set(v):
		symbol_char_if_number = v[0] if v != "" else ""

## Creates an AdvancedDie with initialized [member faces].
func _init(face_values : Array = ["1", "2", "3", "4", "5", "6"]):
	faces = face_values

## Returns an array containing all symbols on a face.
## "AAABBC" turns into ["A", "A", "A", "B", "B", "C"],
## "Red;Blue;Yellow" becomes ["Red", "Blue", "Yellow"],
## for numbers, see [member use_numbers_as_symbols].
func get_symbols_on_face(face_index : int) -> Array[String]:
	if face_index >= faces.size():
		return []
	
	var string : String = faces[face_index]
	if string.find(SYMBOL_DELIMITER) != -1:
		var string_split = string.split(SYMBOL_DELIMITER, false)
		return Array(string_split)

	if !use_numbers_as_symbols && string.is_valid_float():
		var value_number = float(string)
		string = ""
		for x in int(value_number):
			string += symbol_char_if_number

	return Array(string.split(""))

## Returns an array containing result of [method get_symbols_on_face] of each face.
func get_all_symbols() -> Array[Array]:
	var arr := []
	arr.resize(faces.size())
	for i in faces.size():
		arr[i] = get_symbols_on_face(i)

	return arr

## Tallies up all symbols into a dictionary.[br]
## [codeblock]
## var die = AdvancedDie.new(["XXXXYY"])
## var dict = {"X": 6, "Y": 1}
## die.add_up_face_symbols(0, dict)
## print(dict)  # Prints {"X": 10, "Y": 3}
## [/codeblock] [br]
## [b]Note:[/b] this method modifies the dictionary passed.
func add_up_face_symbols(face_index : int, to_dict : Dictionary):
	add_up_symbols(faces[face_index], to_dict, symbol_char_if_number, use_numbers_as_symbols)

## Static version of [method add_up_face_symbols]
static func add_up_symbols(string : String, to_dict : Dictionary, symbol_char_if_number : String = " ", use_numbers_as_symbols : bool = false):
	if !use_numbers_as_symbols && string.is_valid_float():
		to_dict[symbol_char_if_number] = to_dict.get(symbol_char_if_number, 0) + string.to_float()

	else:
		var symbols = string.split(SYMBOL_DELIMITER if string.find(SYMBOL_DELIMITER) != -1 else "")
		for x in symbols:
			to_dict[x] = to_dict.get(x, 0) + 1

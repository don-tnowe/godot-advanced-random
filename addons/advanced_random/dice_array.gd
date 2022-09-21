class_name DiceArray
extends Reference

var rng : RandomNumberGenerator

var _dice := []
var _dice_faces_rolled := []
var _dice_symbol_counts := {}

# Create a DiceArray object. Optionally, pass a RandomNumberGenerator - if not, new one is created.
# Set `dice` to configure which `AdvancedDie` are rolled at the start. You can reassign these later when calling `roll()`
func _init(random_number_generator : RandomNumberGenerator = null, dice : Array = []):
	rng = random_number_generator
	if !random_number_generator:
		rng = RandomNumberGenerator.new()
		rng.randomize()
		
	if dice.size() > 0:
		roll(dice)


func roll(dice : Array = []):
	if dice.size() > 0:
		_dice = dice
	
	_dice_symbol_counts.clear()
	_dice_faces_rolled.resize(_dice.size())
	for i in _dice.size():
		_dice_faces_rolled[i] = (rng.randi() if rng else randi()) % _dice[i].faces.size()
		_dice[i].add_up_face_symbols(_dice_faces_rolled[i], _dice_symbol_counts)


func get_symbol_counts() -> Dictionary:
	return _dice_symbol_counts.duplicate()


func get_symbol_count(of_symbol : String = "") -> int:
	return _dice_symbol_counts.get(of_symbol, 0)


func get_rolled_face_indices() -> Array:
	return _dice_faces_rolled.duplicate()
			

func get_rolled_faces() -> Array:
	var arr = []
	var face
	arr.resize(_dice.size())
	for i in _dice.size():
		face = _dice[i].faces[_dice_faces_rolled[i]]
		# if !_dice[i].use_numbers_as_symbols && face.is_valid_float():
		# 	arr[i] = float(face) 

		# else:
		arr[i] = _dice[i].get_symbols_on_face(_dice_faces_rolled[i])

	return arr			

class_name DiceArray
extends RefCounted

## Chucks a buch of dice and tallies up the numbers or symbols.

## The [RandomNumberGenerator] used to determine dropped values.
var rng : RandomNumberGenerator

var _dice := []
var _dice_faces_rolled := []
var _dice_symbol_counts := {}

## Create a DiceArray object. Optionally, pass a [RandomNumberGenerator] - if not, new one is created.[br]
## Set [code]dice[/code] to configure which [AdvancedDie] are rolled at the start. You can reassign these later when calling [method roll].
func _init(random_number_generator : RandomNumberGenerator = null, dice : Array = []):
	rng = random_number_generator
	if !random_number_generator:
		rng = RandomNumberGenerator.new()
		rng.randomize()
		
	if dice.size() > 0:
		roll(dice)

## Rolls the dice. Retrieve the results afterwards using other methods of the class.
func roll(dice : Array = []):
	if dice.size() > 0:
		_dice = dice
	
	_dice_symbol_counts.clear()
	_dice_faces_rolled.resize(_dice.size())
	for i in _dice.size():
		_dice_faces_rolled[i] = (rng.randi() if rng else randi()) % _dice[i].faces.size()
		_dice[i].add_up_face_symbols(_dice_faces_rolled[i], _dice_symbol_counts)

## Creates a Dictionary telling how many times each symbol was seen after a [method roll].
func get_symbol_counts() -> Dictionary:
	return _dice_symbol_counts.duplicate()


## Tells how many times a symbol was seen after a [method roll].
func get_symbol_count(of_symbol : String = "") -> int:
	return _dice_symbol_counts.get(of_symbol, 0)

## Tells which die faces were pointing upwards after a [method roll], by index.
func get_rolled_face_indices() -> Array[int]:
	return _dice_faces_rolled.duplicate()

## Tells which symbols were on each die's face after a [method roll].
func get_rolled_faces() -> Array[Array]:
	var arr = []
	var face
	arr.resize(_dice.size())
	for i in _dice.size():
		face = _dice[i].faces[_dice_faces_rolled[i]]
		arr[i] = _dice[i].get_symbols_on_face(_dice_faces_rolled[i])

	return arr

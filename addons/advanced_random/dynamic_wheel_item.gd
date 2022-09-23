tool
class_name DynamicWheelItem
extends Resource

export var max_duplicates := 0
export var tags := "tag_1 tag_2 tag_3" setget _set_tags
export var requires_one_of_tags := "" setget _set_requires_one_of_tags
export var tag_delimeter := " "
export(Array, String) var tags_array setget _set_tags_array
export(Array, String) var requires_one_of_tags_array setget _set_requires_one_of_tags_array
export var tag_all_copies := true
export var base_weight := 10.0
export(String, MULTILINE) var multiplier_per_tag := "" setget _set_multiplier_per_tag
export(String, MULTILINE) var multiplier_if_tag_present := "" setget _set_multiplier_if_tag_present
export(String, MULTILINE) var multiplier_if_tag_not_present := "" setget _set_multiplier_if_tag_not_present
export(String, MULTILINE) var max_tags_present := "" setget _set_max_tags_present
export(String, MULTILINE) var min_tags_present := "" setget _set_min_tags_present
export var list_item_delimeter := " " setget _set_list_item_delimeter
export var list_row_delimeter := ";" setget _set_list_row_delimeter

var _is_cached := false
var _tag_dict := {}
var _requires_one_of_tags_array := []
var _multiplier_per_tag_dict := {}
var _multiplier_if_tag_present_dict := {}
var _multiplier_if_tag_not_present_dict := {}
var _max_tags_present_dict := {}
var _min_tags_present_dict := {}


func _set_tags(v):
	tags = v
	_is_cached = false


func _set_requires_one_of_tags(v):
	requires_one_of_tags = v
	_is_cached = false


func _set_tags_array(v):
	tags_array = v
	_is_cached = false


func _set_requires_one_of_tags_array(v):
	requires_one_of_tags_array = v
	_is_cached = false

func _set_multiplier_per_tag(v):
	multiplier_per_tag = v
	_is_cached = false


func _set_multiplier_if_tag_present(v):
	multiplier_if_tag_present = v
	_is_cached = false


func _set_multiplier_if_tag_not_present(v):
	multiplier_if_tag_not_present = v
	_is_cached = false


func _set_max_tags_present(v):
	max_tags_present = v
	_is_cached = false


func _set_min_tags_present(v):
	min_tags_present = v
	_is_cached = false


func _set_list_item_delimeter(v):
	list_item_delimeter = v
	_is_cached = false


func _set_list_row_delimeter(v):
	list_row_delimeter = v
	_is_cached = false


func get_weight(owned_tags : Dictionary, owned_items : Dictionary = {}) -> float:
	if !_is_cached:
		_cache_lists()

	if !owned_one_of_tags(owned_tags, _requires_one_of_tags_array):
		return 0.0

	if owned_items.has(self):
		owned_tags = owned_tags.duplicate()
		for k in _tag_dict:
			if owned_tags.has(k):
				owned_tags[k] -= _tag_dict[k] * (owned_items[self] if tag_all_copies else 1)

	for k in _max_tags_present_dict:
		if owned_tags.get(k, 0) >= _max_tags_present_dict[k]:
			return 0.0

	for k in _min_tags_present_dict:
		if owned_tags.get(k, 0) < _min_tags_present_dict[k]:
			return 0.0
	var result_weight := base_weight
	for k in _multiplier_per_tag_dict:
		result_weight *= pow(_multiplier_per_tag_dict[k], owned_tags.get(k, 0))

	for k in _multiplier_if_tag_present_dict:
		if owned_tags.has(k):
			result_weight *= _multiplier_if_tag_present_dict[k]
	
	for k in _multiplier_if_tag_not_present_dict:
		if !owned_tags.has(k):
			result_weight *= _multiplier_if_tag_not_present_dict[k]

	return result_weight


func _cache_lists():
	_tag_dict.clear()
	var tag_array = tags.split(tag_delimeter) if tags != "" else []
	tag_array.append_array(tags_array)
	for x in tag_array:
		_tag_dict[x] = _tag_dict.get(x, 0) + 1

	_requires_one_of_tags_array = requires_one_of_tags.split(tag_delimeter) if requires_one_of_tags != "" else []
	_requires_one_of_tags_array.append_array(requires_one_of_tags_array)

	_multiplier_per_tag_dict.clear()
	_multiplier_if_tag_present_dict.clear()
	_multiplier_if_tag_not_present_dict.clear()
	_max_tags_present_dict.clear()

	_cache_text_into_dictionary(_multiplier_per_tag_dict, multiplier_per_tag)
	_cache_text_into_dictionary(_multiplier_if_tag_present_dict, multiplier_if_tag_present)
	_cache_text_into_dictionary(_multiplier_if_tag_not_present_dict, multiplier_if_tag_not_present)
	_cache_text_into_dictionary(_max_tags_present_dict, max_tags_present)
	_cache_text_into_dictionary(_min_tags_present_dict, min_tags_present)

	_is_cached = true


func _cache_text_into_dictionary(dict : Dictionary, list_string : String):
	for x in list_string.split(list_row_delimeter):
		if x == "": continue
	
		x = x.trim_prefix(" ")  # Because a space after semicolons/commas is common
		dict[x.left(x.find(list_item_delimeter))] = float(
			x.right(x.rfind(list_item_delimeter) + list_item_delimeter.length())
		)


func get_tag_dict(unsafe : bool = false) -> Dictionary:
	if !_is_cached:
		_cache_lists()
	
	return _tag_dict.duplicate() if !unsafe else _tag_dict



func get_weight_debug(owned_tags : Dictionary, owned_items : Dictionary) -> String:
	var beginning := resource_path.get_file() + " >>> "
	if !_is_cached:
		_cache_lists()
	
	if !owned_one_of_tags(owned_tags, _requires_one_of_tags_array):
		return beginning + "0\n    None of requires_one_of_tags owned."
	
	if owned_items.has(self):
		owned_tags = owned_tags.duplicate()
		for k in _tag_dict:
			if owned_tags.has(k):
				owned_tags[k] -= _tag_dict[k] * (owned_items[self] if tag_all_copies else 1)

	var result_text := ""
	for k in _max_tags_present_dict:
		result_text += "\n    Limit " + k + ": " + str(owned_tags.get(k, 0)) + "/" + str(_max_tags_present_dict[k])
		if owned_tags.get(k, 0) >= _max_tags_present_dict[k]:
			return beginning + result_text + " at limit: "

	for k in _min_tags_present_dict:
		result_text += "\n    Required " + k + ": " + str(owned_tags.get(k, 0)) + "/" + str(_min_tags_present_dict[k])
		if owned_tags.get(k, 0) < _min_tags_present_dict[k]:
			return beginning + result_text + " requirements not met"

	var result_weight := base_weight
	for k in _multiplier_per_tag_dict:
		result_text += "\n    Owned " + str(owned_tags.get(k, 0)) + " " + k + ": W x" + str(pow(_multiplier_per_tag_dict[k], owned_tags.get(k, 0)))
		result_weight *= pow(_multiplier_per_tag_dict[k], owned_tags.get(k, 0))

	for k in _multiplier_if_tag_present_dict:
		if owned_tags.has(k):
			result_text += "\n    Owned " + k + ": W x" + str(_multiplier_if_tag_present_dict[k])
			result_weight *= _multiplier_if_tag_present_dict[k]
	
	for k in _multiplier_if_tag_not_present_dict:
		if !owned_tags.has(k):
			result_text += "\n    Not owned " + k + ": W x" + str(_multiplier_if_tag_not_present_dict[k])
			result_weight *= _multiplier_if_tag_not_present_dict[k]
	
	assert(result_weight == get_weight(owned_tags), _get_debug_error_message(result_weight, owned_tags, result_text))
	return beginning + str(result_weight) + result_text
	

func _get_debug_error_message(result_weight, owned_tags, result_text):
	if result_weight == get_weight(owned_tags): return
	printerr("Debug weight does not correspond to non-debug calculations: " + resource_path.get_file() + "\n" + result_text)
	return (
		"Debug weight does not correspond to non-debug calculations.\nDebug W: "
		+ str(result_weight)
		+ "\nNon-debug W: " 
		+ str(get_weight(owned_tags))
	)
	


func owned_one_of_tags(owned_tags : Dictionary, search_tags : Array) -> bool:
	if search_tags.size() == 0:
		return true

	if !_is_cached:
		_cache_lists()
	
	for x in search_tags:
		if owned_tags.has(x):
			return true

	return false

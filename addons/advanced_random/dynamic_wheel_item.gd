@tool
class_name DynamicWheelItem
extends Resource

## A structure defining how a dictionary's values influence a number's drop chance on a [FortuneWheel].

## Use this in multiplier and increment dictionaries in place of a tag to base weight on count of duplicates.
const TAG_SELF := "@self"

## If this count is exceeded in the items-owned dictionary, this item can no longer drop.
@export var max_duplicates := 0
## The base weight, if no modifiers have been applied.
@export var base_weight := 10.0
## Tags to base other items' drop chances off of.
@export var tags : Array[String] = []:
	set(v):
		tags = v
		_is_cached = false
## If none of these is present, this item can not drop.
@export var requires_one_of_tags : Array[String] = []:
	set(v):
		requires_one_of_tags = v
		_is_cached = false

## If not set, only the first instance of the item in the dictionary will contribute to tag counts.
@export var tag_all_copies := true

@export_category("Calculations")
## Increment the weight [b]every time[/b] any of these tag if found, by that tag's increment set here.
@export_multiline var increment_per_tag := "":
	set(v):
		increment_per_tag = v
		_is_cached = false
## Multiply the weight [b]every time[/b] any of these tag if found, by that tag's coefficient set here.
@export_multiline var multiplier_per_tag := "":
	set(v):
		multiplier_per_tag = v
		_is_cached = false
## Multiply the weight once for each of these tags found, by the tag's coefficient set here.
## Set to 0 to block from dropping this item if a tag is present.
@export_multiline var multiplier_if_tag_present := "":
	set(v):
		multiplier_if_tag_present = v
		_is_cached = false
## Multiply the weight once for each of these tags found, by the tag's coefficient set here.[br]
## Set to 0 to block from dropping this item if a tag is not present.
@export_multiline var multiplier_if_tag_not_present := "":
	set(v):
		multiplier_if_tag_not_present = v
		_is_cached = false
## If a tag's count is not less than this, this item can't drop.
@export_multiline var max_tags_present := "":
	set(v):
		max_tags_present = v
		_is_cached = false
## If a tag's count is not higher than this, this item can't drop.
@export_multiline var min_tags_present := "":
	set(v):
		min_tags_present = v
		_is_cached = false

@export_category("Parsing")
## Put this in between the tag and the value of an entry. [br]
## Used by [b]Calculations[/b] above properties to parse a dictionary from the text. [br]
@export var list_key_value_delimiter := " ":
	set(v):
		list_key_value_delimiter = v
		_is_cached = false
## Put this in between entries of a list. [br]
## Used by [b]Calculations[/b] above properties to parse a dictionary from the text. [br]
@export var list_entry_delimiter := ";":
	set(v):
		list_entry_delimiter = v
		_is_cached = false

var _is_cached := false
var _tag_dict := {}
var _multiplier_per_tag_dict := {}
var _increment_per_tag_dict := {}
var _multiplier_if_tag_present_dict := {}
var _multiplier_if_tag_not_present_dict := {}
var _max_tags_present_dict := {}
var _min_tags_present_dict := {}

## Returns [member base_weight] augmented with consideration to [code]owned_tags[/code] and optionally [code]owned_items[/code].[br]
## Set [code]ignore_if_has_duplicates[/code] to ignore the tags from copies of this item.
func get_weight(owned_tags : Dictionary, owned_items : Dictionary = {}, ignore_if_has_duplicates : bool = false) -> float:
	if !_is_cached:
		_cache_lists()

	if !owned_one_of_tags(owned_tags, requires_one_of_tags):
		return 0.0

	if !ignore_if_has_duplicates && owned_items.has(self):
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

	if _multiplier_per_tag_dict.has(TAG_SELF):
		result_weight *= pow(_multiplier_per_tag_dict[TAG_SELF], owned_items.get(self, 0))
	
	for k in _multiplier_per_tag_dict:
		result_weight *= pow(_multiplier_per_tag_dict[k], owned_tags.get(k, 0))
	
	if _increment_per_tag_dict.has(TAG_SELF):
		result_weight *= 1.0 + _increment_per_tag_dict[TAG_SELF] * owned_items.get(self, 0)
	
	for k in _increment_per_tag_dict:
		result_weight *= 1.0 + _increment_per_tag_dict[k] * owned_tags.get(k, 0)
	
	for k in _multiplier_if_tag_present_dict:
		if (k == TAG_SELF && owned_items.has(self)) || owned_tags.has(k):
			result_weight *= _multiplier_if_tag_present_dict[k]
	
	for k in _multiplier_if_tag_not_present_dict:
		if (k == TAG_SELF && !owned_items.has(self)) || !owned_tags.has(k):
			result_weight *= _multiplier_if_tag_not_present_dict[k]

	return result_weight


func _cache_lists():
	_tag_dict.clear()
	for x in tags:
		_tag_dict[x] = _tag_dict.get(x, 0) + 1

	_multiplier_per_tag_dict.clear()
	_increment_per_tag_dict.clear()
	_multiplier_if_tag_present_dict.clear()
	_multiplier_if_tag_not_present_dict.clear()
	_max_tags_present_dict.clear()
	_min_tags_present_dict.clear()

	_cache_text_into_dictionary(_multiplier_per_tag_dict, multiplier_per_tag)
	_cache_text_into_dictionary(_increment_per_tag_dict, increment_per_tag)
	_cache_text_into_dictionary(_multiplier_if_tag_present_dict, multiplier_if_tag_present)
	_cache_text_into_dictionary(_multiplier_if_tag_not_present_dict, multiplier_if_tag_not_present)
	_cache_text_into_dictionary(_max_tags_present_dict, max_tags_present)
	_cache_text_into_dictionary(_min_tags_present_dict, min_tags_present)

	_is_cached = true


func _cache_text_into_dictionary(dict : Dictionary, list_string : String):
	for x in list_string.split(list_entry_delimiter):
		if x == "": continue
	
		x = x.trim_prefix(" ")  # Because a space after semicolons/commas is common
		dict[x.left(x.find(list_key_value_delimiter))] = (
			x.substr(x.rfind(list_key_value_delimiter) + list_key_value_delimiter.length())
		).to_float()

## Returns the item's tags as a Dictionary. [br]
## If [code]unsafe[/code] set, slightly faster, but may unexpectedly modify item's data.
func get_tag_dict(unsafe : bool = false) -> Dictionary:
	if !_is_cached:
		_cache_lists()
	
	return _tag_dict.duplicate() if !unsafe else _tag_dict


func get_weight_debug(owned_tags : Dictionary, owned_items : Dictionary) -> String:
	var beginning := resource_path.get_file() + " >>> "
	if !_is_cached:
		_cache_lists()
	
	if !owned_one_of_tags(owned_tags, requires_one_of_tags):
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
	
	if _multiplier_per_tag_dict.has(TAG_SELF):
		result_text += "\n    Already owned " + str(owned_items.get(self, 0)) + " copies: x" + str(_multiplier_per_tag_dict[TAG_SELF], owned_items.get(self, 0))
		result_weight *= pow(_multiplier_per_tag_dict[TAG_SELF], owned_items.get(self, 0))

	for k in _multiplier_per_tag_dict:
		result_text += "\n    Owned " + str(owned_tags.get(k, 0)) + " " + k + ": W x" + str(pow(_multiplier_per_tag_dict[k], owned_tags.get(k, 0)))
		result_weight *= pow(_multiplier_per_tag_dict[k], owned_tags.get(k, 0))

	if _increment_per_tag_dict.has(TAG_SELF):
		result_text += "\n    Already owned " + str(owned_items.get(self, 0)) + " copies: x" + str(1.0 + _increment_per_tag_dict[TAG_SELF] * owned_items.get(self, 0))
		result_weight *= 1.0 + _increment_per_tag_dict[TAG_SELF] * owned_items.get(self, 0)
	
	for k in _increment_per_tag_dict:
		result_text += "\n    Owned " + str(owned_tags.get(k, 0)) + " " + k + ": W x" + str(1.0 + _increment_per_tag_dict[k] * owned_tags.get(k, 0))
		result_weight *= 1.0 + _increment_per_tag_dict[k] * owned_tags.get(k, 0)
	

	for k in _multiplier_if_tag_present_dict:
		if (k == TAG_SELF && owned_items.has(self)) || owned_tags.has(k):
			result_text += "\n    Owned " + k + ": W x" + str(_multiplier_if_tag_present_dict[k])
			result_weight *= _multiplier_if_tag_present_dict[k]
	
	for k in _multiplier_if_tag_not_present_dict:
		if (k == TAG_SELF && !owned_items.has(self)) || !owned_tags.has(k):
			result_text += "\n    Not owned " + k + ": W x" + str(_multiplier_if_tag_not_present_dict[k])
			result_weight *= _multiplier_if_tag_not_present_dict[k]

	# Broken in 4.0: can't use runtime-generated messages
#	assert(result_weight == get_weight(owned_tags, owned_items, true), _get_debug_error_message(result_weight, owned_tags, owned_items, result_text))
	assert(result_weight == get_weight(owned_tags, owned_items, true), "Debug weight does not correspond to non-debug calculations.")
	return beginning + str(result_weight) + result_text


func _get_debug_error_message(result_weight, owned_tags, owned_items, result_text):
	var nd_weight := get_weight(owned_tags, owned_items, true)
	if result_weight == nd_weight: return
	printerr(
		"Debug weight does not correspond to non-debug calculations: " + resource_path.get_file()
		+ "\n" + result_text + "\n" + str(result_weight) + "\n" + str(nd_weight)
	)
	return (
		"Debug weight does not correspond to non-debug calculations.\nDebug W: "
		+ str(result_weight)
		+ "\nNon-debug W: " 
		+ str(nd_weight)
	)

## Returns [code]true[/code] if any of [code]search_tags[/code] is a key is [code]owned_tags[/code].
static func owned_one_of_tags(owned_tags : Dictionary, search_tags : Array) -> bool:
	if search_tags.size() == 0:
		return true

	for x in search_tags:
		if owned_tags.has(x):
			return true

	return false

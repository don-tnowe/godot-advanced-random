class_name FortuneWheel
extends RefCounted

## A class to perform weighted random number generation. Has methods for simple weighted RNG,
## as well as conditional weights using [DynamicWheelItem]s.

## The [RandomNumberGenerator] used by this Wheel to determine dropped values.
var rng : RandomNumberGenerator

## Create a FortuneWheel object.[br]
## Optionally, pass a RandomNumberGenerator - if not, new one is created.
func _init(random_number_generator : RandomNumberGenerator = null):
	rng = random_number_generator
	if random_number_generator == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

## A weighted randomness function that takes an array of weights. Bigger weights drop more frequently.[br]
## [b]Returns:[/b] indices of results in an array, count determined by [code]count[/code].
func spin_batch(weights : Array, count : int = 1) -> Array:
	if count == 1:
		return [spin(weights)]

	var weight_sum := 0.0
	for x in weights:
		weight_sum += x

	assert(weight_sum > 0.0, "No elements in array have a weight")

	var random_pos = rng.randf() * weight_sum
	var results = []
	weights = weights.duplicate()
	while results.size() < count:
		for i in weights.size():
			if random_pos < weights[i]:
				# Don't repeat items in multi-pulls.
				weight_sum -= weights[i]
				weights[i] = 0

				results.append(i)
				random_pos = rng.randf() * weight_sum
				break
		
			random_pos -= weights[i]

		if weight_sum <= 0.0:
			results.append(0)
		
	return results

## A weighted randomness function that takes an array of weights. Bigger weights drop more frequently.[br]
## [b]Returns:[/b] Index of result.
func spin(weights : Array) -> int:
	var weight_sum := 0.0
	for x in weights:
		weight_sum += x

	assert(weight_sum > 0.0, "No elements in array have a weight")

	var random_pos = (randf() if !rng else rng.randf()) * weight_sum
	for i in weights.size():
		if random_pos < weights[i]:
			return i
		
		random_pos -= weights[i]
	
	return -1

## A weighted randomness function that takes an [code]item_pool[/code] of [DynamicWheelItem]s that have their weights based on items in `items_owned`.[br]
## You can provide [code]precalculated_counts[/code] from calling [method count_tags_items] and modifying the dictionaries.[br]
## [b]Returns:[/b] Position of the result inside [code]item_pool[/code].
func spin_dynamic(item_pool : Array[DynamicWheelItem], items_owned : Array[DynamicWheelItem], precalculated_counts : Array = []) -> int:
	if precalculated_counts.size() == 0:
		precalculated_counts = count_tags_items(items_owned)

	var weights := get_dynamic_weights(item_pool, precalculated_counts[0], precalculated_counts[1])
	return spin(weights)

## A variation of [method spin_dynamic]` that returns multiple values. Items in resulting array do not repeat.[br]
## You can provide [code]precalculated_counts[/code] from calling [method count_tags_items].
func spin_dynamic_batch(item_pool : Array, items_owned : Array, count : int = 1, precalculated_counts : Array = []) -> Array:
	if precalculated_counts.size() == 0:
		precalculated_counts = count_tags_items(items_owned)

	var weights := get_dynamic_weights(item_pool, precalculated_counts[0], precalculated_counts[1])
	if count == 1:
		return [spin(weights)]

	return spin_batch(weights, count)

## Counts tags and items in a [DynamicWheelItem] collection, returning an array of tag count and item count.[br]
## Optionally, pass items to ignore - comparison is done by their [member Resource.resource_path].[br]
## You can provide `precalculated_counts` from another call of this to tally up from multiple item pools.[br]
## Items without [member DynamicWheelItem.tag_all_copies] set will be only counted ONCE.
static func count_tags_items(items : Array[DynamicWheelItem], ignore_items : Array = [], precalculated_counts : Array = [{}, {}]) -> Array:
	var tags_found : Dictionary = precalculated_counts[0]
	var items_found : Dictionary = precalculated_counts[1]
	var cur_item_tag_dict : Dictionary
	for x in items:
		if _array_has_object(ignore_items, x):
			continue
		
		items_found[x] = items_found.get(x, 0) + 1
		if !x.tag_all_copies && items_found[x] > 1:
			continue
		
		cur_item_tag_dict = x.get_tag_dict(true)
		for k in cur_item_tag_dict:
			tags_found[k] = tags_found.get(k, 0) + cur_item_tag_dict[k]

	return [tags_found, items_found]

## Calculates weights of a [DynamicWheelItem] collection. Use with [method spin] and [method spin_batch].
static func get_dynamic_weights(item_pool : Array[DynamicWheelItem], owned_tags : Dictionary, owned_items : Dictionary = {}) -> Array:
	var result := []
	var item
	result.resize(item_pool.size())
	for i in item_pool.size():
		item = item_pool[i]
		if item.max_duplicates >= 0 && owned_items.get(item, 0) >= item.max_duplicates:
			result[i] = 0.0

		else:
			result[i] = item.get_weight(owned_tags, owned_items)

	return result

## Calculates weights of a [DynamicWheelItem] collection and returns a multiline string with the calculation breakdown.
static func get_dynamic_weights_debug(item_pool : Array, owned_tags : Dictionary, owned_items : Dictionary = {}) -> Array:
	var result := []
	var item
	result.resize(item_pool.size())
	for i in item_pool.size():
		item = item_pool[i]
		if item.max_duplicates >= 0 && owned_items.get(item, 0) >= item.max_duplicates:
			result[i] = item_pool[i].resource_path.get_file() + "\n    Count at max!"

		else:
			result[i] = item.get_weight_debug(owned_tags, owned_items)

	return result


static func _array_has_object(array : Array, obj : Object) -> bool:
	for x in array:
		if x == obj:
			return true

	return false

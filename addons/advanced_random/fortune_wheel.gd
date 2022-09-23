class_name FortuneWheel
extends Reference

var rng : RandomNumberGenerator

# Create a FortuneWheel object. Optionally, pass a RandomNumberGenerator - if not, new one is created.
func _init(random_number_generator : RandomNumberGenerator = null):
	rng = random_number_generator
	if random_number_generator == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

# A weighted randomness function that takes an array of weights. Bigger weights drop more frequently.
# Returns: indices of results in an array.
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

# A weighted randomness function that takes an array of weights. Bigger weights drop more frequently.
# Returns: Index of result.
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

# A weighted randomness function that takes an `item_pool` of `DynamicWheelItem`s that have their weights based on items in `items_owned`. 
# Returns: Position of the result inside `item_pool`.
func spin_dynamic(item_pool : Array, items_owned : Array) -> int:
	var counts := count_tags(items_owned)
	var weights := get_dynamic_weights(item_pool, counts[0], counts[1])
	return spin(weights)

# A variation of `spin_dynamic` that returns multiple values. items in resulting array do not repeat.
func spin_dynamic_batch(item_pool : Array, items_owned : Array, count : int = 1) -> Array:
	var counts := count_tags(items_owned)
	var weights := get_dynamic_weights(item_pool, counts[0], counts[1])
	if count == 1:
		return [spin(weights)]
	
	return spin_batch(weights, count)

# Counts tags in a `DynamicWheelItem` collection, returning an array of tag count and item count.
# Optionally, pass items to ignore - comparison is done by their `resource_path`.
# Items without `tag_all_copies` set will be only counted ONCE.
static func count_tags(items : Array, ignore_items : Array = []) -> Array:
	var dict := {}
	var items_found := {}
	var tag_dict : Dictionary
	for x in items:
		if array_has_resource_with_path(ignore_items, x.resource_path):
			continue
		
		items_found[x] = items_found.get(x, 0) + 1
		if !x.tag_all_copies && items_found[x] > 1:
			continue
		
		tag_dict = x.get_tag_dict(true)
		for k in tag_dict:
			dict[k] = dict.get(k, 0) + tag_dict[k]

	return [dict, items_found]

# Calculates weights of a `DynamicWheelItem` collection. Use with `spin()` and `spin_batch()`.
static func get_dynamic_weights(item_pool : Array, owned_tags : Dictionary, owned_items : Dictionary = {}) -> Array:
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

# Calculates weights of a `DynamicWheelItem` collection and returns a multiline string with the calculation breakdown.
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


static func array_has_resource_with_path(array : Array, name : String) -> bool:
	for x in array:
		if x.resource_path == name:
			return true

	return false

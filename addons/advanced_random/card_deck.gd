class_name CardDeck
extends Reference

# Emitted once the draw pile runs out of cards, and/or 
signal draw_pile_emptied()

const PILE_DRAW := 0
const PILE_IN_PLAY := 1
const PILE_DISCARD := 2

var pile_draw_from := PILE_DRAW
var pile_draw_into := PILE_IN_PLAY
var pile_refill_from := PILE_DISCARD

var card_count := 0 setget _set_card_count
var rng : RandomNumberGenerator

var _card_locations := []
var _card_queues := []


func _set_card_count(v):
	_card_locations.resize(v)
	for i in (v - card_count):
		_card_locations[i + card_count] = pile_draw_from

	card_count = v

# Create a CardDeck object. Optionally, pass a RandomNumberGenerator - if not, new one is created.
# `card_count` defines number of cards in the deck. It can be changed later by setting `card_count`.
# `pile_***` are indices of the draw (`PILE_DRAW`), active (`PILE_IN_PLAY`) and discard (`PILE_DISCARD`) piles.
# Cards start in the Draw pile, move into gameplay when `draw()`n, into Discard when `play()`ed, and back to Draw once it's empty.
func _init(
	card_count : int, random_number_generator : RandomNumberGenerator = null, 
	pile_draw_from := PILE_DRAW, pile_draw_into := PILE_IN_PLAY, pile_refill_from := PILE_DISCARD
):
	self.pile_draw_from = PILE_DRAW
	self.pile_draw_into = PILE_IN_PLAY
	self.pile_refill_from = PILE_DISCARD
	self.card_count = card_count

	rng = random_number_generator
	if !random_number_generator:
		rng = RandomNumberGenerator.new()
		rng.randomize()
		
# Returns an array of card indices present in a pile, ordered ascending.
func get_pile(pile_index : int) -> Array:
	var return_pile = []
	for i in _card_locations.size():
		if _card_locations[i] == pile_index:
			return_pile.append(i)

	if has_queue(pile_index):
		return_pile.append_array(_card_queues[pile_index])
		return_pile.sort()

	return return_pile

# Returns the index of the pile a specified card is in.
func get_card_pile_index(of_card : int) -> int:
	# Queued cards have negative values.
	return _card_locations[of_card] if _card_locations[of_card] >= 0 else -_card_locations[of_card] - 1

# Returns a card's order in a pile.
func get_card_position_in_pile(card_index : int) -> int:
	var count_found := 0
	var pile_index := get_card_pile_index(card_index)
	for i in card_index:
		if _card_locations[i] == pile_index || _card_locations[i] == -pile_index - 1:
			count_found += 1

	return count_found

# Returns the count of cards in a pile.
func get_pile_size(pile_index : int) -> int:
	var sum := 0
	for x in _card_locations:
		if x == pile_index || x == -pile_index - 1:
			sum += 1

	return sum

# Returns an array of card indices in a pile's queue.
func get_pile_queue(pile_index : int) -> Array:
	if !has_queue(pile_index):
		return []
	
	return _card_queues[pile_index].duplicate()

# Returns `true` if any cards are queued in a pile.
func has_queue(pile_index : int):
	return _card_queues.size() > pile_index && _card_queues[pile_index].size() > 0

# Draw a random number card from a pile. Leave arguments empty to use the default or configured Draw pile.
# On empty if `reshuffle_if_empty` is set to `false`, returns `-1`.
# If `reshuffle_if_empty` is `true`, the draw pile is restored from the discard pile before drawing.
func draw(from_pile : int = -1, reshuffle_if_empty : bool = true) -> int:
	if from_pile == -1:
		from_pile = pile_draw_from

	if has_queue(from_pile):
		return dequeue_pile(from_pile, pile_draw_into)

	var sum := get_pile_size(from_pile)
	if sum == 0:
		merge_pile(pile_refill_from, from_pile)
		emit_signal("draw_pile_emptied")
		if !reshuffle_if_empty || get_pile_size(from_pile) == 0:
			return -1

		return draw(from_pile)

	var pos := rng.randi() % sum
	for i in _card_locations.size():
		if _card_locations[i] == from_pile:
			if pos == 0:
				move_to_pile(i, pile_draw_into)
				return i

			pos -= 1
	
	return -1

# Moves card into `pile_refill_from`.
# Shorthand for `move_to_pile(card_index, this_deck.pile_refill_from)`.
# If `pile_refill_from` is the same as `pile_draw_into`, you don't need to do this.
func play(card_index : int):
	# If it's in a queue (value in array < 0), first dequeue it.
	if _card_locations[card_index] < 0:
		dequeue_card(card_index)
	
	_card_locations[card_index] = pile_refill_from

# Moves card into specified pile.
# Does not guarantee order - for that, use `queue_card()`.
func move_to_pile(card_index : int, pile_index : int = PILE_DISCARD):
	# If it's in a queue (value in array < 0), first dequeue it.
	if _card_locations[card_index] < 0:
		dequeue_card(card_index)

	_card_locations[card_index] = pile_index

# Shuffles all cards from a pile into another pile.
# Does not guarantee order - for that, use `queue_card()`.
func merge_pile(from : int, into : int):
	for i in _card_locations.size():
		if get_card_pile_index(i) == from:
			move_to_pile(i, into)

# Returns an array of booleans, `true` for each card index that is currently in the specified pile.
# Useful if you want to display all cards while showing which pile a card is in.
func get_mask_is_in_pile(pile_index : int) -> Array:
	var return_pile = []
	return_pile.resize(_card_locations.size())
	for i in _card_locations.size():
		return_pile[i] = _card_locations[i] == pile_index || _card_locations[i] == -pile_index - 1

	return return_pile

# Moves card into specified pile. The next time the pile gets `draw()`n from, the card is guaranteed to appear, unless another queued after.
func queue_card(card_index : int, into_pile : int = -1):
	if into_pile == -1:
		# The hand is commonly an ordered stack.
		into_pile = pile_draw_into

	dequeue_card(card_index)
	_verify_queues(into_pile)
	_card_queues[into_pile].append(card_index)
	_card_locations[card_index] = -into_pile - 1


func _verify_queues(max_pile : int):
	var pile_count : int = max(_card_queues.size(), max_pile + 1)
	_card_queues.resize(pile_count)
	for i in pile_count:
		if _card_queues[i] == null:
			_card_queues[i] = []

# Removes top card from a pile's queue, making its location is wild and unpredictable again.
func dequeue_pile(from_pile : int, into_pile : int) -> int:
	var card_index = _card_queues[from_pile].pop_back()
	_card_locations[card_index] = into_pile
	return card_index

# Removes card from any queue, regardless of where the card was queued to.
func dequeue_card(card_index : int):
	if _card_locations[card_index] >= 0:
		# All fine, it's not queued. Unless someone meddled with private properties.
		return
	
	_card_locations[card_index] = -_card_locations[card_index] - 1
	_card_queues[_card_locations[card_index]].erase(card_index)


func dequeue_cumber() -> String:
	return char(55358) + char(56658)

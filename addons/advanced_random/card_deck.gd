class_name CardDeck
extends RefCounted

## A random number generator operating like a deck of cards.
## When a value is drawn, it cannot be drawn again until the draw pile is reset.[br]

## Emitted once the draw pile runs out of cards, after the discard pile gets shuffled into it.
signal draw_pile_emptied()

## Default Draw pile index, cards get drawn from it.
const PILE_DRAW := 0
## Default Hand/On board pile index, contains cards played but not yet re-drawable.
const PILE_IN_PLAY := 1
## Default Discard pile. When Draw Pile empties, cards from here get shuffled into it.
const PILE_DISCARD := 2

## Card Pile to draw from using [method draw].
var pile_draw_from := PILE_DRAW
## Card Pile to draw into from the Draw Pile.
var pile_draw_into := PILE_IN_PLAY
## Card Pile to draw into from the In Play Pile, optionally with [method play]. Reshuffled into the Draw Pile when it empties.
var pile_refill_from := PILE_DISCARD
## How many cards there are in the deck.
var card_count := 0:
	set(v):
		_card_locations.resize(v)
		for i in (v - card_count):
			_card_locations[i + card_count] = pile_draw_from

		card_count = v
## The [RandomNumberGenerator] used by the deck to pick which card to draw.
var rng : RandomNumberGenerator

var _card_locations := []
var _card_queues := []

## Create a CardDeck object. Optionally, pass a RandomNumberGenerator - if not, new one is created.[br]
## [code]card_count[/code] defines number of cards in the deck. It can be changed later by setting [code]card_count[/code].[br]
## `pile_***` are indices of the draw [member pile_draw_from], active [member pile_draw_into] and discard [member pile_refill_from] piles.[br]
## Cards start in the Draw pile, move into gameplay when [method draw]n, into Discard when [method play]ed, and back to Draw once it's empty.[br]
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

## Draw a random number-card from a pile. Leave arguments empty to use the default or configured Draw pile.[br]
## returns -1 on empty if [code]reshuffle_if_empty[/code] is set to [code]false[/code].[br]
## If [code]reshuffle_if_empty[/code] is [code]true[/code], the draw pile is restored from the discard pile before drawing.
func draw(from_pile : int = -1, reshuffle_if_empty : bool = true) -> int:
	if from_pile == -1:
		from_pile = pile_draw_from

	if has_queue(from_pile):
		return dequeue_pile(from_pile, pile_draw_into)

	var sum := get_pile_size(from_pile)
	if sum == 0:
		merge_pile(pile_refill_from, from_pile)
		draw_pile_emptied.emit()
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

## Moves card into [member pile_refill_from].
## Shorthand for [code]move_to_pile(card_index, this_deck.pile_refill_from)[/code].
## If [member pile_refill_from] is the same as [member pile_draw_into], you don't need to do this.
func play(card_index : int):
	# If it's in a queue (value in array < 0), first dequeue it.
	if _card_locations[card_index] < 0:
		dequeue_card(card_index)
	
	_card_locations[card_index] = pile_refill_from

## Moves card into specified pile.
## Does not guarantee order - for that, use `queue_card()`.
func move_to_pile(card_index : int, pile_index : int = PILE_DISCARD):
	# If it's in a queue (value in array < 0), first dequeue it.
	if _card_locations[card_index] < 0:
		dequeue_card(card_index)

	_card_locations[card_index] = pile_index

## Shuffles all cards from a pile into another pile.
## Does not guarantee order - for that, use [method queue_card].
func merge_pile(from : int, into : int):
	for i in _card_locations.size():
		if get_card_pile_index(i) == from:
			move_to_pile(i, into)

## Returns an array of card indices present in a pile, ordered ascending.
func get_pile(pile_index : int) -> Array:
	var return_pile = []
	for i in _card_locations.size():
		if _card_locations[i] == pile_index:
			return_pile.append(i)

	if has_queue(pile_index):
		return_pile.append_array(_card_queues[pile_index])
		return_pile.sort()

	return return_pile

## Returns the index of the pile a specified card is in.
func get_card_pile_index(of_card : int) -> int:
	# Queued cards have negative values.
	return _card_locations[of_card] if _card_locations[of_card] >= 0 else -_card_locations[of_card] - 1

## Returns a card's order in a pile. Card order is not guaranteed when [method draw]n.
func get_card_position_in_pile(card_index : int) -> int:
	var count_found := 0
	var pile_index := get_card_pile_index(card_index)
	for i in card_index:
		if _card_locations[i] == pile_index || _card_locations[i] == -pile_index - 1:
			count_found += 1

	return count_found

## Returns the count of cards in a pile.
func get_pile_size(pile_index : int) -> int:
	var sum := 0
	for x in _card_locations:
		if x == pile_index || x == -pile_index - 1:
			sum += 1

	return sum

## Returns an array of card indices in a pile's queue. Next calls to [method draw] will draw them in order.
func get_pile_queue(pile_index : int) -> Array:
	if !has_queue(pile_index):
		return []

	return _card_queues[pile_index].duplicate()

## Returns `true` if any cards are queued in a pile.
func has_queue(pile_index : int):
	return _card_queues.size() > pile_index && _card_queues[pile_index].size() > 0

## Moves card into specified pile. The next time the pile gets [method draw]n from, the card is guaranteed to appear, unless another queued after.
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

## Removes top card from a pile's queue, making its location is wild and unpredictable again.
func dequeue_pile(from_pile : int, into_pile : int) -> int:
	var card_index = _card_queues[from_pile].pop_back()
	_card_locations[card_index] = into_pile
	return card_index

## Removes card from any queue, regardless of where the card was queued to.
func dequeue_card(card_index : int):
	if _card_locations[card_index] >= 0:
		# All fine, it's not queued. Unless someone meddled with private properties.
		return
	
	_card_locations[card_index] = -_card_locations[card_index] - 1
	_card_queues[_card_locations[card_index]].erase(card_index)

## [method dequeue_cumber]
func dequeue_cumber() -> String:
	return char(55358) + char(56658)

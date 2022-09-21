extends Control

export var card_count := 24
export var card_in_pile_separation := 24.0

onready var original_card := $"Cards".get_child(0)

var deck : CardDeck

var _card_nodes := []

func _ready():
	_card_nodes = []
	original_card.get_parent().remove_child(original_card)
	for i in card_count:
		create_card_node(get_color_from_index(i) * 3.0)

	deck = CardDeck.new(card_count)
	# Just card_count is cool, but you can also pass more parameters.
	# deck = CardDeck.new(
	# 	card_count, RandomNumberGenerator.new(),
	# 	CardDeck.PILE_DRAW, CardDeck.PILE_IN_PLAY, CardDeck.PILE_DISCARD
	# 	)
	deck.connect("draw_pile_emptied", self, "_on_draw_pile_emptied")
	update_card_view()


func create_card_node(color) -> Node:
	var new_node = original_card.duplicate()
	$"Cards".add_child(new_node)
	_card_nodes.append(new_node)
	new_node.self_modulate = color
	new_node.get_node("ActualPressableButton").connect("pressed", self, "_on_card_pressed", [new_node.get_position_in_parent()])
	new_node.get_node("Label").text = str(new_node.get_position_in_parent())
	return new_node


func get_color_from_index(i : int, full_hue_count : int = 6) -> Color:
	return Color().from_hsv(
		float(i) / card_count,
		min(float(i % (card_count / full_hue_count) + 1) / full_hue_count * 1.75, 0.75),
		min(float(full_hue_count - i % (card_count / full_hue_count)) / full_hue_count * 1.25, 1.0)
	)


func update_card_view():
	for i in card_count:
		if deck.get_card_pile_index(i) == CardDeck.PILE_DRAW:
			_card_nodes[i].rect_global_position = (
				$"PileDraw".rect_global_position
				+ Vector2(0, deck.get_card_position_in_pile(i) * card_in_pile_separation)
			)
			_card_nodes[i].raise()

		elif deck.get_card_pile_index(i) == CardDeck.PILE_DISCARD:
			_card_nodes[i].rect_global_position = (
				$"PileDiscard".rect_global_position
				+ Vector2(0, deck.get_card_position_in_pile(i) * card_in_pile_separation)
			)
			_card_nodes[i].raise()

		# Hand card handling is different. We need to consider the order cards were drawn!
		#
		# elif deck.get_card_pile_index(i) == CardDeck.PILE_IN_PLAY:
		# 	_card_nodes[i].rect_global_position = (
		# 		$"Hand".rect_global_position
		# 		+ Vector2(
		# 			deck.get_card_position_in_pile(i) * card_in_pile_separation
		# 			- deck.get_pile_size(CardDeck.PILE_IN_PLAY) * card_in_pile_separation * 0.5, 0
		# 		)
		# 	)

	# If you put cards into a queue, they will stay in the order they were added in!
	# Of course you need to add them first. Or you could track order yourself. Or use the commented display code above.
	#
	var queue := deck.get_pile_queue(CardDeck.PILE_IN_PLAY)
	for i in queue.size():
		var node = _card_nodes[queue[i]]
		node.rect_global_position = (
			$"Hand".rect_global_position
			+ Vector2(
				i * card_in_pile_separation
				- queue.size() * card_in_pile_separation * 0.5, 0
			)
		)
		node.raise()


func _on_Draw_pressed():
	var drawn_card_index = deck.draw()
	if drawn_card_index == -1:
		# Draw pile can become empty if your Hand is not limited - handle that.
		return

	var drawn_card_node = _card_nodes[drawn_card_index]
	# Do whatever with drawn_card_node and drawn_card_index
	
	# Add cards to the pile's queue so order is guaranteed.
	deck.queue_card(drawn_card_index)
	update_card_view()


# Method is called when clicking a card.
# Don't forget to connect the signal, especially if the card is created from code.
func _on_card_pressed(card_index : int):
	if deck.get_card_pile_index(card_index) != CardDeck.PILE_IN_PLAY:
		# If the card's not in the hand, you can't do anything with it.
		return
	
	if !$"CheckBox".pressed:
		# Here goes whatever you're supposed to do with the card when you play it.
		var node = _card_nodes[card_index]
		$"Label2".text = "Card played!!! " + str(card_index) + " And its color is:::::" + str(node.self_modulate)
		# End of whatever block

		deck.play(card_index)

	else:
		deck.queue_card(card_index, deck.pile_draw_from)
		_card_nodes[card_index].raise()

	update_card_view()


func _on_draw_pile_emptied():
	# Play the "Shuffle" animation.
	$"AnimationPlayer".seek(0)
	$"AnimationPlayer".play("Reshuffle")
	# Animation calls update_card_view().

# You can add cards to the CardDeck. As many cards as you like.
# (Just don't use the same CardDeck instance for the whole game session - they're not removed automatically.)
func add_card():
	deck.card_count += 1
	card_count += 1
	create_card_node(Color.white * randf() * 3)
	update_card_view()


func _on_Create_pressed():
	add_card()

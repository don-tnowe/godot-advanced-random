extends Control



func _on_Button3_pressed():
	get_tree().change_scene("res://example/dice_array/dice.tscn")


func _on_Button2_pressed():
	get_tree().change_scene("res://example/card_deck/cards.tscn")


func _on_Button_pressed():
	get_tree().change_scene("res://example/dynamic_wheel/upgrades.tscn")


func _on_Button4_pressed():
	get_tree().change_scene("res://example/fairng/fairng_test.tscn")

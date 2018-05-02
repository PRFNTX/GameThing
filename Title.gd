extends Node2D

onready var globals = get_node("/root/master")

func _ready():
	for deck in globals.deck_list.keys():
		$decks.add_item(deck)

func _on_game_pressed():
	globals.set_scene('browse_games')


func _on_deck_pressed():
	globals.set_scene('deck')

var curr_deck
func _on_decks_item_selected( ID ):
	curr_deck = $decks.get_item_text(ID)


func _on_solo_pressed():
	globals.Deck = curr_deck
	globals.socket_on=false
	globals.player_num=0
	globals.start_solo_game()
	
	

extends Node2D

onready var globals = get_node('/root/master')

var socket_events = ['join','close','leave','start','open','collision']
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var state= {'show_owner':null,'show_challenger':null,'is_owner':false,'in_game':false,'self_ready':false,'opp_ready':false}

func setState(newState):
	for key in newState.keys():
		call(key,newState[key])
	
	$Owner/Change_o.hide()
	$Challenger/Change_c.hide()
	if state['self_ready']:
		if state['is_owner']:
			$Owner/Change_o.show()
		else:
			$Challenger/Change_c.show()
	
	if state['is_owner'] and state['self_ready'] and state['opp_ready']:
		$Start.show()
	else:
		$Start.hide()

###STATE FUNCTIONS

func show_owner(val):
	state['show_owner']=val
	if not val==null:
		$Owner/lbl_Name.text=val
		$Owner.show()
	else:
		$Owner.hide()

func show_challenger(val):
	state['show_challenger']=val
	if not val==null:
		$Challenger/lbl_Name.text=val
		$Challenger.show()
		$Games.hide()
	else:
		$Challenger.hide()

func is_owner(boo):
	state['is_owner']=boo
	if boo:
		$Games.hide()
	else:
		$Games.show()
"""
func selected_game(val):
	state['selected_game'] = val
	$Owner globals.open_games.filter(game=>{
		game.name == val
	})[0]
"""

func in_game(val):
	state['in_game'] = val
	if val:
		$Leave.show()
		$Games.hide()
		$Decks.show()
	else:
		$Leave.hide()
		$Games.show()
		$Decks.hide()
	

func self_ready(val):
	state['self_ready']=val
	if val:
		if state['is_owner']:
			$Owner/is_ready.text='Ready!'
			$Owner/Change_o.show()
		else:
			$Challenger/is_ready.text='Ready!'
			$Challenger/Change_c.show()
		$Decks.hide()
	else:
		if state['is_owner']:
			$Owner/is_ready.text='waiting...'
			$Owner/Change_o.hide()
		else:
			$Challenger/is_ready.text='waiting...'
			$Challenger/Change_c.hide()
		if state['in_game']:
			$Decks.show()
	globals.send_msg({'ready':val})

func opp_ready(val):
	state['opp_ready']=val
	if val:
		if state['is_owner']:
			$Challenger/is_ready.text='Ready!'
		else:
			$Owner/is_ready.text='Ready!'
	else:
		if state['is_owner']:
			$Challenger/is_ready.text='waiting...'
		else:
			$Owner/is_ready.text='waiting...'

########
func _ready():
	globals.get_games()
	get_decks()
	

func refresh_games():
	globals.get_games()
	

var deck_list
func get_decks():
	deck_list = globals.deck_list
	for deck in deck_list.keys():
		$Decks/Decks.add_item(deck)
	_on_Decks_item_selected( 0 )

###EVENTS

func game_list(val):
	for game in val:
		$Games/Games.add_item(game['name'])

func join(value):
	if not state['is_owner']:
		setState({'show_owner':value,'show_challenger':'THis is yoU','in_game':true})
	else:
		setState({'show_challenger':value})
	if state['self_ready']:
		globals.send_msg({'ready':true})
		globals.send_msg({'deck_name':$Owner/DeckName.text})

func collision(val):
	$Games/GameName.text = ""
	$Games/GameName.placeholder_text = "Game: "+val+", name taken"

func create(val):
	
	setState({'show_owner':globals.user.username,'is_owner':true,'in_game':true})

func drop(val):
	setState({'show_challenger':null})

func close(val):
	setState({'show_owner':null,'show_challenger':null,'is_owner':false,'in_game':false})

func start(val):
	pass

func ready(val):
	print('OPP READY VAL')
	print(val)
	setState({'opp_ready':val})

func deck(val):
	print('OPP Deck VAL')
	print(val)
	if state['is_owner']:
		$Challenger/DeckName.text = val
	else:
		$Owner/DeckName.text = val




var selected_game
func _on_Join_pressed():
	var game
	if $Games/Games.get_selected_items().size()>0:
		var game_index = $Games/Games.get_selected_items()[0]
		game = $Games/Games.get_item_text(game_index)
		setState({'show_owner':globals.open_games[game_index].owner,'show_challenger':globals.user.username,'is_owner':false,'in_game':true})
		globals.send_msg({'join':game})


func _on_Create_pressed():
	var game
	if $Games/GameName.text.length()>0:
		game = $Games/GameName.text
		globals.send_msg({'create':game})


func _on_Games_item_selected( index ):
	var game = $Games/Games.get_item_text(index)
	var game_owner = globals.open_games[index].owner
	setState({'show_owner':game_owner,'show_challenger':null,'is_owner':false})
	selected_game = index
	

#### DECK SELECTION STUFF

func _on_Select_pressed():
	$Decks.hide()
	"""
	var d_name = $Decks/Decks.get_item_text($Decks/Decks.get_selected_id())
	if state['is_owner']:
		$Owner/DeckName.text = d_name
	else:
		$Challenger/DeckName.text = d_name
	"""
	setState({'self_ready':true})
	globals.Deck = deck_text
	globals.send_msg({'deck_name':deck_text})

var deck_text=""
func _on_Decks_item_selected( ID ):
	$Decks/DeckList.clear()
	deck_text = $Decks/Decks.get_item_text(ID)
	if state['is_owner']:
		$Owner/DeckName.text = deck_text
	else:
		$Challenger/DeckName.text = deck_text
	for card in globals.deck_list[$Decks/Decks.get_item_text(ID)]:
		$Decks/DeckList.add_item(card)

#### START GAME
func _on_Start_pressed():
	globals.send_msg({'start':""})



func _on_Change_c_pressed():
	setState({'self_ready':false})


func _on_Change_o_pressed():
	setState({'self_ready':false})


func _on_Leave_pressed():
	if state['is_owner']:
		globals.send_msg({'close':''})
	else:
		globals.send_msg({'drop':''})
	setState({'show_owner':null,'show_challenger':null,'is_owner':false,'in_game':false,'self_ready':false,'opp_ready':false})

func _on_Refresh_pressed():
	$Games/Games.clear()
	refresh_games()


func _on_Button_pressed():
	globals.set_scene('title')

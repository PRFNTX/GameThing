extends Control
export(bool) var deck = false
var dy = 18
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

export(PackedScene) var row_scene

var top_level

func set_name(val):
	.set_name(val)
	if (top_level!=null):
		top_level.get_node('Rename').text=str(val)

func init_deck():
	pass	

func add_item(card_node):
	var row = row_scene.instance()
	row.connect('add', self, 'add_pressed')
	row.connect('remove', self, 'remove_pressed')
	row.connect('click',self,'select_item')
	row.connect('mouse_enter',self,'mouse_enter')
	$box.add_child(row)
	row.set_card(card_node)
	row.index = $box.get_child_count()-1
	return row

func get_row_by_name(card_name):
	for child in $box.get_children():
		if child.get('Name')==card_name:
			return child
	return null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func update(in_deck=null):
	### this is not great
	var deck_list = top_level.deck_lists[top_level.state['current_deck']]
	if !deck:
		for row in $box.get_children():
			var card_name = row.get('Name')
			if deck_list.keys().has(card_name):
				get_row_by_name(card_name).set('Deck',str(deck_list[card_name]))
			else:
				get_row_by_name(card_name).set('Deck',str(0))
	###
	else:
		
		for card in deck_list.keys():
			print(card)
			if get_row_by_name(card)==null:
				var thing = top_level.globals.card_instances[card]
				add_item(top_level.globals.card_instances[card]).set('Deck',deck_list[card])
			else:
				get_row_by_name(card).set('Deck',deck_list[card])
		
		var ind = 0
		for row in $box.get_children():
			if not deck_list.keys().has(row.get("Name")):
				row.queue_free()
			else:
				row.index = ind
				ind +=1



var shown_card = null
func show_card(card):
	var par=top_level
	if (shown_card!=null):
		shown_card.queue_free()
	shown_card = par.resources[card].instance()
	top_level.add_child(shown_card)
	shown_card.rect_scale=Vector2(2,2)
	var display = "Display"
	if deck:
		display = "Display2"
	shown_card.rect_position = top_level.get_node(display).position
	

var active = null
func matchSelect(num):
	active=num
	show_card($box.get_children()[num].get('Name'))
	


func _on_Gold_item_selected( index ):
	matchSelect(index)


func _on_Faeria_item_selected( index ):
	matchSelect(index)


func _on_Name_item_selected( index ):
	matchSelect(index)


func _on_Attack_item_selected( index ):
	matchSelect(index)


func _on_Health_item_selected( index ):
	matchSelect(index)


func _on_Type_item_selected( index ):
	matchSelect(index)


func _on_Num_item_selected( index ):
	matchSelect(index)


func _on_Deck_item_selected( index ):
	matchSelect(index)


func _on_Quant_item_selected( index ):
	matchSelect(index)


func add_pressed(ind):
	var childs = $box.get_children()
	top_level.add_card(childs[ind].get('Name'))


func remove_pressed(ind):
	var childs = $box.get_children()
	top_level.remove_card(childs[ind].get('Name'))

func mouse_enter(index):
	pass
	

func select_item(ind):
	for child in $box.get_children():
		child.get_node('select').hide()
	$box.get_children()[ind].get_node('select').show()
	$box.get_children()[ind].selected=true
	
	matchSelect(ind)

func _on_Save_Deck_pressed():
	"""
	var list = []
	for key in top_level.deck_lists[top_level.state['current_deck']].keys():
		for i in top_level.deck_lists[top_level.state['current_deck']][key]:
			list.append(key)
	
	top_level.HTTP.authenticated_server_request("/decks/"+top_level.state['current_deck'].replace(" ",'_'),HTTPClient.METHOD_PUT,{'cards':list,'deck_name':$Rename.text})
	set_name($Rename.text)
	top_level.globals.set_deck_list(top_level.HTTP.authenticated_server_request("/decks",HTTPClient.METHOD_GET,{}))
	top_level.initialize_decks(false)
	"""

func _on_Save_pressed():
	var list = []
	for key in top_level.deck_lists[top_level.state['current_deck']].keys():
		for i in top_level.deck_lists[top_level.state['current_deck']][key]:
			list.append(key)
	
	top_level.HTTP.authenticated_server_request("/decks/"+top_level.state['current_deck'].replace(" ",'_'),HTTPClient.METHOD_PUT,{'cards':list,'deck_name':top_level.get_node('Rename').text})
	top_level.get_node('Tabs/'+top_level.state['current_deck']).set_name(top_level.get_node('Rename').text)
	
	top_level.globals.set_deck_list(top_level.HTTP.authenticated_server_request("/decks",HTTPClient.METHOD_GET,{}))
	top_level.initialize_decks(false)

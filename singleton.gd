extends Node


onready var HTTP = get_node('/root/HTTP')

var scenes = {'game':"res://Game.tscn",'title':'res://Title.tscn', 'deck':'res://EditDeck.tscn','login':'res://Login.tscn','browse_games':'res://GameBrowser.tscn'}
var card_resources = {}
var card_instances = {}

var Deck = {}
var deck_list=null
var user
var websocket

var socket_on = true

func set_deck_list(parsedjson):
	deck_list={}
	for deck in parsedjson:
		deck_list[deck['deck_name']] = deck['cards']

func get_card_by_id(id):
	for card in card_instances.keys():
		var cn = card_instances[card].get_node('Card')
		if cn.card_number==int(id):
			return cn.card_name

func get_id_by_name(name):
	return card_instances[name].get_node('Card').card_number

var currentScene

##TESTING
func start_solo_game():
	set_scene('game')
	

func _ready():
	load_cards()
	websocket = preload('res://Godot-Websocket/websocket.gd').new(self)
	#get_tree().change_scene(scenes['login'])

func init_user():
	set_deck_list(HTTP.authenticated_server_request("/decks",HTTPClient.METHOD_GET,{}))
	socket_start()

var socket_active = false

func socket_start():
	if !socket_active:
		websocket.start('54.244.61.234',443)
		websocket.set_reciever(self,'_on_message_recieved')
		websocket.send({'greeting':user.username})
		socket_active=true


const dirPath='res://cards/'
func load_cards():
	var dir = Directory.new()
	dir.open(dirPath)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while(file_name!=""):
		if dir.current_is_dir():
			pass
		else:
			card_resources[file_name.split('.')[0]]=load(dirPath+file_name)
		file_name = dir.get_next()
	for card in card_resources.keys():
		card_instances[card]= card_resources[card].instance()


#### GET GAME LIST
var open_games
func get_games():
	send_msg({"game_list":""})

### SCENES
func set_scene(scene):
	get_tree().change_scene(scenes[scene])




#CHAT CHANNELS
#join_chat
#leave_chat
#msg_channel

#GAMES
#join
#leave
#close
#start
#open
#collision

#ACTIONS
#actions
func send_msg(value):
	#if socket_on:
	websocket.send(value)

func _on_message_recieved(msg):

	var event = parse_json(msg)
	print(event)
	var action = event.keys()[0]
	call(action,event[action])

	if get_tree().get_current_scene().has_method(action):
		get_tree().get_current_scene().call(action,event[action])

###OTHER

func hello(val):
	print('hello')

func invalid(val):
	print("UNRECOGNIZED MESSAGE ID")

func game_list(val):
	
	open_games = val

func game_action(val):
	pass

##CHATS
func join_chat(val):
	pass

func leave_chat(val):
	pass

func msg_channel(val):
	pass


var Game_player_num = null
### GAMES
func join(val):
	pass

func leave(val):
	pass

func close(val):
	pass

var player_num
func start(val):
	player_num = int(val)
	set_scene('game')


func create(val):
	pass

func collision(val):
	pass

func ready(val):
	pass

func deck(val):
	pass



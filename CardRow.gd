extends HBoxContainer


signal add
signal remove

signal click
signal mouse_over

var index = 0

func set_card(card_node):
	var card = card_node.get_node('Card')
	$Gold.text = str(card.cost_gold)
	$Faeria.text = str(card.cost_faeria)
	$Name.text = str(card.card_name)
	$Attack.text = str(card.base_attack)
	$Health.text = str(card.base_health)
	$LandType.text = str(card.lands_type)
	$LandNum.text = str(card.lands_num)
	$Deck.text = str(0)
	$Avail.text = str(3)
	

func get(field):
	return get_node(field).text

func set(field, val):
	get_node(field).text = str(val)

func _ready():
	set_process_input(true)



func _on_remove_pressed():
	emit_signal('remove', index)


func _on_add_pressed():
	emit_signal('add', index)

var selected = false
var mouseOver = false
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and mouseOver:
		emit_signal('click',index)
		 


func _on_CardRow_mouse_entered():
	if !selected:
		emit_signal('mouse_entered', index)
		$select.show()
		mouseOver=true


func _on_CardRow_mouse_exited():
	if !selected:
		$select.hide()
		mouseOver=false

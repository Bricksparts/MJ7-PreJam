extends Node2D


signal tap
signal joy_position(pos)

export(int) var  Joy_Range_P=100
export(float) var drag_range=0.2
export(bool) var follow_mode=false
export(Vector2) var joystick_rest_pos =Vector2(400,400)
export(Vector2) var offset=Vector2(0,0)
export(Array,int) var Joy_Range=[0,400,0,400]

var input_in_range:bool=false
var input_index:int=-1
var drag_r:bool=false

func _unhandled_input(event)->void:
	if event is InputEventScreenTouch :#always enter here before a screen drag
		if !event.is_pressed():#enters here when player takes fingers off screen
			if input_index==event.index:
				
				position=joystick_rest_pos+offset
				$Joy.position=Vector2(0,0)
				input_index=-1
				if !drag_r:emit_signal("tap")
				drag_r=false
		elif input_index==-1 :#enters here when player has fingers on screen
			
			if !test_input_range(event.position):
				return
			position=event.position+offset
			$Joy.position=Vector2(0,0)
			input_index=event.index
	
	if event is InputEventScreenDrag:
		if input_index==event.index:
			if sqrt((event.position-position+offset).dot(event.position-position+offset))>=Joy_Range_P*drag_range:
				drag_r=true
			if sqrt((event.position-position+offset).dot(event.position-position+offset))<=Joy_Range_P:
				$Joy.position=event.position-position+offset
			else :
				$Joy.position=(event.position-position+offset).normalized()*Joy_Range_P
				if follow_mode:
					position+=$Joy.position.normalized()*(sqrt((event.position-position+offset).dot(event.position-position+offset))-Joy_Range_P)

func get_joy_motion()->Vector2:
	return $Joy.position/Joy_Range_P

func test_input_range(a:Vector2)->bool:
	if a.x>Joy_Range[0] && a.x<Joy_Range[1] && a.y>Joy_Range[2] && a.y<Joy_Range[3]:
		return true
	else:
		return false

func _physics_process(delta):
	emit_signal("joy_position",get_joy_motion())

func _ready():
	position=joystick_rest_pos

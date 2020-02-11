extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var collidingWest

signal whileDetectWestWall (a)

func _physics_process(delta):
	if $RayCast2D.is_colliding():
		collidingWest = $RayCast2D.get_collider()
		emit_signal("whileDetectWestWall", collidingWest.is_in_group("wallRunnable"))
	

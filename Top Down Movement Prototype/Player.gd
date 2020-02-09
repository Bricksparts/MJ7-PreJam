extends KinematicBody2D

onready var pointer:= $Pointer
onready var ray:= $Pointer/RayCast2D
onready var reticle:= $Pointer/Reticle

enum state {halt, run, glide, sprint, walled}

var playerState = state.halt

const SPRINT_THRESHOLD = 1200

const FORCE_RUN = 2000
const FORCE_OVERRUN_DECEL = 300
const FORCE_HALT = 100
const FORCE_GLIDE = 600

const THRESHOLD_RUN = 200
const THRESHOLD_GLIDE = 50

var motion = Vector2()
var inputAxis = Vector2()
var jumpAxis = Vector2()

func _physics_process(delta):
	inputAxis = get_input_axis()
	update_input()
	apply_movement(delta)
	motion = move_and_slide(motion)
#	update_reticle()

func get_input_axis():
	var axis = Vector2.ZERO
	axis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	axis.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	return axis.normalized()

#func update_reticle():
#	reticle.draw_set_transform()
#	 = inputAxis * 16

func update_input():
	if playerState == state.run:
		if inputAxis == Vector2.ZERO:
			playerState = state.halt
	elif playerState == state.halt:
		if inputAxis != Vector2.ZERO:
			playerState = state.run

#func apply_friction(amount):
#	if motion.length() > amount:
#		motion -= motion.normalized() * amount
#	else:
#		motion = Vector2.ZERO

func calc_force_jump(multiplier = 1):
	#Calculates a vector2 that represents the force from the starting phase of a jump
	pass

func calc_force_run(multiplier = 1):
	#Calculates a vector2 that represents the 'input' force from running
	return inputAxis * FORCE_RUN * multiplier

func calc_force_halt(multiplier = 1):
	#Calculates a vector2 that represents the force while the player is sliding to a halt on the ground while there is no player input
	return -motion.normalized() * FORCE_HALT * multiplier

func calc_force_overrun_decel(multiplier = 1):
	#Calculates a vector2 that represents the ''input'friction' force that slows a player down to the running threshold
	return -motion.normalized() * FORCE_OVERRUN_DECEL * multiplier

func calc_force_roll(vectorRoll):
	pass

func calc_force_glide(multiplier = 1):
	#Calculates a vector2 that represents the 'input' force from gliding
	var vectorGlide = inputAxis * FORCE_GLIDE * multiplier
	return vectorGlide.clamped(THRESHOLD_GLIDE)

func apply_movement(delta):
#	var vectorMovementSum = Vector2()
	if playerState == state.halt:
		if motion.length() < 5:
			motion = Vector2.ZERO
		else:
			motion += calc_force_halt() * delta
	
	elif playerState == state.run:
		motion += calc_force_run() * delta
		motion = motion.clamped(THRESHOLD_RUN)
	
	elif playerState == state.sprint:
		pass

#	var maxSpeedMultiplier
#	if grounded:
#		maxSpeedMultiplier = speedMultiplier
#	else:
#		maxSpeedMultiplier = speedMultiplier * .1
#
#	if inputAxis == Vector2.ZERO:
#		#Apply friction while coming to a stop on the ground
##		motion -= motion.normalized() * FORCE_RUN * delta * (motion.length() / SPRINT_THRESHOLD)
#		if motion.length() > FORCE_RUN * .05:
#			motion -= motion.normalized() * FORCE_RUN * .25 * delta
#		else:
#			motion = Vector2.ZERO
#	else:
#		#Apply input force
#		if motion.length() < THRESHOLD_RUN + 10:
#			#Running
#			motion += inputAxis * FORCE_RUN * delta
#			motion = motion.clamped(THRESHOLD_RUN)
#		else:
#			#Sprinting
##			print("player is sprinting")
#			motion += inputAxis * FORCE_RUN * delta
#			motion -= motion.normalized() * FORCE_RUN * .25 * delta
#
#		if jump == true:
#			motion += inputAxis * FORCE_RUN * delta
	
		
#		var newMotion = Vector2()
#
#		newMotion = motion + inputAxis * FORCE_RUN * delta
#		if newMotion.length() > THRESHOLD_RUN && motion.length() < THRESHOLD_RUN:
#			motion = newMotion.clamped(THRESHOLD_RUN)
#		elif motion.length() > THRESHOLD_RUN:
#			motion -= newMotion.normalized() * FORCE_SPRINTING_DECEL * delta
#		else:
#			motion = newMotion
		
#		testMotion = motion + inputAxis * FORCE_RUN * delta * ((SPRINT_THRESHOLD - motion.length()) / SPRINT_THRESHOLD )
#		if testMotion.length() > motion.length():
#			motion = testMotion
#		else:
#			motion += inputAxis * FORCE_RUN * delta * ((SPRINT_THRESHOLD + motion.length()) / SPRINT_THRESHOLD )

#	if motion.length() <= LOW_SPEED_MAX:
#		motion = get_input_axis() * motion.length()
#		motion += FORCE_RUN
#	elif motion.length() <= MED_SPEED_MAX:
#		motion += FORCE_RUN
#		motion = motion.clamped(MED_SPEED_MAX)
#	else:
#		motion = Vector2.ZERO

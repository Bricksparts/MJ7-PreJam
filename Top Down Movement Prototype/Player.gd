extends KinematicBody2D

onready var pointer:= $Pointer
onready var ray:= $Pointer/RayCast2D
onready var reticle:= $Pointer/Reticle

enum moveState {stopped, halt, run, glide, sprint, walled, falling}
#enum moveAction {none, jump, sidestep, roll, vault}

var playerMoveState = moveState.stopped
#var playerMoveAction = moveAction.none

const SPRINT_THRESHOLD = 1200

const FORCE_RUN = 1600
const FORCE_SPRINT = 1000
const FORCE_SPRINT_DECEL = 1100
const FORCE_HALT = 5
const FORCE_GLIDE = 600
const FORCE_GLIDE_HALT = 5
const FORCE_JUMP = 200
const FORCE_JUMP_STOP = 50

const THRESHOLD_RUN = 160
const THRESHOLD_GLIDE = 50

const TIMER_COYOTE_TIME = 24
const TIMER_JUMP = 12
const TIMER_SIDESTEP = 18

var airTimer = 0

var velocity = Vector2()
var glideMotion = Vector2()
var inputAxis = Vector2()
#var jumpAxis = Vector2()

func _physics_process(delta):
	update_timers(delta)
	inputAxis = get_input_axis()
	update_player_state()
	apply_movement(delta)
	velocity = move_and_slide(velocity)
	print(airTimer)
	update_animation()
#	update_reticle()

func get_input_axis():
	var axis = Vector2.ZERO
	axis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	axis.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	return axis.normalized()

#func update_reticle():
#	reticle.draw_set_transform()
#	 = inputAxis * 16

func update_timers(delta):
	if airTimer > 0:
		airTimer = max(0, airTimer - 72 * delta)

func update_player_state():
	#Updates the player state and initiates actions based on player input
	
	if playerMoveState == moveState.stopped:
		if inputAxis != Vector2.ZERO:
			playerMoveState = moveState.run
	
	elif playerMoveState == moveState.halt:
		if inputAxis != Vector2.ZERO:
			playerMoveState = moveState.run
		elif velocity.length() == 0:
			playerMoveState = moveState.stopped
	
	elif playerMoveState == moveState.run:
		#Transitions and actions from the Run state
		if Input.is_action_just_released("action_jump"):
			#Initiate jump
			do_action_jump()
		elif inputAxis == Vector2.ZERO:
			#transition to Halt
			playerMoveState = moveState.halt
	
	elif playerMoveState == moveState.sprint:
		if Input.is_action_just_released("action_jump"):
			#Initiate jump
			do_action_jump()
		elif velocity.length() <= (THRESHOLD_RUN + 10):
			playerMoveState = moveState.run
	
	elif playerMoveState == moveState.glide:
		if airTimer == 0:
			touch_ground()

#func update_move_action():
#
#
#	if playerMoveState == moveState.run:
#		if Input.is_action_pressed("action_jump"):
#			playerMoveAction = moveAction.jump

#func update_input():
#	if playerMoveState == moveState.run:
#		if playerMoveAction == moveAction.jump:
#			do_action_jump()
#			playerMoveState = moveState.glide
#		if inputAxis == Vector2.ZERO:
#			playerMoveState = moveState.halt
#
#	elif playerMoveState == moveState.halt:
#		if inputAxis != Vector2.ZERO:
#			playerMoveState = moveState.run
#
#	elif playerMoveState == moveState.glide:
#		if airTimer == 0:
#			touch_ground()

#func apply_friction(amount):
#	if velocity.length() > amount:
#		velocity -= velocity.normalized() * amount
#	else:
#		velocity = Vector2.ZERO

func do_action_jump():
	#Makes the player perform a jump
	playerMoveState = moveState.glide
	velocity += calc_force_jump()
	airTimer = TIMER_JUMP

func touch_ground():
	#Transitions them to the correct speed and player state (does not yet check if they land on ground or fall yet)
	
	#Slows the player by FORCE_JUMP_STOP
	velocity = velocity.clamped(velocity.length() - FORCE_JUMP_STOP)
	
	if velocity.length() >= (THRESHOLD_RUN + 10):
		#If fast enough, transitions the player to sprinting
		playerMoveState = moveState.sprint
	elif inputAxis != Vector2.ZERO:
		#If not fast enough to Sprint, checks if the player transitions to a run
		playerMoveState = moveState.run
	else:
		#If not fast enough to Sprint, checks if the player transitions to a halt
		playerMoveState = moveState.halt

func calc_force_jump(multiplier = 1):
	#Calculates a vector2 that represents the force from the starting phase of a jump
	return inputAxis * FORCE_JUMP * multiplier

func calc_force_run(multiplier = 1):
	#Calculates a vector2 that represents the 'input' force from running
	return inputAxis * FORCE_RUN * multiplier

func calc_force_halt(multiplier = 1):
	#Calculates a vector2 that represents the force while the player is sliding to a halt on the ground while there is no player input
	return -velocity.normalized() * FORCE_HALT * multiplier * velocity.length()

func calc_force_sprint(multiplier = 1):
	#Calculates a vector2 that represents the 'acceleration' force a player inputs while sprinting
	return inputAxis * FORCE_SPRINT * multiplier

func calc_force_sprint_decel(multiplier = 1):
	#Calculates a vector2 that represent the 'friction' force that slows a player down to the running threshold while sprinting
	return -velocity.normalized() * FORCE_SPRINT_DECEL * multiplier

func calc_force_roll(vectorRoll):
	pass

func calc_force_glide(multiplier = 1):
	#Calculates a vector2 that represents the 'input' force from gliding
	if inputAxis == Vector2.ZERO:
		glideMotion = -glideMotion.normalized() * FORCE_GLIDE_HALT * multiplier * glideMotion.length()
	else:
		glideMotion += inputAxis * FORCE_GLIDE * multiplier
	glideMotion = glideMotion.clamped(THRESHOLD_GLIDE)
	return glideMotion

func apply_movement(delta):
#	var vectorMovementSum = Vector2()
	if playerMoveState == moveState.halt:
		if velocity.length() < 5:
			velocity = Vector2.ZERO
		else:
			velocity += calc_force_halt() * delta
	
	elif playerMoveState == moveState.run:
		velocity += calc_force_run() * delta
		velocity = velocity.clamped(THRESHOLD_RUN)
	
	elif playerMoveState == moveState.sprint:
		velocity += calc_force_sprint() * delta
		velocity += calc_force_sprint_decel() * delta

func update_animation():
	if playerMoveState == moveState.halt:
		$AnimatedSprite.play("Halt")
	elif playerMoveState == moveState.run:
		$AnimatedSprite.play("Run")
	elif playerMoveState == moveState.glide:
		$AnimatedSprite.play("Glide")
	elif playerMoveState == moveState.sprint:
		$AnimatedSprite.play("Sprint")

#	var maxSpeedMultiplier
#	if grounded:
#		maxSpeedMultiplier = speedMultiplier
#	else:
#		maxSpeedMultiplier = speedMultiplier * .1
#
#	if inputAxis == Vector2.ZERO:
#		#Apply friction while coming to a stop on the ground
##		velocity -= velocity.normalized() * FORCE_RUN * delta * (velocity.length() / SPRINT_THRESHOLD)
#		if velocity.length() > FORCE_RUN * .05:
#			velocity -= velocity.normalized() * FORCE_RUN * .25 * delta
#		else:
#			velocity = Vector2.ZERO
#	else:
#		#Apply input force
#		if velocity.length() < THRESHOLD_RUN + 10:
#			#Running
#			velocity += inputAxis * FORCE_RUN * delta
#			velocity = velocity.clamped(THRESHOLD_RUN)
#		else:
#			#Sprinting
##			print("player is sprinting")
#			velocity += inputAxis * FORCE_RUN * delta
#			velocity -= velocity.normalized() * FORCE_RUN * .25 * delta
#
#		if jump == true:
#			velocity += inputAxis * FORCE_RUN * delta
	
		
#		var newMotion = Vector2()
#
#		newMotion = velocity + inputAxis * FORCE_RUN * delta
#		if newMotion.length() > THRESHOLD_RUN && velocity.length() < THRESHOLD_RUN:
#			velocity = newMotion.clamped(THRESHOLD_RUN)
#		elif velocity.length() > THRESHOLD_RUN:
#			velocity -= newMotion.normalized() * FORCE_SPRINTING_DECEL * delta
#		else:
#			velocity = newMotion
		
#		testMotion = velocity + inputAxis * FORCE_RUN * delta * ((SPRINT_THRESHOLD - velocity.length()) / SPRINT_THRESHOLD )
#		if testMotion.length() > velocity.length():
#			velocity = testMotion
#		else:
#			velocity += inputAxis * FORCE_RUN * delta * ((SPRINT_THRESHOLD + velocity.length()) / SPRINT_THRESHOLD )

#	if velocity.length() <= LOW_SPEED_MAX:
#		velocity = get_input_axis() * velocity.length()
#		velocity += FORCE_RUN
#	elif velocity.length() <= MED_SPEED_MAX:
#		velocity += FORCE_RUN
#		velocity = velocity.clamped(MED_SPEED_MAX)
#	else:
#		velocity = Vector2.ZERO

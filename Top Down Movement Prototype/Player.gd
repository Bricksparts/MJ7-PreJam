extends KinematicBody2D

onready var pointer:= $Pointer
onready var ray:= $Pointer/RayCast2D
onready var reticle:= $Pointer/Reticle

enum moveState {stopped, halt, run, glide, sprint, walled, falling, sidestep}
enum moveAction {none, jump, sidestep, roll, vault}

enum otherAnimationStates {jumpCharged}

var playerMoveState = moveState.stopped
var playerInputMoveAction = moveAction.none
var playerQueuedMoveAction = moveAction.none

const SPRINT_THRESHOLD = 1200

const FORCE_RUN = 1600
const FORCE_SPRINT = 1000
const FORCE_SPRINT_DECEL = 1100
const FORCE_HALT = 5
const FORCE_GLIDE = 600
const FORCE_GLIDE_HALT = 5
const FORCE_JUMP = 200
const FORCE_JUMP_STOP = 50
const FORCE_SIDESTEP = 300

const THRESHOLD_RUN = 160
const THRESHOLD_GLIDE = 50

const TIMER_COYOTE_TIME = 24
const TIMER_JUMP = 18
const TIMER_SIDESTEP = 6
const TIMER_JUMP_CHARGE_UP = 40

const TICKS_PER_SECOND = 72
const CLAMP_FUDGE = 5

var isInputAxisLocked = false

var jumpChargeUpTimer = 0
var sidestepTimer = 0
var airTimer = 0

var velocity = Vector2()
var velocityMemory = Vector2()
var glideMotion = Vector2()
var inputAxis = Vector2()
var inputAxisLocked = Vector2()
var joyInput=Vector2(0,0)
#var jumpAxis = Vector2()

func _ready():
	add_to_group("Player")
	get_parent().get_node("StaticBody2D").add_to_group("wallRunnable")

func _physics_process(delta):
	update_timers(delta)
	update_input_axis()
	update_player_state()
	update_input_move_action()
	apply_movement(delta)
	velocity = move_and_slide(velocity)
	update_animation()
#	update_reticle()

func update_input_axis():
	if isInputAxisLocked == false:
		inputAxis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
		inputAxis.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		inputAxis = (inputAxis.normalized() + joyInput).clamped(1)

func update_input_move_action():
	if Input.is_action_just_pressed("action_jump"):
		print("HELLO")
		if playerMoveState == moveState.run or moveState.sprint:
			playerQueuedMoveAction = moveAction.sidestep
			jumpChargeUpTimer = TIMER_JUMP_CHARGE_UP
			isInputAxisLocked = true
	
	if playerQueuedMoveAction == moveAction.sidestep:
		if jumpChargeUpTimer == 0:
			playerQueuedMoveAction = moveAction.jump
		elif Input.is_action_just_released("action_jump"):
			do_action_sidestep()
			jumpChargeUpTimer = 0
			isInputAxisLocked = false
	elif playerQueuedMoveAction == moveAction.jump:
		if Input.is_action_just_released("action_jump"):
			do_action_jump()
			isInputAxisLocked = false


#func update_reticle():
#	reticle.draw_set_transform()
#	 = inputAxis * 16

func update_timers(delta):
	airTimer = calc_timer(airTimer, delta)
	sidestepTimer = calc_timer(sidestepTimer, delta)
	jumpChargeUpTimer = calc_timer(jumpChargeUpTimer, delta)

func calc_timer(timer, delta):
	if timer > 0:
		timer = max(0, timer - TICKS_PER_SECOND * delta)
	return timer

func update_player_state():
	#Updates the player state and initiates actions based on player input
	
	if playerMoveState == moveState.stopped:
		#Stopped state
		if inputAxis != Vector2.ZERO:
			#transition from Stopped to Run
			playerMoveState = moveState.run
	
	elif playerMoveState == moveState.halt:
		#Halt state
		if inputAxis != Vector2.ZERO:
			#transition from Halt to Run
			playerMoveState = moveState.run
		elif velocity.length() == 0:
			#transition from Halt to Stopped
			playerMoveState = moveState.stopped
	
	elif playerMoveState == moveState.run:
		#Run state
		if playerInputMoveAction == moveAction.jump:
			#initiate Jump from Run
			do_action_jump()
		elif playerInputMoveAction == moveAction.sidestep:
			#initiate Sidestep from Run
			do_action_sidestep()
		elif inputAxis == Vector2.ZERO:
			#transition from Run to Halt
			playerMoveState = moveState.halt
	
	elif playerMoveState == moveState.sprint:
		#Sprint state
		if playerInputMoveAction == moveAction.jump:
			#initiate Jump from Sprint
			do_action_jump()
		elif playerInputMoveAction == moveAction.sidestep:
			#initiate Sidestep from Sprint
			do_action_sidestep()
		elif velocity.length() <= (THRESHOLD_RUN + CLAMP_FUDGE):
			#transition from Sprint to Run
			playerMoveState = moveState.run
	
	elif playerMoveState == moveState.glide:
		#Glide state
		if airTimer == 0:
			#Transition from Glide to one of the grounded states
			touch_ground()
	
	elif playerMoveState == moveState.sidestep:
		#Sidestep state
		
		#NEED TO CHECK FOR WALLRUNABLE OBJECT
		if sidestepTimer == 0:
			#transition from Sidestep to one of the grounded states
			sidestep_end()

func do_action_jump():
	#Makes the player perform a jump
	playerMoveState = moveState.glide
	velocity += calc_force_jump()
	airTimer = TIMER_JUMP

func do_action_sidestep():
	#Makes the player perform a sidestep
	playerMoveState = moveState.sidestep
	velocityMemory = velocity
	velocity = calc_force_sidestep()
	sidestepTimer = TIMER_SIDESTEP

func convert_grounded_speed_to_state():
	if velocity.length() >= (THRESHOLD_RUN + CLAMP_FUDGE):
		#If fast enough, transitions the player to sprinting
		playerMoveState = moveState.sprint
	elif inputAxis != Vector2.ZERO:
		#If not fast enough to Sprint, checks if the player transitions to a run
		playerMoveState = moveState.run
	else:
		#If not fast enough to Sprint, checks if the player transitions to a halt
		playerMoveState = moveState.halt

func touch_ground():
	#Slows the player by FORCE_JUMP_STOP
	velocity = velocity.clamped(velocity.length() - FORCE_JUMP_STOP)
	convert_grounded_speed_to_state()

func sidestep_end():
	#returns the player's velocity to that which it was before the sidestep
	velocity = velocityMemory
	convert_grounded_speed_to_state()

func calc_force_jump(multiplier = 1):
	#Calculates a vector2 that represents the force from the starting phase of a jump
	return inputAxis * FORCE_JUMP * multiplier

func calc_force_sidestep(multiplier = 1):
	#Calculates a vector2 that represents the force from the starting phase of a sidestep
	return inputAxis * FORCE_SIDESTEP * multiplier

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
		if velocity.length() < CLAMP_FUDGE:
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
	
	#overrule cases
#	if




func _on_Joystick_joy_position(pos):
	joyInput=pos


func _on_WallDetector_whileDetectWestWall(a):
	if a:
		print("Colliding with runnable wall")
	else:
		print("Collindng with non-runnable wall")

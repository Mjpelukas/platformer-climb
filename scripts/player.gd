# Extends CharacterBody2D, meaning this script will inherit the properties and methods of CharacterBody2D.
extends CharacterBody2D

# Exports allow these variables to be adjustable from the Godot Editor, providing easy tweaks for gameplay.
@export var player_speed = 100 # The player's speed.
@export var gravity = 30 # Gravity applied to the player.
@export var jump_force = 5 # The force applied when the player jumps.

# Onready variables are initialized once the node and its children are part of the scene tree, ensuring they're not null.
@onready var ap = $AnimationPlayer # Reference to the AnimationPlayer node.
@onready var sprite = $Sprite2D # Reference to the Sprite2D node.
@onready var cshape = $CollisionShape2D # Reference to the CollisionShape2D node.
@onready var crouch_cast_1 = $CrouchCast_1 # Reference to a RayCast2D node used for crouching logic.
@onready var crouch_cast_2 = $CrouchCast_2 # Another RayCast2D node used for crouching logic.

# State variables to track the character's status.
var is_crouching = false # Tracks if the player is crouching.
var stuck_under_object = false # Tracks if the player is stuck under an object while crouching.

# Preload collision shapes for standing and crouching to swap based on the player's state.
var standing_cshape = preload("res://resources/knight_standing_cshape.tres")
var crouching_cshape = preload("res://resources/knight_crouching_cshape.tres")

# _process function runs every frame but is empty here, indicating no frame-by-frame logic is required.
func _process(delta):
	pass

# _physics_process handles physics-related updates, running at a fixed framerate, ideal for movement and physics calculations.
func _physics_process(delta):
	# Apply gravity if the player is not on the ground. Cap the falling speed with a maximum value.
	if !is_on_floor():
		velocity.y += gravity
		if velocity.y > 700:
			velocity.y = 700
	
	# Handle jumping. Only allows jumping if the player is on the floor.
	if Input.is_action_just_pressed("jump") && is_on_floor():
		velocity.y = -jump_force
	
	# Determine movement direction and set horizontal velocity.
	var horizontal_direction = Input.get_axis("move_left", "move_right")
	velocity.x = horizontal_direction * player_speed
	
	# Flip the sprite and adjust position based on movement direction.
	if horizontal_direction != 0:
		switch_directions(horizontal_direction)
		
	# Handle crouching and standing up.
	if Input.is_action_pressed("crouch"):
		crouch()
	elif Input.is_action_just_released("crouch"):
		if can_stand():
			stand()
		else:
			if !stuck_under_object:
				stuck_under_object = true
	
	# Automatically stand up when there's no obstruction and the crouch button is not pressed.
	if stuck_under_object && can_stand() && !Input.is_action_pressed("crouch"):
		stand()
		stuck_under_object = false
	
	# Move the player and slide along surfaces.
	move_and_slide()
	
	# Update the player's animation based on their current state and actions.
	update_animations(horizontal_direction)

# Handles the logic for updating the player's animations based on their actions and state.
func update_animations(horizontal_direction):
	if is_on_floor():
		if horizontal_direction == 0:
			if is_crouching:
				ap.play("crouch")
			else:
				ap.play("idle")
		else: 
			if is_crouching:
				ap.play("crouch_walk")
			else:
				ap.play("run")
	else: # in the air
		if is_crouching == false:
			if velocity.y < 0:
				ap.play("jump")
			elif velocity.y > 0:
				ap.play("fall")
		else:
			ap.play("crouch")

# Flips the sprite based on the direction of movement and adjusts its position slightly.
func switch_directions(horizontal_direction):
	sprite.flip_h = (horizontal_direction == -1)
	sprite.position.x = horizontal_direction * 4

# Transitions the player into a crouching state, changing the collision shape to the crouching one.
func crouch():
	if is_crouching:
		return
	is_crouching = true
	cshape.shape = crouching_cshape
	cshape.position.y = 30
		
# Transitions the player back to a standing state, restoring the original collision shape.
func stand():
	if is_crouching == false:
		return
	is_crouching = false
	cshape.shape = standing_cshape
	cshape.position.y = 23

# Checks if the player can stand up from a crouch by checking for collisions above.
func can_stand() -> bool:
	return !crouch_cast_1.is_colliding() && !crouch_cast_2.is_colliding()

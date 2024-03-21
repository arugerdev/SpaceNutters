extends CharacterBody3D

# Player Nodes
@onready var neck = $neck
@onready var head = $neck/head
@onready var eyes = $neck/head/eyes
@onready var standing_collision_shap = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var camera = $neck/head/eyes/Camera3D
@onready var animation_player = $neck/head/eyes/AnimationPlayer
@onready var mesh = $RootNode/Skeleton3D/Char
@onready var infected_label = $neck/head/eyes/Camera3D/Label
@onready var animation_player_skin = $AnimationPlayer
@onready var animation_tree = $AnimationTree
@onready var playerName = $neck/head/PlayerName
@onready var kickingArea = $neck/head/eyes/Camera3D/Area3D

# Speed vars
var current_speed = 5.0

const walking_speed = 4.0
const sprinting_speed = 8.0
const crouching_speed = 3.5

# States
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var hard_landing = false
var sliding = false
var isKiking = false

# Slide vars
var slide_timer = 0.0
var slide_timer_max = 1
var slide_vector = Vector2.ZERO
var slide_speed = 11.0

# Head bobbing vars
const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 15.0
const head_bobbing_croching_speed = 10.0

const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

# Movement vars
var crouching_depth = -0.6
const jump_velocity = 4.5
var lerp_speed = 10.0
var air_lerp_speed = 3.0
var free_look_tilt_amount = 8
var last_velocity = Vector3.ZERO
var hard_landing_time_max = 1
var hard_landing_time = 0

# Input vars
var direction = Vector3.ZERO
const mouse_sens = 0.25

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Game vars
var infected = false
var state = {
			"id":0,
			"velocity": Vector3.ZERO,
			"pos": Vector3.ZERO,
			"inAir": false,
			"crouching": false,
			"sliding": false,
			"hardLanding": false
			}

func _ready():
	if not is_multiplayer_authority(): 
		infected_label.hide()
		$neck/head/eyes/Camera3D/LabelID.hide()
		return
	
	mesh.hide()
	playerName.hide()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	$neck/head/eyes/Camera3D/LabelID.text = "ID: " + var_to_str(multiplayer.get_unique_id())
# Multiplayer Authority Handle

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _input(event):
	if not is_multiplayer_authority(): return
	
	# Mouse Detection
	
	if event is InputEventMouseMotion:
		
		# Free Looking Logic
		
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			
		# Mouse Looking Logic
		
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Getting Movement Input
	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	state = {
		"id": multiplayer.get_unique_id(),
		"velocity": input_dir.normalized() * current_speed / walking_speed,
		"position": position,
		"inAir": !is_on_floor(),
		"crouching": crouching,
		"sliding": sliding,
		"hardLanding": hard_landing
		}
	
	# Handle Movement State
	
	if hard_landing_time > 0:
		hard_landing = true
		hard_landing_time -= delta
		
	if hard_landing_time <= 0:
		hard_landing = false
	
	if is_on_floor():
		isKiking = false
	
	# Crouching
	
	if Input.is_action_pressed("crouch") || sliding:
		
		current_speed = lerp(current_speed,crouching_speed, delta * lerp_speed)
		head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed)
		
		crouching_collision_shape.disabled = false
		standing_collision_shap.disabled = true
		
		# Slide Begin Logic
		
		if  sprinting and input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true
			
			if !is_on_floor():
				isKiking = true
			
		crouching = true
		walking = false
		sprinting = false
		
	elif !ray_cast_3d.is_colliding():
		
	# Standing
		
		standing_collision_shap.disabled = false
		crouching_collision_shape.disabled = true
		
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			# Sprinting
			current_speed = lerp(current_speed,sprinting_speed, delta * lerp_speed)
			
			walking = false
			sprinting = true
			crouching = false
		else:
			# Walking
			current_speed = lerp(current_speed,walking_speed, delta * lerp_speed)
			
			walking = true
			sprinting = false
			crouching = false
			
	# Handle Free Looking
	
	if Input.is_action_pressed("free_look") || sliding:
		free_looking = true
		
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z, -deg_to_rad(7.0), delta * lerp_speed)					
		else:
			eyes.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)					
		
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, delta * lerp_speed)
			
	# Handle Sliding
	
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false
	
	# Handle headbob
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_croching_speed * delta
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index / 2) + 0.5
	
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (head_bobbing_current_intensity / 2.0), delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * (head_bobbing_current_intensity), delta * lerp_speed)
		
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * lerp_speed)
		
	# Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false
		animation_player.play("jump")

	# Handle landing
	if is_on_floor():
		if last_velocity.y < -10.0:
			hard_landing_time = hard_landing_time_max
			hard_landing = true
			state.hardLanding = true
			animation_player.play("hard_landing")
		elif last_velocity.y < -4.0:
			animation_player.play("landing")
	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * air_lerp_speed)

	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		current_speed = (slide_timer + 0.1) * slide_speed
	
	if hard_landing:
		current_speed = crouching_speed * 0.5
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	last_velocity = velocity
	
	move_and_slide()

func _process(delta):
	
	if position.y <= -100:
		position = Vector3.UP
		velocity = Vector3.ZERO
		last_velocity = Vector3.ZERO
	
	playerName.text = var_to_str(state.id)
	updateAnimations(delta)
	
	if not is_multiplayer_authority():
		var mat : ShaderMaterial = mesh.get_surface_override_material(0).get_next_pass()
		mat.set_shader_parameter("enable", infected) 
		return
		
	for p in multiplayer.get_peers():
		updateData.rpc_id(p,state)
					
	if infected:
		infected_label.text = "Infected"
		infected_label.set("theme_override_colors/font_color", Color.DARK_RED)
	elif !infected:
		infected_label.text = "No Infected"
		infected_label.set("theme_override_colors/font_color", Color.GREEN)
	
func updateAnimations(delta):
	var target = Vector2( clamp(state.velocity.x , -2, 2), clamp(state.velocity.y , -2, 2))
	var from = animation_tree.get("parameters/Walking&Running/blend_position")
	
	animation_tree.set("parameters/Walking&Running/blend_position",  lerp(from, target, 5 * delta))
	animation_tree.set("parameters/Crouch/blend_position",  lerpf(animation_tree.get("parameters/Crouch/blend_position"), state.velocity.y, 5 * delta))
	
	animation_tree.set("parameters/conditions/is_in_air", state.inAir)
	animation_tree.set("parameters/conditions/hardLanding", (!state.inAir && state.hardLanding))
	animation_tree.set("parameters/conditions/fallingToLand", (!state.inAir && !state.hardLanding))
	animation_tree.set("parameters/conditions/crouching", state.crouching)
	animation_tree.set("parameters/conditions/sliding", state.sliding)
	animation_tree.set("parameters/conditions/standing", (!state.crouching && !state.sliding))
	animation_tree.set("parameters/conditions/slidingToCrouch", (state.crouching && !state.sliding))
	
@rpc("call_local","any_peer")
func set_infectation(value):
	infected = value
	
@rpc("call_remote","any_peer", "reliable")
func updateData(value):
	for player in multiplayer.get_peers():
		if player == multiplayer.get_remote_sender_id():
			get_node("/root/").find_child(var_to_str(player), true, false).state = value
	

	
@rpc("call_local","any_peer")
func kickedDash(dir, force):
	last_velocity += dir * force
	velocity += dir * force
	move_and_slide()


func _on_area_3d_body_entered(body):
	if !isKiking || body == $".":
		return
	if body.has_method("kickedDash"):
		last_velocity = Vector3.DOWN
		velocity = Vector3.DOWN
		move_and_slide()
		body.kickedDash.rpc(-global_transform.basis.z, 100)	
		

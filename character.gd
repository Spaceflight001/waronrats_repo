extends CharacterBody3D

var camrot: Vector3 = Vector3(0,0,0)

@export var health: float = 100.0

@export var camvel: Vector3 = Vector3(0,0,0)
@export var camoff: Vector3 = Vector3(0,0,0)

var lastpos: Vector3 = Vector3(0,0,0)
var lastinair: bool = false
@export var true_velocity: Vector3
@export var gun: Node

var speed: float = 3.0
const jump_vel: float = 8.5
var accel: float = 30.0
var charvely: float = 0.0

var aimspeed: float = 6
var aimtime: float = 0.0

var camrecoil: float = 0.1
var recoilpos: float = 0.0
var recoilvel: float = 0.0
var recoilmax: float = 40.0

var sensitivity: float = 1.0

var unaimpos = Vector3(0.3,-0.3,-0.9)
@onready var aimpos = Vector3(0,0,0)

func fire():
	camoff.x = randf_range(-10,10)/500
	camoff.y = randf_range(-10,10)/500
	camrot.x += deg_to_rad(0.2)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camrot.y -= event.relative.x / 500 * sensitivity
		camrot.x -= event.relative.y / 500 * sensitivity
	if event.is_action_pressed("escape"):
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action("aim"):
		aimtime = 0.0
		speed = 6
	
	#equip logic
	if Input.is_key_pressed(KEY_1):
		if has_node("GunNode"):
			$GunNode.reparent($Backpack, false)
			$".."/Buttons.currenttool = null
		else:
			velocity = Vector3.ZERO
			$Backpack.find_child("GunNode").reparent(self, false)
			$GunNode.position.y = 0.5
			aimpos = -Vector3($GunNode/Gun/AimPositon.position.x,$GunNode/Gun/AimPositon.position.z,$GunNode/Gun/AimPositon.position.y)
			$".."/Buttons.currenttool = $GunNode

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	aimtime += delta
	true_velocity = global_position - lastpos

	#handle camera
	camoff += camvel * delta
	camvel.x -= velocity.y / 200
	$Camera3D.rotation = camrot + camoff
	
	
	#add gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 2
	else:
		velocity.y = 0.0
	
	#if player falls, reset
	if position.y < -100:
		position = Vector3(0,10,0)
	
	#handle camera zoom
	#if Input.is_action_pressed("aim") and has_node("GunNode"):
		#$Camera3D.fov = move_toward($Camera3D.fov, 65, delta * 30)
	#else:
		#$Camera3D.fov = move_toward($Camera3D.fov, 75, delta * 30)
	
	
	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y += jump_vel
	
	# handle sprinting.
	if Input.is_action_pressed("sprint") and Input.is_action_pressed("move_forward"):
		if speed < 10:
			speed += accel * delta
		elif speed != 10:
			speed = 10
			accel = 60.0
	else:
		if speed > 3:
			speed -= accel * delta
		elif speed != 3:
			speed = 3
	
	#handle aiming
	if Input.is_action_pressed("aim"):
		sensitivity = 0.5
	else:
		sensitivity = 1
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left","move_right", "move_forward", "move_backward").rotated(-$Camera3D.global_rotation.y)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var maxspeed = direction * speed
	if direction:
		velocity.x += direction.x * accel * delta
		velocity.z += direction.z * accel * delta
		if Vector3(velocity.x,0,velocity.z).length_squared() / 5 > speed:
			velocity.x -= velocity.x * 10 * delta
			velocity.z -= velocity.z * 10 * delta
	else:
		pass
		velocity.x -= velocity.x * (delta * accel)
		velocity.z -= velocity.z * (delta * accel)
	
	var freq: float = 1.5
	if has_node("GunNode"):
		freq = $GunNode.recoil_frequency
	
	#camera recoil spring logic
	var caminc = -camoff * freq
	camvel += caminc
	camvel *= 1-delta*3
	
	lastpos = global_position
	move_and_slide()

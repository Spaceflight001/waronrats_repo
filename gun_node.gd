extends Node3D

#key nodes
@onready var main = get_tree().root.get_child(0)
@onready var objpool = main.objpool

@export var actualname: String = "Placeholder"

@export var damage: float
@export var firerate: float
@export var accuracy: float
@export var pellets: int
@export var velocity: float
@export var aimspeed: float

@export var ammo: int
@export var capacity: int

@export var recoil_power: float
@export var aim_recoil: float
@export var recoil_frequency: float

@export var bullet_mesh: PackedScene

var camrotation = Vector3.ZERO
var camdiff = Vector3.ZERO

var swayosc: Vector2 = Vector2(0,1)

var gunoff:Vector3 = Vector3(0,0,0)
var sway:float = 0.0
var walksway:float = 0.0

var sprintoff:float = 0.0
var sprintvel:float = 0.0
var charvely:float = 0.0

var fired: int = 0.0
var lastfire:float = 0.0
var reset:bool = false

#vertical gun recoil spring
var recoilpos:float = 0.0
var recoilvel:float  = 0.0

#horizontal gun recoil spring
var recoilposh:float = 0.0
var recoilvelh:float = 0.0

#camera recoil spring
var crecoilpos:float = 0.0
var crecoilvel:float = 0.0

var noise:FastNoiseLite = FastNoiseLite.new()

@onready var unaimpos = $Gun.position
@onready var aimpos = -Vector3($Gun/AimPositon.position.x,$Gun/AimPositon.position.z,$Gun/AimPositon.position.y)

func _input(event: InputEvent) -> void:
	
	#reload logic
	if event.is_action_pressed("reload"):
		ammo = capacity

func fire():
	lastfire = 0.0
	$Gun/ShootSound.pitch_scale = 0.96 + randf()*0.08
	$Gun/ShootSound.play(0.1)
	ammo -= 1
	
	#pellets
	for pellets in pellets:
		var bullet
		if objpool.is_empty():
			bullet = bullet_mesh.instantiate()
			main.add_child(bullet)
		else:
			bullet = objpool[0]
			objpool.remove_at(0)
		
		# 1. Calculate the spread (adjust 5.0 to change max spread angle)
		var spread_amount = deg_to_rad(45.0 / accuracy)
		var random_roll = randf() * TAU
		var random_pitch = randf() * spread_amount
		
		# 2. Create the spread rotation
		var spread_rot = Basis().rotated(Vector3.UP, random_roll) * Basis().rotated(Vector3.RIGHT, random_pitch)
		
		# 3. Apply it to the gun's current global_basis
		var spreaded = $Gun.global_basis * spread_rot
		
		# 4. Assign to bullet
		bullet.global_basis = spreaded
		bullet.global_position = $Gun/Origin.global_position
		bullet.origin = $Gun/Origin.global_position
		bullet.velocity = spreaded.y * velocity + get_parent().velocity
		bullet.damage = damage
		bullet.show()
		bullet.set_process(true)
		bullet.set_physics_process(true)
	fired += 1
	
	var recoilinc = -recoilpos * 0.4
	$Gun/FlashLight.light_energy = 2
	print(noise.get_noise_1d(fired))
	if Input.is_action_pressed("aim"):
		recoilvel += 0.4 + recoilinc
		recoilvelh += randf_range(-400,400)/4000 + recoilinc
		$Gun.position.z += 0.02
		get_parent().camvel += Vector3(deg_to_rad(recoil_power),0,deg_to_rad(recoil_power) * noise.get_noise_1d(fired)) * aim_recoil
	else:
		recoilvel += 0.8 + recoilinc
		recoilvelh += randf_range(-400,400)/2000 + recoilinc
		$Gun.position.z += 0.04
		get_parent().camvel += Vector3(deg_to_rad(recoil_power),0,deg_to_rad(recoil_power) * noise.get_noise_1d(fired))
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lastfire = 0.0
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.9


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	lastfire += delta
	recoilpos += recoilvel * delta
	recoilposh += recoilvelh * delta
	crecoilpos += crecoilvel * delta
	sprintoff += sprintvel / 5
	
	
	if gunoff.y > 0:
		gunoff.x = (-gunoff.y ** 2) * 2
	else:
		gunoff.x = (-gunoff.y ** 2) * 2
	
	if get_parent().name != "Backpack":
		#handle shooting
		if Input.is_action_pressed("fire") and lastfire > (60.0 / firerate):
			if ammo > 0:
				fire()
		
		$Gun/SubViewport/Camera3D.global_position = $Gun/AimPositon.global_position
		$Gun/SubViewport/Camera3D.global_rotation = $Gun/Sprite3D.global_rotation
		
		#handle muzzle flash
		$Gun/FlashLight.light_energy = move_toward($Gun/FlashLight.light_energy, 0, delta * 20)
		
		$Gun.rotation.y = 0.3 * sprintoff
		if camrotation != Vector3.ZERO:
			camdiff = (get_parent().find_child("Camera3D").rotation - camrotation)
		camrotation = get_parent().find_child("Camera3D").rotation
		recoilvel -= camdiff.x * 1.5
		recoilvelh -= camdiff.y * 1.5
		rotation = camrotation + Vector3(gunoff.x * walksway - charvely + recoilpos - 0.3 * sprintoff, gunoff.y * sway + recoilposh,0)
		#get_parent().camoff.y += deg_to_rad(randf_range(-crecoilpos * 100, crecoilpos * 100) / 100) * 10
		
		#handle sway
		var input_dir := Input.get_vector("move_left","move_right", "move_forward", "move_backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction:
			if Input.is_action_pressed("sprint") and Input.is_action_pressed("move_forward"):
				sway = move_toward(sway, 1, delta / 2)
				walksway = move_toward(walksway, 0.6, delta / 2)
				sprintvel += 0.025
			else:
				if get_parent().velocity.length_squared() / 5 < 4:
					sway = move_toward(sway, 0.1, delta / 2)
					walksway = move_toward(walksway, 0.2, delta)
				else:
					sway = move_toward(sway, 0.1, delta / 4)
					walksway = move_toward(walksway, 0.2, delta / 2)
		else:
			#sprintoff = move_toward(sprintoff, 0, delta)
			walksway = move_toward(walksway, 0, delta / 4)
			if Input.is_action_pressed("aim"):
				sway = move_toward(sway, 0.0, delta / 1.25)
			else:
				sway = move_toward(sway, 0.0, delta / 1.5)
		
		var cam = get_parent().find_child("Camera3D")
		var diff = aimpos.distance_to(unaimpos)
		if Input.is_action_pressed("aim"):
			var dist = $Gun.position.distance_to(aimpos)
			$Gun.position = $Gun.position.move_toward(aimpos, aimspeed * delta * dist)
		else:
			var dist = $Gun.position.distance_to(unaimpos)
			$Gun.position = $Gun.position.move_toward(unaimpos, aimspeed * delta * dist)
		
		charvely += get_parent().velocity.y * delta * 0.1
		charvely *= 1-delta*3
		
		#make the gun sway
		var horvel = Vector3(get_parent().velocity.x,0,get_parent().velocity.z) / 4
		swayosc = swayosc.rotated(deg_to_rad(delta* 2 + 360.0 * delta * horvel.length()))
		gunoff.y = swayosc.x * walksway
	else:
		pass
	
	#recoil springs
	var recoilinc = -recoilpos * 2
	recoilvel += recoilinc
	recoilvel *= 1-delta*5
	
	var recoilinch = -recoilposh * 2
	recoilvelh += recoilinch
	recoilvelh *= 1-delta*5
	
	var crecoilinc = -crecoilpos * 2
	crecoilvel += crecoilinc
	crecoilvel *= 1-delta*5
		
	var sprintinc = -sprintoff * 0.03
	sprintvel += sprintinc
	sprintvel *= 1-delta*4
	if sprintvel < 0:
		sprintvel *= 1-delta*4
		

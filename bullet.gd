extends MeshInstance3D

@onready var main = get_tree().root.get_child(0)
@onready var effpool = main.effpool

@export var damage: float
@export var velocity: Vector3
@export var origin: Vector3
@export var hiteffect: PackedScene
var accel = Vector3(0,-2.8,0)
var lifetime = 0.0
var destroy = false

var hitcolor:Color = Color(1,0.5,0.5)
var killcolor:Color = Color(0.8,0,0)

var hits: Array[Node] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	origin = global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if destroy == true and main.objpool.has(self) == false:
		destroy = false
		hide()
		set_process(false)
		set_physics_process(false)
		origin = Vector3(0,-100,0)
		velocity = Vector3.ZERO
		position = Vector3(0,-100,0)
		rotation = Vector3.ZERO
		main.objpool.append(self)
		lifetime = 0.0
	
	var nextx = origin.x + velocity.x*lifetime + 0.5*accel.x * lifetime**2
	var nexty = origin.y + velocity.y*lifetime + 0.5*accel.y * lifetime**2
	var nextz = origin.z + velocity.z*lifetime + 0.5*accel.z * lifetime**2
	
	
	var nextpos = Vector3(nextx,nexty,nextz)
	look_at(nextpos, Vector3.UP)
	rotation += Vector3(deg_to_rad(90),0,0)
	scale.y = position.distance_to(nextpos)
	$Raycast.target_position.y = -scale.y
	$Raycast.force_raycast_update()
	
	if $Raycast.is_colliding():
		var collider = $Raycast.get_collider()
		#print(collider)
		if collider.name != "Character":
			position = $Raycast.get_collision_point()
			
			#if it hit a rat
			if collider.name.begins_with("Rat"):
				
				#if the bullet havent hit the rat
				if hits.has(collider) != true:
					hits.append(collider)
					main.feed.emit(str(damage), hitcolor)
					main.get_node("Hitmarker").play()
					collider.health -= damage
					
					#apply impulse
					#var impoff: Vector3 = collider.position - $Raycast.get_collision_point()
					#collider.apply_impulse((nextpos - position) * 10, impoff)
				else:
					position = nextpos
			else:
				destroy = true 
			if collider.is_class("MeshInstance3D") or collider.is_class("CSGMesh3D"):
				var hit
				if effpool.is_empty():
					hit = hiteffect.instantiate()
					main.add_child(hit)
				else:
					hit = effpool[0]
					effpool.remove_at(0)
				hit.set_process(true)
				
				#var hit = hiteffect.instantiate()
				var look = $Raycast.get_collision_point() + $Raycast.get_collision_normal()
				#main.add_child(hit)
				hit.position = $Raycast.get_collision_point()
				hit.look_at(look)
				hit.material = $Raycast.get_collider().mesh.get_material()
				hit.get_node("Shards").draw_pass_1.material = $Raycast.get_collider().mesh.get_material()
				hit.get_node("Shards").restart()
				hit.get_node("Smoke").restart()
	else:
		position = nextpos
	
	lifetime += delta
	
	if lifetime > 2.5:
		destroy = true

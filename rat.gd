extends RigidBody3D

@export var health: float = 0.0

var lastjump: float = 5.0
var lastdamage: float = 0.0
@onready var collray:RayCast3D = $CollisionRay
@onready var main:Node = get_tree().root.get_child(0)

var isonfloor: bool = true

var killcolor:Color = Color(0.8,0,0)

var floornormal: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	lastjump += delta
	lastdamage += delta
	
	var playerpos = get_tree().root.get_child(0).find_child("Character").position
	#var velocity = linear_velocity
	#velocity = (playerpos - position).normalized() / 20
	#velocity = -global_basis.z / 18
	#if isonfloor == true:
		#velocity = -global_basis.z * 6
	#velocity += get_gravity() * delta * 1.3
	
	#handle gravity
	
	#if collray.is_colliding() == false:
		#linear_velocity.y += -9.8 * 3 * delta
	#elif collray.get_collision_normal() > 0:
		#linear_velocity.y += -9.8 * collray.get_collision_normal().y * 3 * delta
	#print(collray.get_collision_normal().y)
	
	if collray.is_colliding():
		linear_velocity.y += -9.8 * delta
		#linear_velocity += collray.get_collision_normal() * Vector3(0,-29.4,0) * delta
	else:
		linear_velocity.y += -9.8 * 3 * delta
	
	
	if $JumpRaycast.get_collider() != null:
		if lastjump > 2.0:
			lastjump = 0.0
			linear_velocity.y += 10
	
	var look: Vector3
	#for part in get_colliding_bodies():
		#print(c)
	
	linear_velocity += -global_basis.z * 10 * delta
	#linear_velocity = velocity
	#move_and_collide(velocity)
	
	#kill if fall
	if global_position.y < -100:
		health = 0.0
	
	#health logic
	if health <= 0.0:
		main.feed.emit("KILLED RAT [100]", killcolor)
		main.get_node("Killmarker").play()
		queue_free()
	
	#face player
	look_at(playerpos, Vector3.UP)
	rotation.x = 0
	rotation.z = 0
	
	#deal damage if player touches rat
	var colliders = get_colliding_bodies()
	for collider in colliders:
		if collider.name == "Character" and lastdamage > 1:
			lastdamage = 0.0
			collider.health = move_toward(collider.health, 0, 5)
			var mult: float = collider.health / 100
			main.get_node("Buttons/Sideblack").modulate.a = 1
			main.get_node("Character").camvel += Vector3(mult * 2 * (randf() - randf()),mult * 2 *  (randf() - randf()),0)
	
	if collray.is_colliding():
		var target_basis = Basis()
		target_basis.y = collray.get_collision_normal()
		target_basis.x = target_basis.y.cross(global_transform.basis.z).normalized()
		target_basis.z = target_basis.x.cross(target_basis.y).normalized()
		
		global_transform.basis = target_basis
	#rotate(Vector3(0,0,1), rotz - deg_to_rad(90))
	#rotate(Vector3(1,0,0), rotx + deg_to_rad(0))

#func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#var currvelocity: Vector3 = linear_velocity
	#
	#var count = state.get_contact_count()
	#if count > 0:
		#var normal = state.get_contact_local_normal(0)
		#for i in count:
			#normal = state.get_contact_local_normal(1)
			#
			#if normal.angle_to(Vector3.UP) <= 46*(PI/100):
				#isonfloor = true
				#floornormal = normal
		##print(str(normal.angle_to(Vector3.UP)) + " vs " + str(46*(PI/100)))
	#
	#var resistance = floornormal if isonfloor else Vector3.UP
	#currvelocity += resistance * get_gravity() * 2
	#linear_velocity += currvelocity
	

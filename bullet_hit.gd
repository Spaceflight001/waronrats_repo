extends Node3D

@onready var main = get_tree().root.get_child(0)
@onready var effpool = main.effpool

@export var material: Material
var lifetime = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$Shards.draw_pass_1.set_material(material)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	lifetime += delta
	if lifetime > 2:
		lifetime = 0
		set_process(false)
		effpool.append(self)

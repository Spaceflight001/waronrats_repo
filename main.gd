extends Node

signal feed
var timer = 0.0

@export var objpool: Array = []
@export var effpool: Array = []

@onready var rat = load("res://rat.tscn")

func  _input(event: InputEvent) -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer > 3:
		timer = 0.0
		var ratclone = rat.instantiate()
		add_child(ratclone, true)
		ratclone.health = 100.0
		ratclone.position = Vector3(0,5,0)
		

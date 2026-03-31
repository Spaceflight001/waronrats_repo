extends Label

var lifetime: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if name != "FeedLabel":
		lifetime += delta
	if lifetime > 5:
		modulate.a -= 0.5*delta
		if modulate.a <= 0:
			free()

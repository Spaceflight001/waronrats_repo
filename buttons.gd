extends CanvasLayer

@export var currenttool: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $Sideblack.modulate.a > 0:
		$Sideblack.modulate.a = move_toward($Sideblack.modulate.a, 0, delta*0.2)
	
	var character = get_tree().root.get_child(0).find_child("Character")
	if character:
		$HealthBar.value = character.health
		
		if currenttool:
			$Label.text = str(currenttool.ammo)
		else:
			$Label.text = "No Gun"
	$FPSLabel.text = "FPS: " + str(Engine.get_frames_per_second())


func _on_main_feed(message: String, color: Color = Color(1,1,1)) -> void:
	for button in get_children():
		if button.name.begins_with("FeedLabel") and button.name != "FeedLabel":
			button.position.y += 20
	var clone = $FeedLabel.duplicate()
	add_child(clone, true)
	clone.text = message
	clone.modulate = color
	clone.label_settings.outline_color = color * Color(1,1,1,0.5)

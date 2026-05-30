extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	modulate = lerp(modulate,Color.WHITE,0.1)
	$Srpite.scale = lerp($Srpite.scale,Vector2(1,1),0.1)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if Global.player.amountOfFlaps <= 0:
		return
	$AudioStreamPlayer.play()
	modulate = Color(18.892, 18.892, 18.892, 1.0)
	$Srpite.scale = Vector2(2,2)
	Global.player.amountOfFlaps = Global.player.FLAPRESETAMOUNT
	Global.player.updateFlapCount()

extends Camera2D

func _ready() -> void:
	Global.connect("shrimpFound",butt)

func tweenCamera(newPos :Vector2i) -> void:
	get_tree().paused = true
	var tween :Tween = create_tween()
	tween.tween_property(self,"global_position",Vector2(newPos * Vector2i(640,480)),0.5)
	await tween.finished
	get_tree().paused = false
	
func butt() -> void:
	$Label.text = "honey walnut shrimp located: " + str(Global.shrimpCollected) + " / " + str(Global.globalShrimpCount)

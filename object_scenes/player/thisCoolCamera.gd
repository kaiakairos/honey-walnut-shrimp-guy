extends Camera2D

func tweenCamera(newPos :Vector2i) -> void:
	get_tree().paused = true
	var tween :Tween = create_tween()
	tween.tween_property(self,"global_position",Vector2(newPos * Vector2i(640,640)),0.5)
	await tween.finished
	get_tree().paused = false
	

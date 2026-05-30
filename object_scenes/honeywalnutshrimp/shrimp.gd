extends Node2D

var isFollowing :bool = false

func _ready() -> void:
	Global.globalShrimpCount += 1

func _process(delta: float) -> void:
	$Sprite.offset.y = sin((Time.get_ticks_msec() + global_position.x) * 0.01) * 3.0
	$Sprite.rotation = sin((Time.get_ticks_msec() + global_position.x) * 0.005) * PI * 0.1
	
	if isFollowing:
		$Sprite.global_position = lerp($Sprite.global_position,Global.player.global_position,0.3)
		
		if Global.player.is_on_floor() and (Global.player.sprite.animation == "idle" or Global.player.sprite.animation == "walk" or Global.player.sprite.animation == "duck"):
			Global.addShrimp()
			queue_free()
		
		if Global.player.dead:
			isFollowing = false
		
	else:
		$Sprite.position = lerp($Sprite.position,Vector2.ZERO,0.3)
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	#Global.addShrimp()
	#queue_free()
	isFollowing = true

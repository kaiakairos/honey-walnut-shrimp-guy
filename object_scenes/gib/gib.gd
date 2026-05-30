extends CharacterBody2D

var tick :float = 0.0

func _ready() -> void:
	$Gib.rotation = randf_range(-PI,PI)
	

func _process(delta: float) -> void:
	
	var onFloor :bool = is_on_floor()
	
	if onFloor:
		velocity.x = lerp(velocity.x,0.0,0.06)
	velocity.y += 1000 * delta
	
	var velSave :Vector2 = velocity
	
	move_and_slide()
	
	if !onFloor and is_on_floor():
		velocity.y = -1.0 * velSave.y
	
	$Gib.rotate(velocity.x *delta)
	tick += delta
	
	
	if tick > 1.0:
		$Gib.scale = lerp($Gib.scale,Vector2.ZERO,0.02)
	
	if tick > 3.0:
		queue_free()

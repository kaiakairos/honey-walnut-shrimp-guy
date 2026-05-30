extends Node2D


var tickTimer :float = 50.0

func _process(delta: float) -> void:
	$Label9.text = str(Global.globalShrimpCount - Global.shrimpCollected) + " shrimp remaining..."
	tickTimer -= delta
	
	if Global.shrimpCollected >= Global.globalShrimpCount:
		$LockedDoor/StaticBody2D/CollisionShape2D.disabled = true
		$LockedDoor.hide()
		$Label3.text = "congrats you have found my glorious
		HONEY WALKNUT SHRIMP. 
		proceed to the left for your grand prize"

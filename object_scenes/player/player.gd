extends CharacterBody2D

@export var wingOrigin :Node2D
@export var wingSprite1 :Sprite2D
@export var wingSprite2 :Sprite2D
@export var sprite :AnimatedSprite2D


const JUMPFORCE :int = 320
const GRAVITY :int = 1200
const SPEED :int = 200
const GROUNDEDACCEL :float = 0.5
const GROUNDEDDECEL :float = 0.1

const AIRACCEL :float = 0.1
const AIRDECEL :float = 0.06

const ROTATEMULT :float = 0.05

var jumpBuffer :float = 0.0
var coyoteBuffer :float = 0.0
var lastFloorRemembered : float = 0.0

var duckLastFrame :bool = false
var isDucking :bool = false

var DUCKSPEEDBOOST :float = 6.0

var amountOfFlaps :int = 1
const FLAPRESETAMOUNT :int = 6

var takingFallDamage :bool = false

var hurtFromFall :bool = false
var hurtTicks: float = 0.0

var cameraPosition :Vector2i = Vector2i.ZERO

var respawnPoint :Vector2 = Vector2.ZERO
var dead :bool = false
@onready var gibScene :PackedScene = load("res://object_scenes/gib/gib.tscn")

func _ready() -> void:
	respawnPoint = global_position

func _process(delta: float) -> void:
	
	if dead:
		lerpWingsSpinning(delta)
		return
	
	lerpScale(delta)
	
	var isOnFloor :bool = is_on_floor()
	
	
	
	if hurtFromFall:
		lerpWingsSpinning(delta)
		
		velocity.y += GRAVITY * delta
		velocity.x = lerp(velocity.x,0.0,getLerpDeltaTimed(delta,AIRDECEL))
		
		move_and_slide()
		
		modulate = lerp(modulate,Color.WHITE,getLerpDeltaTimed(delta,0.2))
		doCameraPosition()
		return
	
	if takingFallDamage:
		isOnFloor = false
	
	duckLastFrame = isDucking
	isDucking = doDuck(delta,isOnFloor)
	if isDucking:
		$CollisionShape2D.position.y = 2.5
		$CollisionShape2D.shape.size.y = 7.0
	else:
		$CollisionShape2D.position.y = -1.0
		$CollisionShape2D.shape.size.y = 14.0
	
	var dir:float = movement(delta,isOnFloor)
	
	processAnimation(delta,isOnFloor,dir)
	
	doCameraPosition()

func movement(delta:float,isOnFloor:bool) -> float:
	
	
	
	if isOnFloor:
		lastFloorRemembered = position.y
		coyoteBuffer = 0.08 #(abs(1000.0  - velocity.x) * 0.00012)
		amountOfFlaps = FLAPRESETAMOUNT
		updateFlapCount()
		
		if isDucking and !duckLastFrame: # just pressed DUCK
			setScale(Vector2(1.2,0.8))
	
	if Input.is_action_pressed("jump"):
		velocity.y += GRAVITY * delta * 0.6
	else:
		velocity.y += GRAVITY * delta
	
	if Input.is_action_just_pressed("jump"):
		jumpBuffer = 0.1
	if coyoteBuffer > 0.0 and jumpBuffer > 0.0:
		velocity.y = JUMPFORCE * -1
		position.y = lastFloorRemembered
		jumpBuffer = -1.0
		setScale(Vector2(0.6,1.4))
	elif jumpBuffer > 0.0 and amountOfFlaps > 0:
		amountOfFlaps -= 1
		updateFlapCount()
		velocity.y -= JUMPFORCE * 0.7
		jumpBuffer = -1.0
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("littleJump")
		setScale(Vector2(0.75,1.25))
	elif Input.is_action_pressed("jump") and !isOnFloor and amountOfFlaps > 0:
		velocity.y = min(velocity.y,60.0)
	
	if velocity.y > 61.0:
		if amountOfFlaps > 0:
			lerpWingsFalling(delta)
		else:
			lerpWingsSpinning(delta)
	elif velocity.y > 59.0:
		lerpWingsGlide(delta)
		
	
	jumpBuffer -= delta
	coyoteBuffer -= delta
	
	
	
	var dir :float = Input.get_axis("move_left","move_right")
	
	
	
	var properAccel :float = GROUNDEDACCEL # get proper lerp time to use
	
	if isDucking:
		properAccel = 0.01
		#print("offisafen")
	
	if isOnFloor and roundi(dir) == 0:
		print(dir)
		properAccel = GROUNDEDDECEL
	elif isOnFloor and roundi(dir) != 0:
		pass
	else:
		properAccel = AIRACCEL
		if roundi(dir) == 0.0:
			properAccel = AIRDECEL
			if takingFallDamage:
				properAccel = 0.0
	#print(properAccel)
	
	var realTargetSpeed :float = dir * SPEED
	
	if roundi(dir) == 0 and !isDucking:
		realTargetSpeed = 0.0
	else:
		if isDucking:
			if abs(velocity.x) < abs(dir * SPEED * DUCKSPEEDBOOST):
				realTargetSpeed = dir * SPEED * DUCKSPEEDBOOST
				if isDucking and !duckLastFrame: # just pressed DUCK
					velocity.x = dir * SPEED * 2.0
	
		if !isOnFloor and abs(velocity.x) > abs(dir * SPEED * 1.2):
			if (roundi(dir) == -1 and velocity.x < 0.0) or (roundi(dir) == 1 and velocity.x > 0.0):
				realTargetSpeed = velocity.x
			else:
				realTargetSpeed = 0.0
	
	
	
	
	velocity.x = lerp(velocity.x,realTargetSpeed,getLerpDeltaTimed(delta,properAccel))
	
	var velSave :Vector2 = velocity
	
	move_and_slide()
	velocity.x = get_real_velocity().x
	
	
	if !isOnFloor and is_on_floor() and amountOfFlaps <= 0:
		if velSave.y > 500.0:
			velocity.y = velSave.y * -0.8
			takingFallDamage = true
			setScale(Vector2(0.7,1.2)) # bounce
		else:
			hurtFromFall = true
			takingFallDamage = false
			setScale(Vector2(1.4,0.6))
			sprite.offset = Vector2(0.0,-10.0)
			sprite.position = Vector2(0.0,6.0)
	
	return dir

func doDuck(delta:float,isOnFloor:bool) -> bool:
	if !isOnFloor and (!$duckingCast.is_colliding() and !$duckingCast2.is_colliding()):
		return false
	
	if Input.is_action_pressed("duck") or $duckingCast.is_colliding() or $duckingCast2.is_colliding():
		return true
	return false

func getLerpDeltaTimed(delta:float,typical:float) -> float:
	var value :float = ( ( 0.016666 * log(2) ) / (log( abs(typical - 1.0) ) ) ) * -1
	return 1.0 - pow(2.0,(-delta/value))

func doCameraPosition() -> void:
	$Camera2D.global_position = cameraPosition * Vector2i(640,640)
	var worldPosition :Vector2i = Vector2i(global_position / 640.0)
	if global_position.x < 0:
		worldPosition.x -= 1
	if global_position.y < 0:
		worldPosition.y -= 1
	
	if worldPosition == cameraPosition:
		return
	
	cameraPosition = worldPosition
	$Camera2D.tweenCamera(cameraPosition)
	
	
	

func processAnimation(delta:float,isOnFloor:bool,dir:float) -> void:
	
	if hurtFromFall:
		
		playAnim("hurtFall")
		wingOrigin.scale.y = 0.5
		await get_tree().create_timer(1.0).timeout
		wingOrigin.scale.y = 1.0
		hurtFromFall = false
		velocity.y = -130.0
		return
	
	
	if takingFallDamage:
		playAnim("roll")
		sprite.rotate(delta*velocity.x * ROTATEMULT)
		return
	
	if isOnFloor:
		if roundi(dir) == 0:
			playAnim("idle")
		else:
			playAnim("walk")
			
			sprite.flip_h = dir < 0.0
			wingOrigin.scale.x = dir
			
			
		if isDucking:
			playAnim("duck")
		
		lerpWingsIdle(delta)
		
		
	else:
		
		
		if velocity.y > 61.0 and amountOfFlaps <= 0:
			playAnim("roll")
			sprite.rotate(delta*ROTATEMULT*velocity.x)
		elif velocity.y > 59.0 and Input.is_action_pressed("jump"):
			playAnim("glide")
		else:
			playAnim("jump")


func lerpWingsIdle(delta:float) -> void:
	wingSprite1.position = lerp(wingSprite1.position,Vector2(-4.0,-6.0),getLerpDeltaTimed(delta,0.2))
	wingSprite1.scale = lerp(wingSprite1.scale,Vector2(0.575,0.24),getLerpDeltaTimed(delta,0.2))
	wingSprite1.rotation = lerp_angle(wingSprite1.rotation,deg_to_rad(-50.4),getLerpDeltaTimed(delta,0.2))
		
	wingSprite2.position = lerp(wingSprite2.position,Vector2(-2.0,-6.0),getLerpDeltaTimed(delta,0.2))
	wingSprite2.scale = lerp(wingSprite2.scale,Vector2(0.415,0.375),getLerpDeltaTimed(delta,0.2))
	wingSprite2.rotation = lerp_angle(wingSprite2.rotation,deg_to_rad(52.4),getLerpDeltaTimed(delta,0.2))
		
		

func lerpWingsFalling(delta:float) -> void:
	wingSprite1.position = lerp(wingSprite1.position,Vector2(-4.0,-6.0),getLerpDeltaTimed(delta,0.2))
	wingSprite1.scale = lerp(wingSprite1.scale,Vector2(0.785,0.895),getLerpDeltaTimed(delta,0.2))
	wingSprite1.rotation = lerp_angle(wingSprite1.rotation,deg_to_rad(-9.8),getLerpDeltaTimed(delta,0.2))
		
	wingSprite2.position = lerp(wingSprite2.position,Vector2(0.0,-4.0),getLerpDeltaTimed(delta,0.2))
	wingSprite2.scale = lerp(wingSprite2.scale,Vector2(0.69,1.0),getLerpDeltaTimed(delta,0.2))
	wingSprite2.rotation = lerp_angle(wingSprite2.rotation,deg_to_rad(0.0),getLerpDeltaTimed(delta,0.2))

func lerpWingsGlide(delta:float) -> void:
	wingSprite1.position = lerp(wingSprite1.position,Vector2(-4.0,-6.0),getLerpDeltaTimed(delta,0.2))
	wingSprite1.scale = lerp(wingSprite1.scale,Vector2(0.785,0.895),getLerpDeltaTimed(delta,0.2))
	wingSprite1.rotation = lerp_angle(wingSprite1.rotation,deg_to_rad(-32.9),getLerpDeltaTimed(delta,0.2))
		
	wingSprite2.position = lerp(wingSprite2.position,Vector2(0.0,-4.0),getLerpDeltaTimed(delta,0.2))
	wingSprite2.scale = lerp(wingSprite2.scale,Vector2(0.69,1.0),getLerpDeltaTimed(delta,0.2))
	wingSprite2.rotation = lerp_angle(wingSprite2.rotation,deg_to_rad(28.8),getLerpDeltaTimed(delta,0.2))

func lerpWingsSpinning(delta:float) -> void:
	wingSprite1.position = lerp(wingSprite1.position,Vector2(-4.0,8.0),getLerpDeltaTimed(delta,1.0))
	wingSprite1.scale = lerp(wingSprite1.scale,Vector2(0.0,0.0),getLerpDeltaTimed(delta,0.2))
	wingSprite1.rotation = lerp_angle(wingSprite1.rotation,deg_to_rad(-50.4),getLerpDeltaTimed(delta,0.2))
		
	wingSprite2.position = lerp(wingSprite2.position,Vector2(-2.0,8.0),getLerpDeltaTimed(delta,1.0))
	wingSprite2.scale = lerp(wingSprite2.scale,Vector2(0.0,0.0),getLerpDeltaTimed(delta,0.2))
	wingSprite2.rotation = lerp_angle(wingSprite2.rotation,deg_to_rad(52.4),getLerpDeltaTimed(delta,0.2))
		

func playAnim(anim:String) -> void:
	if sprite.animation != anim:
		sprite.play(anim)
		if anim != "roll":
			sprite.rotation = 0.0
			wingOrigin.rotation = 0.0

func updateFlapCount() -> void:
	var fake :int = amountOfFlaps
	if fake > 4:
		fake = 4
	var percentile :float = float(fake) / 4.0
	modulate = Color(1.0,percentile,percentile)
	
	
	if amountOfFlaps <= 0:
		sprite.offset = Vector2(0.0,0.0)
		sprite.position = Vector2(0.0,-4.0)

func lerpScale(delta:float) -> void:
	sprite.scale = lerp(sprite.scale,Vector2(1,1),getLerpDeltaTimed(delta,0.2))

func setScale(sca:Vector2) -> void:
	sprite.scale = sca


func _on_area_2d_body_entered(body: Node2D) -> void:
	die()



func die() -> void:
	dead = true
	
	hide()
	for i in range(8):
		var newGib :CharacterBody2D= gibScene.instantiate()
		newGib.velocity = Vector2(200,0).rotated( randf_range(-PI,PI)) + velocity
		newGib.global_position = global_position
		get_parent().call_deferred("add_child",newGib)
	
	velocity = Vector2.ZERO
	await get_tree().create_timer(1.0).timeout
	show()
	global_position = respawnPoint
	doCameraPosition()
	dead = false
	
	amountOfFlaps = 0
	takingFallDamage = true
	#hurtFromFall = true
	#processAnimation(0.00166,false,0.0)
	


func _on_checkpoint_body_entered(body: Node2D) -> void:
	respawnPoint = global_position
	body.get_parent().play()

extends Node

var shrimpCollected :int = 0
signal shrimpFound

var sfx :AudioStreamPlayer = AudioStreamPlayer.new()

var player :CharacterBody2D

var globalShrimpCount :int = -768

func _ready() -> void:
	sfx.stream = load("res://sound/ahhh.ogg")
	add_child(sfx)

func addShrimp() -> void:
	shrimpCollected += 1
	sfx.play()
	emit_signal("shrimpFound")

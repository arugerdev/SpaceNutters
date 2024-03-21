extends Node3D

@onready var animation_player = $AnimationPlayer

var opened = false
@export var canChange = true



func toogle_door():
	if !canChange:
		return
		
	opened = !opened
	if opened:
		animation_player.play("open_door")
	elif !opened:
		animation_player.play("close_door")


func _on_animation_player_animation_finished(anim_name):
	canChange = true

func _on_animation_player_animation_started(anim_name):
	canChange = false

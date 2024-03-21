extends CSGBox3D

@onready var animation_player = $AnimationPlayer
@onready var door = $"../Door"

@rpc("call_local", "any_peer")
func fps_interaction():
	animation_player.play("pressed_button")
	door.toogle_door()

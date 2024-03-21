extends Node3D

@onready var ray_cast_3d = $RayCast3D
@onready var cross_hair_ui = $CrossHair_UI
@onready var player = $"../../../.."

func _process(delta):
	if ray_cast_3d.is_colliding():
		if ray_cast_3d.get_collider().has_method("fps_interaction"):
			cross_hair_ui.set_Target_Scale(12.0)
			
			if Input.is_action_just_pressed("interaction"):
				ray_cast_3d.get_collider().fps_interaction.rpc()
				
		elif ray_cast_3d.get_collider().has_method("set_infectation") && ray_cast_3d.get_collider() != player:
			cross_hair_ui.set_Target_Scale(12.0)
			if Input.is_action_just_pressed("shoot"):
				if player.infected:
					ray_cast_3d.get_collider().set_infectation.rpc(true)
					player.set_infectation.rpc(false)
		else:
			cross_hair_ui.reset_Target_Scale()
		
	elif not cross_hair_ui.target_scale == 0.0:
		cross_hair_ui.reset_Target_Scale()
	

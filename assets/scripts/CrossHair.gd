extends Control

@onready var line_2d = $CrossHair/Line2D

const lerp_speed = 12.0
@export var target_scale = 6.0
var default_scale = 0.0

func _ready():
	default_scale = target_scale

func _process(delta):
	line_2d.width = lerp(line_2d.width, target_scale, delta * lerp_speed)

func set_Target_Scale(newVale):
	target_scale = newVale
	
func reset_Target_Scale():
	target_scale = default_scale

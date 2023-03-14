extends Node

var points:Array

func _ready():
	points.append(Draw3D.point(Vector3.ZERO), 0.05)
	points.append(Draw3D.point(Vector3.FORWARD), 0.05)
	
	
	
func _process(delta):
	pass
	

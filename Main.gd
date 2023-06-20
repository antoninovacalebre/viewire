extends Node

var points:Array
var lines:Array

var current_paths:Array

var mouse_line: MeshInstance3D

var colors:Array

var files_counter := 0

@export var default_camera_pos :Vector3= Vector3(0.0, 0.0, 40.0)
@export var point_size := 0.025

func _ready() -> void:
	colors.append(Color.LIGHT_GREEN)
	colors.append(Color.LIGHT_CORAL)
	colors.append(Color.LIGHT_CYAN)
	colors.append(Color.LIGHT_GOLDENROD)
	colors.append(Color.LIGHT_STEEL_BLUE)
	colors.append(Color.LIGHT_SLATE_GRAY)
	
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Clear"):
		_clear_points_and_lines()
		
	if event.is_action_pressed("Open File"):
		_popup_file_dialog()
		
	if event.is_action_pressed("Toggle Help"):
		$Control/TextEdit.visible = not $Control/TextEdit.visible
		
	if event.is_action_pressed("Reset Camera"):
		_center_camera()
		
	if event.is_action_pressed("Reload"):
		var paths = [] + current_paths
		_clear_points_and_lines()
		_on_file_dialog_files_selected(paths)
	
func _clear_points_and_lines()->void:
	for p in points:
		p.queue_free()
	points.clear()
		
	for l in lines:
		l.queue_free()
	lines.clear()
	
	files_counter = 0
	current_paths.clear()
	
	
func _popup_file_dialog() -> void:
	$FileDialog.popup()
	
func _center_camera():
	
	var center = Vector2(0.0, 0.0)
	
	var max_x = -1e9
	var min_x = 1e9
	var max_y = -1e9
	var min_y = 1e9
	
	for point in points:
		center.x += point.position.x
		center.y += point.position.y
		
		max_x = max(max_x, point.position.x)
		min_x = min(min_x, point.position.x)
		
		max_y = max(max_y, point.position.y)
		min_y = min(min_y, point.position.y)
		
	center /= len(points)
	
	var distance = 2 * max(max_x-min_x, max_y-min_y) * 0.5 / tan(deg_to_rad($Camera.fov/2))
	
	$Camera.transform = Transform3D(Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(center.x, center.y, distance))

func _on_file_dialog_files_selected(paths):
	for path in paths:
		current_paths.append(path)
		
		var nlines = 0
		
		var file = FileAccess.open(path, FileAccess.READ)
		
		# Parsing
		
		var nwires = int(file.get_line())
		
		for j in nwires:
			var line = file.get_line()
			line = line.replace("\t", " ")
			line = line.split(" ", false)
			
			if len(line) <= 2:
				nlines = int(line[0])
			else:
				line = file.get_line()
				line = line.replace("\t", " ")
				line = line.split(" ", false)
				nlines = int(line[0])
				
			var first_point = len(points)
			
			for ii in nlines:
				var i = first_point + ii
				line = file.get_line()
				line = line.replace("\t", " ")
				line = line.split(" ", false)
				
				var pv3 = Vector3(float(line[0]), float(line[1]), float(line[2]))
				points.append(Draw3d.point(pv3, point_size))
				
				if ii > 0:
					var p1 = points[i].position
					var p2 = points[i-1].position
					
					var is_via = abs(p1.z - p2.z) > 1e-9
					var same_xy = Vector2(p1.x, p1.y).distance_to(Vector2(p2.x, p2.y)) < 1e-9
					
					if  is_via and !same_xy:
						lines.append(Draw3d.line(p1, p2, Color.RED))
					else:
						lines.append(Draw3d.line(p1, p2, colors[files_counter]))
						
					if ii == (nlines-1):
						var same_as_first = Vector2(p1.x, p1.y).distance_to(Vector2(points[first_point].position.x, points[first_point].position.y)) < 1e-9
						
						if !same_as_first:
							lines.append(Draw3d.line(points[i].position, points[first_point].position, Color.FUCHSIA))
					
		$Control/TextEdit.visible = false
		
		if files_counter == 0:
			_center_camera()
		
		files_counter += 1

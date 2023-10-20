extends Node

var points:Array
var lines:Array

var current_paths:Array

var mouse_line: MeshInstance3D

var colors:Array
var background_colors:Array
var bkg_idx := -1

var files_counter := 0
var wires_counter := 0
var reloading := false
var smallest_segment_length := INF

@export var default_camera_pos :Vector3= Vector3(0.0, 0.0, 40.0)
@export var default_point_size := 0.025

func _ready() -> void:
	reloading = false
	
	# color cycle is shamelessly copied from matplotlib
	# https://matplotlib.org/stable/users/prev_whats_new/dflt_style_changes.html
	colors.append(Color.hex(0x1f77b4ff))
	colors.append(Color.hex(0xff7f0eff))
	colors.append(Color.hex(0x2ca02cff))
	colors.append(Color.hex(0xd62728ff))
	colors.append(Color.hex(0x9467bdff))
	colors.append(Color.hex(0x8c564bff))
	colors.append(Color.hex(0xe377c2ff))
	colors.append(Color.hex(0x7f7f7fff))
	colors.append(Color.hex(0xbcbd22ff))
	colors.append(Color.hex(0x17becfff))
	
	background_colors.append(Color.hex(0x4d4d4dff))
	background_colors.append(Color.hex(0xffffffff))
	
	_cycle_background_color()
	
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Clear"):
		_clear_points_and_lines()
		
	if event.is_action_pressed("Open File"):
		_popup_file_dialog()
		
	if event.is_action_pressed("Cycle Background Color"):
		_cycle_background_color()
		
	if event.is_action_pressed("Toggle Help"):
		$Control/TextEdit.visible = not $Control/TextEdit.visible
		
	if event.is_action_pressed("Reload"):
		reloading = true
		var paths = [] + current_paths
		_clear_points_and_lines()
		_on_file_dialog_files_selected(paths)
		reloading = false
	elif event.is_action_pressed("Reset Camera"):
		_center_camera() 
	
func _clear_points_and_lines()->void:
	for p in points:
		p.queue_free()
	points.clear()
		
	for l in lines:
		l.queue_free()
	lines.clear()
	
	files_counter = 0
	wires_counter = 0
	current_paths.clear()

func _cycle_background_color() -> void:
	bkg_idx = (bkg_idx + 1) % len(background_colors)
	RenderingServer.set_default_clear_color(background_colors[bkg_idx])
	for point in points:
		point.mesh.material.albedo_color = background_colors[bkg_idx].inverted()
	
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
			
			if line[0].is_valid_int():
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
				points.append(Draw3d.point(pv3, default_point_size, background_colors[bkg_idx].inverted()))
				
				if ii > 0:
					var p1 = points[i].position
					var p2 = points[i-1].position
					
					var is_via = abs(p1.z - p2.z) > 1e-9
					var same_xy = Vector2(p1.x, p1.y).distance_to(Vector2(p2.x, p2.y)) < 1e-9
					
					if  is_via and !same_xy:
						lines.append(Draw3d.line(p1, p2, Color.RED))
					else:
						lines.append(Draw3d.line(p1, p2, colors[wires_counter % len(colors)]))
					
					var segment_length = p1.distance_to(p2)
					if segment_length > 1e-12:
						smallest_segment_length = min(smallest_segment_length, segment_length)
					else:
						print_debug("Found segment of size less than 1e-12")
						
					if ii == (nlines-1):
						var same_as_first = p1.distance_to(points[first_point].position) < 1e-9
						
						if !same_as_first:
							lines.append(Draw3d.line(points[i].position, points[first_point].position, Color.FUCHSIA))
							smallest_segment_length = min(smallest_segment_length, points[i].position.distance_to(points[first_point].position))
			
			wires_counter += 1		
			
		$Control/TextEdit.visible = false
		
		_resize_points()
		
		if files_counter == 0 and not reloading:
			_center_camera()
		
		files_counter += 1

func _resize_points() -> void:
	for point in points:
		point.mesh.size = Vector3(1.0, 1.0, 1.0) * smallest_segment_length / 10.0

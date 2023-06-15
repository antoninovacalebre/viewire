extends Node

func line(pos1: Vector3, pos2: Vector3, color = Color.WHITE_SMOKE) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()	
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	get_tree().get_root().add_child.call_deferred(mesh_instance)
	
	return mesh_instance


func point(pos:Vector3, radius = 0.05, color = Color.WHITE_SMOKE) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	
	var cube_mesh := BoxMesh.new()
	var material := ORMMaterial3D.new()
		
	mesh_instance.mesh = cube_mesh
	mesh_instance.position = pos
	
	cube_mesh.material = material
	cube_mesh.size = Vector3(radius*2, radius*2, radius*2)
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	get_tree().get_root().add_child.call_deferred(mesh_instance)
	
	return mesh_instance
	


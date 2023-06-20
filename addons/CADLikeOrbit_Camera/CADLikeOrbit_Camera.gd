class_name CADLikeOrbit_Camera extends Camera3D

@export var ZOOMSPEED = 0.15
@export var ROTATIONSPEED = 0.5 * PI/180 #rad/screenpixel
@export var DEFAULTFOCALDIST = 10
@export var DEFAULTPANDIST = 10
@export var RAYLENGTH = 100000
@export var USEFOCALPOINTSPHERE = true
@export var FocalPointSphereRadius = 0.2
@export_color_no_alpha var FocalPointSphereColor = Color.RED
@export var IfNoObjPickedRotateAroundOrigin = false
@export var InputMapActionZoom = "Zooming"
@export var InputMapActionPan = "Panning"
@export var RotateUsingZoomPlusPan = true
@export var InputMapActionRotate = "Rotating"

signal CamZoom_start
signal CamZoom_stop
signal CamPan_start
signal CamPan_stop
signal CamRotate_start
signal CamRotate_stop

var CamAction_ZOOM = false
var CamAction_ROTATE = false
var CamAction_PAN = false
var act_pos2d = Vector2(0,0)
var last_pos2d = Vector2(0,0)
var actpandist = 0
var focalpoint = Vector3(0,0,0)


func _ready():
	
	#Add needed Child Objects (Not Visible in the Scene-Tree)
	var newRayCast = RayCast3D.new()
	newRayCast.name = "RayCast"
	add_child(newRayCast)
	newRayCast.set_owner(self)
	
	var newSphere = CSGMesh3D.new()
	newSphere.name = "FocalpointSphere"
	newSphere.mesh = SphereMesh.new()
	newSphere.scale = Vector3(FocalPointSphereRadius, FocalPointSphereRadius, FocalPointSphereRadius)
	newSphere.mesh.material = StandardMaterial3D.new()
	newSphere.mesh.material.albedo_color = FocalPointSphereColor
	add_child(newSphere)
	newSphere.set_owner(self)
	
	#No Action a Scene-Start
	CamAction_ZOOM = false
	CamAction_PAN = false
	CamAction_ROTATE = false
	
	#Check for InputMap Errors
	if len(InputMap.action_get_events(InputMapActionZoom)) == 0 or \
	   len(InputMap.action_get_events(InputMapActionPan)) == 0 or \
	   (len(InputMap.action_get_events(InputMapActionRotate)) == 0 and not RotateUsingZoomPlusPan):
			print(self.name + " Error: Can't find defined InputMap Actions!")
			var sol = "Solution: Change the Input Map Parameters or add "
			sol += "new InputMap-Action's with the defined Names: %s, %s, %s" 
			sol = sol % [InputMapActionZoom, InputMapActionPan, InputMapActionRotate]
			print(sol)	
			
func Zooming():
	if last_pos2d != Vector2(0,0):
		var Zoomdist = (last_pos2d[1]-act_pos2d[1])*ZOOMSPEED
		translate_object_local(Vector3(0,0,Zoomdist))

func Panning():

	#is there a t-1 Action? No, then get Focalpoint
	if last_pos2d == Vector2(0,0):

		#Orient RayCast 
		var RayCastPose = global_transform.inverse()
		RayCastPose.origin = Vector3(0,0,0)
		$RayCast.transform = RayCastPose
		$RayCast.force_update_transform()

		#Get 3d-Focalpoint for t-1
		var raynormal = project_ray_normal(act_pos2d) 
		#$RayCast.cast_to = raynormal * RAYLENGTH
		$RayCast.target_position = raynormal * RAYLENGTH
		$RayCast.force_raycast_update()
		if $RayCast.is_colliding():
			focalpoint = $RayCast.get_collision_point()
		else:
			focalpoint = global_transform.origin + raynormal.normalized() * DEFAULTPANDIST

		#Distnace/Vectorlength from Camorigin to Focalpoint
		actpandist = (focalpoint - global_transform.origin).length()

	else: 
		#Calc new Cam origin
		var focalpose = global_transform
		focalpose.origin = focalpoint
		var raynormal = project_ray_normal(act_pos2d) #Ray in Global Csys
		var raynormal_refCam = global_transform.basis.inverse() * raynormal
		global_transform.origin = focalpose * -Transform3D.IDENTITY.translated(raynormal_refCam.normalized() * actpandist).origin

		#Set Focalpointsphere if activated
		if USEFOCALPOINTSPHERE:
			$FocalpointSphere.global_transform.origin = (global_transform * Transform3D.IDENTITY.translated(raynormal_refCam.normalized() * actpandist)).origin
			$FocalpointSphere.visible = true


func Rotating():

	#is there a t-1 Action? No, then get Focalpoint
	if last_pos2d == Vector2(0,0):

		#Orient RayCast 
		var RayCastPose = global_transform.inverse()
		RayCastPose.origin = Vector3(0,0,0)
		$RayCast.transform = RayCastPose
		$RayCast.force_update_transform()

		#Get 3d-Focalpoint for t-1
		var raynormal = project_ray_normal(act_pos2d) 
		$RayCast.target_position = raynormal * RAYLENGTH
		$RayCast.force_raycast_update()
		if $RayCast.is_colliding():
			focalpoint = $RayCast.get_collision_point()
		else:
			if IfNoObjPickedRotateAroundOrigin:
				focalpoint = Vector3(0,0,0) # if not Object Picked then use Worldspace Origin as focalpoint
			else:
				focalpoint = (global_transform * Transform3D.IDENTITY.translated(Vector3(0,0,-DEFAULTFOCALDIST))).origin

		#Set Focalpointsphere if activated
		if USEFOCALPOINTSPHERE:
			$FocalpointSphere.global_transform.origin = focalpoint
			$FocalpointSphere.visible = false

	else: #Rotate

		#Calc new Camtransformation
		var focalpose = global_transform
		focalpose.origin = focalpoint
		var VFocalP2Cam = (focalpose.inverse() * global_transform).origin

		global_transform = focalpose * \
					Transform3D.IDENTITY.rotated(Vector3(1,0,0), (last_pos2d[1]-act_pos2d[1])*ROTATIONSPEED) * \
					Transform3D.IDENTITY.rotated(Vector3(0,1,0), (last_pos2d[0]-act_pos2d[0])*ROTATIONSPEED) * \
					Transform3D.IDENTITY.translated(VFocalP2Cam)


# warning-ignore:unused_argument
func _process(delta):

	#Match Input-Action to Camera-Operation
	if Input.is_action_just_pressed(InputMapActionZoom):
		emit_signal("CamZoom_start")
		CamAction_ZOOM = true
		last_pos2d = Vector2(0,0)
	if Input.is_action_just_released(InputMapActionZoom):
		emit_signal("CamZoom_stop")
		CamAction_ZOOM = false

	if Input.is_action_just_pressed(InputMapActionPan):
		emit_signal("CamPan_start")
		CamAction_PAN = true
		last_pos2d = Vector2(0,0)
	if Input.is_action_just_released(InputMapActionPan):
			emit_signal("CamPan_stop")
			CamAction_PAN = false
			if $FocalpointSphere.visible:
				$FocalpointSphere.visible = false

	#Rotate by using the Key-Combination of Zoom and Pan, or by using a 
	#seperate InputMap-Event
	if RotateUsingZoomPlusPan:

		if Input.is_action_pressed(InputMapActionPan) and \
		   Input.is_action_just_pressed(InputMapActionZoom):

			emit_signal("CamRotate_start")
			CamAction_ROTATE = true

			if CamAction_ZOOM:
				emit_signal("CamZoom_stop")
				CamAction_ZOOM = false
			elif CamAction_PAN:
				emit_signal("CamPan_stop")
				CamAction_PAN = false

			last_pos2d = Vector2(0,0)

		if CamAction_ROTATE and (Input.is_action_just_released(InputMapActionPan) or \
								 Input.is_action_just_released(InputMapActionZoom)):

				emit_signal("CamRotate_stop")
				CamAction_ROTATE = false

				if Input.is_action_pressed(InputMapActionPan):
					emit_signal("CamPan_start")
					CamAction_PAN = true	

				if Input.is_action_pressed(InputMapActionZoom):
					emit_signal("CamZoom_start")
					CamAction_ZOOM = true	
					last_pos2d = Vector2(0,0)

				if $FocalpointSphere.visible:
					$FocalpointSphere.visible = false
	else:

		if Input.is_action_just_pressed(InputMapActionRotate):
			emit_signal("CamRotate_start")
			CamAction_ROTATE = true
			last_pos2d = Vector2(0,0)

		if Input.is_action_just_released(InputMapActionRotate):
				emit_signal("CamRotate_stop")
				CamAction_ROTATE = false
				if $FocalpointSphere.visible:
					$FocalpointSphere.visible = false

	act_pos2d = get_viewport().get_mouse_position()

	if CamAction_ZOOM:
		Zooming()
	if CamAction_PAN:
		Panning()
	if CamAction_ROTATE:
		Rotating()

	last_pos2d = act_pos2d

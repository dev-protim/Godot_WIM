extends XROrigin3D

class_name XRBootstrap

@export var xr_interface_type: String = 'OpenXR'
@export var xr_debug_label: Label3D = null
@export var xr_camera: XRCamera3D = null
@export var sensitivity := 0.2
@export var left_controller: XRController3D = null
@export var right_controller: XRController3D = null


enum PassthroughMode { NONE, DIRECT, BLENDMODE }

# cache the result
var has_passthrough := false
var mouse_position: Vector2
var is_xr := true

# Standard controller offset relative to camera
var left_offset := Vector3(-0.3, -0.5, -0.5)  # left hand
var right_offset := Vector3(0.3, -0.5, -0.5)  # right hand


func moveCamera(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0
	var offset = mouse_pos - center

	var yaw = -offset.x * sensitivity * 0.01
	var pitch = -offset.y * sensitivity * 0.01

	var rotation = xr_camera.rotation_degrees
	rotation.y += yaw
	rotation.x = clamp(rotation.x + pitch, -80, 80)
	xr_camera.rotation_degrees = rotation
	
func update_virtual_controllers():
	if is_xr and left_controller:
		left_controller.global_transform = xr_camera.global_transform.translated(left_offset.rotated(Vector3.UP, deg_to_rad(xr_camera.rotation_degrees.y)))
	
	if right_controller:
		right_controller.global_transform = xr_camera.global_transform.translated(right_offset.rotated(Vector3.UP, deg_to_rad(xr_camera.rotation_degrees.y)))


# Called when the node enters the scene tree for the first time.
func _ready():
	
	print('Hello World')
	
	# only OpenXR
	var xr_interface = XRServer.find_interface(xr_interface_type)
	
	# check if we have an XR interface
	if xr_interface and xr_interface.is_initialized():
		print(xr_interface)
		
		# switch on XR
		get_viewport().use_xr = true
		
		# if we can - passthrough should be on
		self.has_passthrough = XRBootstrap.enable_passthrough(xr_interface) != PassthroughMode.NONE
		
		# only switch on passthrough when XR interface is capable
		if has_passthrough:
			get_viewport().transparent_bg = true
			
	else:
		is_xr = false
		if left_controller:
			print('works')
			var t := Transform3D()
			t.origin = Vector3(1, 1, 3)
			left_controller.global_transform = t
		
			
	if xr_debug_label:
		xr_debug_label.text = "OpenXR: %s\nPassthrough:%s" % [get_viewport().use_xr,has_passthrough]


# from https://docs.godotengine.org/en/stable/tutorials/xr/openxr_passthrough.html    
static func enable_passthrough(xr_interface:XRInterface) -> PassthroughMode:
	if xr_interface: 
		if xr_interface.is_passthrough_supported():
			print("Device {} reports passthrough supported" % xr_interface.get_name())
			if xr_interface.start_passthrough():
				return PassthroughMode.DIRECT
		else:
			var modes = xr_interface.get_supported_environment_blend_modes()
			if xr_interface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
				xr_interface.set_environment_blend_mode(xr_interface.XR_ENV_BLEND_MODE_ALPHA_BLEND)
				return PassthroughMode.BLENDMODE
	return PassthroughMode.NONE
	


func _process(delta: float) -> void:
	if !is_xr:
		moveCamera(delta)
		update_virtual_controllers()
		

extends XRController3D

@export var XROrigin: XROrigin3D = null
@export var XRCamera: XRCamera3D = null
@export var LeftController: XRController3D = null
@export var RayCast: RayCast3D = null
@export var Holder: MeshInstance3D = null
@export var World: Node3D = null

var held_body: RigidBody3D = null
var hold_offset: Vector3 = Vector3.ZERO
var hover_target: MeshInstance3D = null

func _ready() -> void:
	RayCast.enabled = true


func _physics_process(_delta):
	update_hover_effect()
	
	if held_body:
		var global_target_pos = Holder.to_global(hold_offset)
		var current_transform = held_body.global_transform
		current_transform.origin = global_target_pos
		held_body.global_transform = current_transform

	# Mouse-based grab/release for testing
	if Input.is_action_just_pressed("mouse_left"):
		grab_object()
	if Input.is_action_just_released("mouse_left"):
		release_object()

func grab_object():
	if held_body == null and RayCast.is_colliding():
		var collider = RayCast.get_collider()
		if collider is RigidBody3D and collider.name == "Book":
			held_body = collider
			held_body.freeze = true
			held_body.gravity_scale = 0.0
			hold_offset = Holder.to_local(held_body.global_position)


func release_object():
	if held_body != null:
		held_body.freeze = false
		held_body.gravity_scale = 1.0
		held_body = null
					

func update_hover_effect():
	if RayCast.is_colliding():
		var collider = RayCast.get_collider()
		#print(collider, collider.get_parent().name)
		if collider.name == "Book":
			var mesh = collider.get_node_or_null("MeshInstance3D") as MeshInstance3D
			if mesh and mesh != hover_target:
				reset_hover_material()
				hover_target = mesh
				# MiniWorld detection
				if collider.get_parent().get_parent() and collider.get_parent().get_parent().name == "MiniWorld":
					set_hover_material(hover_target, Color.CYAN)
				else:
					set_hover_material(hover_target, Color.YELLOW)
			return
	reset_hover_material()


func set_hover_material(mesh: MeshInstance3D, color: Color):
	var material = mesh.get_active_material(0)
	if material and material is BaseMaterial3D:
		material.albedo_color = color


func reset_hover_material():
	if hover_target:
		set_hover_material(hover_target, Color.WHITE)
		hover_target = null


func _on_xr_controller_3d_right_button_pressed(name: String) -> void:
	if name == "trigger_click":
		grab_object()
		#pass # Replace with function body.


func _on_xr_controller_3d_right_button_released(name: String) -> void:
	if name == "trigger_click":
		release_object()

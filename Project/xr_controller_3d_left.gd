extends XRController3D

@export var World: Node3D = null
@export var Static: Node3D = null
@export var Dynamic: Node3D = null
@export var Right_Controller: XRController3D = null
@export var MINI_SCALE: float = 0.02
@export var Static_Walls: Node3D

var orig_book: RigidBody3D
var clone_book: RigidBody3D
var mini_clone: Node3D

var orig_book_last_pos: Vector3
var clone_book_last_pos: Vector3

func _ready():
	create_mini_world()
	print("Miniature world created on left controller")
	
		
func disable_physics_in_clone(node: Node):
	if node is RigidBody3D:
		node.freeze = true
		node.gravity_scale = 0
		
	if node is CollisionObject3D:
		node.collision_layer = 2
		node.collision_mask = 1 | 2

	for child in node.get_children():
		disable_physics_in_clone(child)
		

func create_mini_world():
	if World == null:
		push_error("World not assigned!")
		return

	# Original book from real world
	orig_book = Dynamic.get_node("Book") as RigidBody3D
	print(orig_book, 'original book')

	# Duplicate the world
	var clone = World.duplicate()
	clone.name = "MiniWorld"

	# Remove camera, lights, walls, and ceiling
	for child in clone.get_children():
		if child is XRCamera3D or child is DirectionalLight3D or child.name == "Static":
			print(child.name)
			child.queue_free()
	
	## This code is for testing
	clone.scale = Vector3.ONE * MINI_SCALE
	disable_physics_in_clone(clone)
	
	var basis = Basis() * MINI_SCALE
	var origin = self.global_transform.origin + self.global_transform.basis.z * -0.3 + Vector3(0, -0.2, 0)
	var scaled_transform = Transform3D(basis, origin)

	# Apply full transform before adding
	clone.global_transform = scaled_transform

	add_child(clone)
	
	print("Placed miniworld at:", clone.global_transform, clone.scale)

	mini_clone = clone
	clone_book = clone.find_child("Book", true, false) as RigidBody3D

	orig_book_last_pos = orig_book.global_position
	clone_book_last_pos = clone_book.global_position

		
func _physics_process(_delta):
	if !is_instance_valid(orig_book) or !is_instance_valid(clone_book):
		return

	# Real Book Moved
	if orig_book.global_position != orig_book_last_pos:
		clone_book.freeze = true
		clone_book.gravity_scale = 0
		var t_local = World.global_transform.affine_inverse() * orig_book.global_transform
		t_local.basis = Basis(t_local.basis.orthonormalized())
		clone_book.global_transform = mini_clone.global_transform * t_local
		orig_book_last_pos = orig_book.global_position
		clone_book_last_pos = clone_book.global_position
		return

	# Miniature Book Moved
	if clone_book.global_position != clone_book_last_pos:
		var t_local = mini_clone.global_transform.affine_inverse() * clone_book.global_transform
		t_local.basis = Basis(t_local.basis.orthonormalized())
		orig_book.global_transform = World.global_transform * t_local
		clone_book_last_pos = clone_book.global_position
		orig_book_last_pos = orig_book.global_position
		return

extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var size_x = 1
export var size_z = 1
var collision_shape
var mesh_instance

# Called when the node enters the scene tree for the first time.
func _ready():
	collision_shape = $StaticBody/CollisionShape
	mesh_instance = $StaticBody/MeshInstance
	collision_shape.scale = Vector3(size_x, 1, size_z)
	mesh_instance.scale = Vector3(size_x, 1, size_z)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

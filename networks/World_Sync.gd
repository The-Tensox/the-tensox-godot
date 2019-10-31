extends HTTPRequest

# Currently this script is highly specialized in the handling of object table

export var HOST = "127.0.0.1"
export var PORT_REST = "8001"
export var PORT_WEBSOCKET = "3012"
export var BATCH_SIZE = 50 # Batch of objects to query
var index = 0 # We start querying at index 0 objects
var ws = null
var cube = preload("res://scenes/Cube.tscn")
var instances = Array()

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("request_completed", self, "_on_HTTPRequest_request_completed")
	ws = WebSocketClient.new()
	ws.connect("connection_established", self, "_connection_established")
	ws.connect("connection_closed", self, "_connection_closed")
	ws.connect("connection_error", self, "_connection_error")
	ws.connect("data_received", self, "_data_received")

	var websocket_url = str("ws://", HOST, ":", PORT_WEBSOCKET)
	print("Connecting to " + websocket_url)
	print(ws.connect_to_url(websocket_url))
	
	# On connection we want to get all the stuff currently in the db
	request(str("http://", HOST, ":", PORT_REST, "/objects/", index, "/", BATCH_SIZE))
	#request(str("http://", HOST, ":", PORT_REST, "/objects/count"))

func _on_HTTPRequest_request_completed( _1, _2, _3, body ):
	var parsed_json = parse_json(body.get_string_from_utf8())
	index+=BATCH_SIZE
	for object in parsed_json["objects"]:
		_process_data({"data": object, "protocol": "GET"})
	# While there is objects to GET, we recursively and incrementally query them
	if parsed_json["items_left"] > 0:
		request(str("http://", HOST, ":", PORT_REST, "/objects/", index, "/", BATCH_SIZE))	
	
	
func _make_post_request(url, data_to_send, use_ssl):
	# Convert data to json string:
	var query = JSON.print(data_to_send)
	# Add "Content-Type" header:
	var headers = ["Content-Type: application/json"]
	request(url, headers, use_ssl, HTTPClient.METHOD_POST, query)	



func _connection_established(protocol):
	print("Connection established with protocol: ", protocol)

func _connection_closed():
	print("Connection closed")

func _connection_error():
	print("Connection error")
	
func _data_received():
	var json_string = ws.get_peer(1).get_packet().get_string_from_ascii()
	var dict
	dict = parse_json(json_string)
	_process_data(dict)

func _process(_1):
	# Debug teleport to mesh
	if Input.is_key_pressed(KEY_K):
		if len(instances) > 0:
			get_parent().get_node("Camera").translation = instances[0]["instance"].translation
		var pos = get_parent().get_node("Camera").translation
		get_parent().get_node("Camera").get_node("Hud/Text").text = str("Teleported to ", pos)
	if ws.get_connection_status() == ws.CONNECTION_CONNECTING || ws.get_connection_status() == ws.CONNECTION_CONNECTED:
		ws.poll()

# TODO: find better name
func _process_data(parsed_json):
	var data = parsed_json["data"]
	var protocol = parsed_json["protocol"]
	var meshInstance

	for i in range(instances.size()):
		if protocol == "DELETE_ALL":
			meshInstance = instances[i]["instance"]
			instances.remove(i)
			meshInstance.queue_free()
		elif instances[i]["data"]["_id"] == data["_id"]:
			meshInstance = instances[i]["instance"]
			if protocol == "DELETE":
				instances.remove(i)
				meshInstance.queue_free()
				# return doesn't work in GDScript like other language it seems =)
		
	if not meshInstance and protocol != "DELETE":
		meshInstance = MeshInstance.new()
		var mesh
		var color
		
		if data["kind"] == "ground":
			color = "#663300" # Brown
		elif data["kind"] == "grass":
			color = "#003300" # Green
		color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1))
		var mat = SpatialMaterial.new()
		mat.albedo_color = color

		match data["mesh"].keys():
			["Box"]:
				mesh = CubeMesh.new()
				var box = data["mesh"]["Box"]
				var x = box["x"]
				var y = box["y"]
				var z = box["z"]
				mesh.size = Vector3(x, y , z)
				mesh.material = mat
			["Capsule"]:
				mesh = CapsuleMesh.new()
				var capsule = data["mesh"]["Capsule"]
				var height = capsule["height"]
				var radius = capsule["radius"]
				mesh.mid_height = height
				mesh.radius = radius
				mesh.material = mat
			["Array"]:
				print(data["position_x"], data["position_z"])
				#mesh = ArrayMesh.new()
				#var arrays = []
				#var vertex_array = []
				#arrays.resize(Mesh.ARRAY_MAX)
				var array = data["mesh"]["Array"]
				var st = SurfaceTool.new()

				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				#st.set_material(mat)
				for i in array["meshes"]:
					#st.add_color(Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1)))
					st.add_vertex(Vector3(i["vertices"][0], i["vertices"][1], i["vertices"][2]))
					
					#vertex_array.append(Vector3(i["vertices"][0], i["vertices"][1], i["vertices"][2]))
				"""
				arrays[Mesh.ARRAY_VERTEX] = vertex_array
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				#mesh.lightmap_unwrap(mesh.transform, 1)
				mesh.regen_normalmaps()
				"""
				# Create indices, indices are optional.
				st.index()
				st.generate_normals()
				# Commit to a mesh.
				mesh = st.commit()

		meshInstance.mesh = mesh
			
		instances.push_front({ "data": data, "instance": meshInstance })
		var scene_root = get_tree().root.get_children()[0]
		scene_root.add_child(meshInstance)
	
	if meshInstance and protocol != "DELETE":
		meshInstance.scale = Vector3(data["scale_x"], data["scale_y"], data["scale_z"])
		meshInstance.translation = Vector3(data["position_x"], data["position_y"], data["position_z"])
		meshInstance.rotation = Vector3(data["rotation_x"], data["rotation_y"], data["rotation_z"])
extends HTTPRequest

# Currently this script is highly specialized in the handling of object table

export var HOST = "127.0.0.1"
export var PORT_REST = "8001"
export var PORT_WEBSOCKET = "3012"
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
	request(str("http://", HOST, ":", PORT_REST, "/objects"))

func _on_HTTPRequest_request_completed( result, response_code, headers, body ):
	var parsed_json = parse_json(body.get_string_from_utf8())
	for object in parsed_json:
		_process_data({"data": object, "protocol": "GET"})
	
func _make_post_request(url, data_to_send, use_ssl):
    # Convert data to json string:
    var query = JSON.print(data_to_send)
    # Add "Content-Type" header:
    var headers = ["Content-Type: application/json"]
    $HTTPRequest.request(url, headers, use_ssl, HTTPClient.METHOD_POST, query)	



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

func _process(delta):
	
	if ws.get_connection_status() == ws.CONNECTION_CONNECTING || ws.get_connection_status() == ws.CONNECTION_CONNECTED:
		ws.poll()
	"""
	if ws.get_peer(1).is_connected_to_host():
		# ws.get_peer(1).put_var("HI")
		if ws.get_peer(1).get_available_packet_count() > 0 :
			var test = ws.get_peer(1).get_var()
			print("recieve %s" % test)
	"""

# TODO: find better name
func _process_data(parsed_json):
	var data = parsed_json["data"]
	var protocol = parsed_json["protocol"]
	var meshInstance
	print(data)

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
		#instance = cube.instance()
		meshInstance = MeshInstance.new()
		var mesh
		# Random color ^^
		var color = Color(rand_range(0,255), rand_range(0,255), rand_range(0,255))
		# TODO: fix it doesn't work different color cuz same object = same material
		# maybe create new material on runtime ...
		if data["kind"] == "ground":
			color = "#663300" # Brown
		elif data["kind"] == "grass":
			color = "#003300" # Green
			
		#instance.get_node("MeshInstance").get_surface_material(0).albedo_color = color
		#print(instance.get_node("MeshInstance").material_override)
		match data["mesh"].keys():
			["Box"]:
				mesh = CubeMesh.new()
				var box = data["mesh"]["Box"]
				var x = box["x"]
				var y = box["y"]
				var z = box["z"]
				mesh.size = Vector3(x, y , z)
			["Capsule"]:
				mesh = CapsuleMesh.new()
				var capsule = data["mesh"]["Capsule"]
				var height = capsule["height"]
				var radius = capsule["radius"]
				mesh.mid_height = height
				mesh.radius = radius
			["Array"]:
				mesh = ArrayMesh.new()
				var arrays = []
				var vertex_array = []
				arrays.resize(Mesh.ARRAY_MAX)
				var array = data["mesh"]["Array"]
				for i in array["meshes"]:
					vertex_array.append(Vector3(i["vertices"][0], i["vertices"][1], i["vertices"][2]))
				arrays[Mesh.ARRAY_VERTEX] = vertex_array
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

		meshInstance.mesh = mesh
			
		instances.push_front({ "data": data, "instance": meshInstance })
		var scene_root = get_tree().root.get_children()[0]
		scene_root.add_child(meshInstance)
		
	#else:
	#	print("Uninplemented protocol:", protocol)
	#print(instance.get_property_list())
	#instance.global_transform = self.global_transform
	
	if meshInstance and protocol != "DELETE":
		meshInstance.scale = Vector3(data["scale_x"], data["scale_y"], data["scale_z"])
		meshInstance.translation = Vector3(data["position_x"], data["position_y"], data["position_z"])
		meshInstance.rotation = Vector3(data["rotation_x"], data["rotation_y"], data["rotation_z"])
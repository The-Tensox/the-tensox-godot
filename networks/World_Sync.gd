extends HTTPRequest

# TODO: some kind of nice design of a macro level world handler
# for example it will check if new entities such a new clouds appear ...
# if there is a new cloud, spawn it then the cloud handle it"s network sync itself ....
var ws = null
var cube = preload("res://scenes/Cube.tscn")
var instances = Array()

# Called when the node enters the scene tree for the first time.
func _ready():
	ws = WebSocketClient.new()
	ws.connect("connection_established", self, "_connection_established")
	ws.connect("connection_closed", self, "_connection_closed")
	ws.connect("connection_error", self, "_connection_error")
	ws.connect("data_received", self, "_data_received")

	var url = "ws://127.0.0.1:3012"
	print("Connecting to " + url)
	print(ws.connect_to_url(url))
	# $HTTPRequest.request("http://localhost:8001/weather")
	#pass # Replace with function body.

func _on_HTTPRequest_request_completed( result, response_code, headers, body ):
	print("Response")
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
	
	
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
	var data = dict["data"]
	var protocol = dict["protocol"]
	print("Parsed", dict)
	print("Data", data)
	print("Protocol", protocol)
	var instance
	#if protocol == "POST":

	#elif protocol == "PUT":
	for i in instances:
		if i["data"]["id"] == data["id"]:
			instance = i["instance"]
			
	if not instance:
		instance = cube.instance()
		instances.push_front({ "data": data, "instance": instance })
		var scene_root = get_tree().root.get_children()[0]
		scene_root.add_child(instance)
	#else:
	#	print("Uninplemented protocol:", protocol)
	#print(instance.get_property_list())
	#instance.global_transform = self.global_transform
	#instance.scale = Vector3(data["scale_x"], data["scale_y"], data["scale_z"])
	instance.translation = Vector3(data["position_x"], data["position_y"], data["position_z"])
	instance.rotation = Vector3(data["rotation_x"], data["rotation_y"], data["rotation_z"])
	
	

	
	

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

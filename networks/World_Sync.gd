extends HTTPRequest

# TODO: some kind of nice design of a macro level world handler
# for example it will check if new entities such a new clouds appear ...
# if there is a new cloud, spawn it then the cloud handle it's network sync itself ....
var ws = null

# Called when the node enters the scene tree for the first time.
func _ready():
	ws = WebSocketClient.new()
	ws.connect("connection_established", self, "_connection_established")
	ws.connect("connection_closed", self, "_connection_closed")
	ws.connect("connection_error", self, "_connection_error")

	var url = "ws://127.0.0.1:3012"
	print("Connecting to " + url)
	print(ws.connect_to_url(url))
	# $HTTPRequest.request("http://localhost:8001/weather")
	#pass # Replace with function body.

func _on_HTTPRequest_request_completed( result, response_code, headers, body ):
	print("Response")
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass




func _connection_established(protocol):
	print("Connection established with protocol: ", protocol)

func _connection_closed():
	print("Connection closed")

func _connection_error():
	print("Connection error")

func _process(delta):
	
	if ws.get_connection_status() == ws.CONNECTION_CONNECTING || ws.get_connection_status() == ws.CONNECTION_CONNECTED:
		ws.poll()
	
	if ws.get_peer(1).is_connected_to_host():
		ws.get_peer(1).put_var("HI")
		if ws.get_peer(1).get_available_packet_count() > 0 :
			var test = ws.get_peer(1).get_var()
			print('recieve %s' % test)
	

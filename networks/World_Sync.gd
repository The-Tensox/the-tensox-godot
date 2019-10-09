extends HTTPRequest

# TODO: some kind of nice design of a macro level world handler
# for example it will check if new entities such a new clouds appear ...
# if there is a new cloud, spawn it then the cloud handle it's network sync itself ....

# Called when the node enters the scene tree for the first time.
func _ready():
	# $HTTPRequest.request("http://localhost:8001/weather")
	pass # Replace with function body.

func _on_HTTPRequest_request_completed( result, response_code, headers, body ):
	print("Response")
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

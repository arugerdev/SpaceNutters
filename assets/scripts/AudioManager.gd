extends Node

@onready var input : AudioStreamPlayer3D = $Input
var index : int
var effect : AudioEffectCapture
var playback : AudioStreamGeneratorPlayback
@onready var output := $Output
var inputThreshold = .005
var receiveBuffer := PackedFloat32Array()
func setupAudio(id):
	set_multiplayer_authority(id)
	if is_multiplayer_authority():
		input.stream = AudioStreamMicrophone.new()
		input.play()
		index = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(index, 0)
		
func _process(delta):
	if is_multiplayer_authority():
		processMic()
	processVoice()
	
func processMic():
	var sterioData : PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	
	if sterioData.size() > 0:
		
		var data = PackedFloat32Array()
		data.resize(sterioData.size())
		var maxAmplitude := 0.0
		
		for i in range(sterioData.size()):
			var value = (sterioData[i].x + sterioData[i].y) / 2
			maxAmplitude = max(value, maxAmplitude)
			data[i] = value
		if maxAmplitude < inputThreshold:
			return
		
		sendData.rpc(data)

func processVoice():
	if receiveBuffer.size() <= 0:
		return
	
	for i in range(min(playback.get_frames_available(), receiveBuffer.size())):
		playback.push_frame(Vector2(receiveBuffer[0], receiveBuffer[0]))
		receiveBuffer.remove_at(0)

@rpc("any_peer","call_remote", "reliable")
func sendData(data:PackedFloat32Array):
	for player in multiplayer.get_peers():
		if player == multiplayer.get_remote_sender_id():
			output = get_node("/root/world/" + var_to_str(player) + "/AudioManager/Output")
			playback = output.get_stream_playback()
	receiveBuffer.append_array(data)

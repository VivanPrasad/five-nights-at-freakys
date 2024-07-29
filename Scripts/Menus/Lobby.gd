extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _on_line_edit_text_changed(_new_text: String) -> void:
	pass
	#join_button.disabled = len(line_edit.text) != 8 \
	#or not Multi.get_ip_from_code(line_edit.text).is_valid_ip_address()

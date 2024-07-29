extends TextureButton

@onready var cam_name_label: Label = $Name

func _ready() -> void:
	cam_name_label.text = "CAM\n%s" % name

extends Node
class_name Multi

static func get_shift_value() -> int:
	var time : Dictionary = Time.get_datetime_dict_from_system(true)
	var shift_value : int = abs(
		time["day"] + time["month"] - time["hour"])
	return shift_value

static func get_code_from_ip(ip_text:String) -> String:
	var values = ip_text.split(".")
	var code_color : Color = Color(
		float((values[0].to_int()+get_shift_value()) / 255.0),
		float((values[1].to_int()+get_shift_value()) / 255.0),
		float((values[2].to_int()+get_shift_value()) / 255.0),
		float((values[3].to_int()+get_shift_value()) / 255.0)
	)
	var ciphered = code_color.to_html()
	return ciphered

static func get_ip_from_code(code : String) -> String:
	var code_color = Color(code.to_lower())
	var code_arr = [
		int(code_color.r*255.0-(get_shift_value())),
		int(code_color.g*255.0-(get_shift_value())),
		int(code_color.b*255.0-(get_shift_value())),
		int(code_color.a*255.0-(get_shift_value()))
	]
	var deciphered = ".".join(code_arr)
	return deciphered

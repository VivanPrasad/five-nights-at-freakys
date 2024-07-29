## Global
extends Node

enum GAMEMODE {CLASSIC,FREE,FRENZY,IRL,CUSTOM}
var is_multi : bool = false
var game_mode : GAMEMODE = GAMEMODE.CLASSIC

class Utils:
	extends Node
	
	## Coroutine
	func fade_in(node:Node,time:float=1.0,
			trans:Tween.TransitionType=Tween.TRANS_CIRC,
			delay:float=0.0):
		await create_tween()\
			.tween_property(node,"modulate:a",1.0,time)\
			.set_trans(trans)\
			.set_delay(delay).finished

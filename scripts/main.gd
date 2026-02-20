extends Node

const KITTY_START_POS := Vector2i(48, 232)
const CAM_START_POS := Vector2i(0, 0)
const START_SPEED := 5.0
const MAX_SPEED := 25

var score: float
var speed: float
var screen_size: Vector2i


func _ready():
	screen_size = get_window().size
	new_game()
	
func new_game():
	score = 0
	
	$Player.position = KITTY_START_POS
	$Player.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	
func _process(delta: float):
	speed = START_SPEED
	#$Ground.position.x -= speed
	#$"Background/Base Layer".autoscroll = Vector2(0, 0)
	#$"Background/Farthest Trees".autoscroll = Vector2(-5, 0)
	#$"Background/Farther Trees".autoscroll = Vector2(-10, 0)
	#$"Background/Far Trees".autoscroll = Vector2(-15, 0)
	#$Background/Trees.autoscroll = Vector2(-20, 0)
	#$Background/Bushes.autoscroll = Vector2(-25, 0)
	#$Player.position.x += speed
	#$Camera2D.position.x += speed
	
	#if $Camera2D.position.x - $Ground.position.x > screen_size.x / 2 * 1.5:
		#$Ground.position.x += screen_size.x / 2
		

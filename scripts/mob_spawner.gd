extends Node2D

@export var kitty: CharacterBody2D

const MOB_SCENE_PATH := "res://scenes/mob.tscn"

var vp_height: int
var vp_width: int
@onready var spawn_timer: Timer = $MobSpawnTimer


func _ready() -> void:
	vp_height = get_viewport_rect().size.y
	vp_width = get_viewport_rect().size.x
	ResourceLoader.load_threaded_request(MOB_SCENE_PATH)


func set_spawn_interval(interval: float) -> void:
	spawn_timer.wait_time = clampf(interval, 2.0, 5.0)


func _on_mob_spawn_timer_timeout() -> void:
	var mob_scene: PackedScene = ResourceLoader.load_threaded_get(MOB_SCENE_PATH)
	var mob: Mob = mob_scene.instantiate()
	mob.target = kitty
	var mob_start_x: int = [-10, vp_width + 10].pick_random()
	var mob_start_y: int = randi_range(vp_height / 8, vp_height / 3)
	mob.position = Vector2i(mob_start_x, mob_start_y)
	# relay kill score to game
	var game: Node = get_tree().current_scene
	if game.has_method("add_kill_score"):
		mob.mob_killed.connect(game.add_kill_score)
	if game.has_method("extend_combo"):
		mob.mob_hit.connect(game.extend_combo)
	add_child(mob)
	ResourceLoader.load_threaded_request(MOB_SCENE_PATH)

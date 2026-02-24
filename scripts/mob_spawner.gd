# Enemy spawner -- creates mobs at timed intervals
#
# Spawns mobs at random positions along the screen edges. The spawn interval
# decreases as the player's score increases (difficulty scaling).
#
# Uses Godot's threaded resource loading to avoid frame hitches. The mob
# scene is pre-requested on _ready() and after each spawn. By the time the
# timer fires, the scene is already loaded in memory and instantiation is
# nearly free.
#
# Signal wiring happens here rather than in the mob scene because the game
# controller (game.gd) needs to receive kill/hit events. The spawner acts
# as a bridge: it looks up the current scene, checks for the expected
# methods, and connects the mob's signals to them. This avoids hard
# references between mobs and the game controller.
extends Node2D

@export var kitty: CharacterBody2D

const MOB_SCENE_PATH := "res://scenes/mob.tscn"

var vp_height: int
var vp_width: int
@onready var spawn_timer: Timer = $MobSpawnTimer


func _ready() -> void:
	vp_height = get_viewport_rect().size.y
	vp_width = get_viewport_rect().size.x
	# start loading the mob scene in a background thread.
	# this prevents frame drops when the first mob spawns.
	ResourceLoader.load_threaded_request(MOB_SCENE_PATH)


# called by game.gd each frame to adjust difficulty.
# the interval shrinks as score increases (5s -> 2s).
func set_spawn_interval(interval: float) -> void:
	spawn_timer.wait_time = clampf(interval, 2.0, 5.0)


# connected to the MobSpawnTimer's timeout signal in the editor
func _on_mob_spawn_timer_timeout() -> void:
	# retrieve the pre-loaded scene (should be ready by now)
	var mob_scene: PackedScene = ResourceLoader.load_threaded_get(MOB_SCENE_PATH)
	var mob: Mob = mob_scene.instantiate()
	# give the mob a reference to the player for targeting
	mob.target = kitty
	# spawn at a random edge (left or right) at a random height in the upper third.
	# spawning at edges means mobs fly in from offscreen naturally.
	var mob_start_x: int = [-10, vp_width + 10].pick_random()
	var mob_start_y: int = randi_range(vp_height / 8, vp_height / 3)
	mob.position = Vector2i(mob_start_x, mob_start_y)
	# connect mob signals to the game controller for scoring.
	# using has_method() makes this safe even if the game controller changes.
	var game: Node = get_tree().current_scene
	if game.has_method("add_kill_score"):
		mob.mob_killed.connect(game.add_kill_score)
	if game.has_method("extend_combo"):
		mob.mob_hit.connect(game.extend_combo)
	add_child(mob)
	# immediately request the next load so it's ready for the next spawn
	ResourceLoader.load_threaded_request(MOB_SCENE_PATH)

# Centralized particle effect helper (static utility)
#
# All particle spawning goes through this single function. This solves
# three problems at once:
#   1. Eliminates duplicated spawn code across mob.gd, bullet.gd, kitty.gd
#   2. Centralizes the "World/Level" parent path (one place to change)
#   3. Handles the missing-node case gracefully with a warning
#
# Particles are parented to the Level node (not the emitter) so they
# persist after the emitter is freed. For example, death particles should
# linger after the mob is queue_free()'d.
#
# The auto-free timer uses lifetime + 0.1s as a safety margin since
# CPUParticles2D doesn't auto-free when emission completes.
class_name FX

static func spawn_particles(scene: PackedScene, pos: Vector2, tree: SceneTree) -> void:
	var particles := scene.instantiate() as CPUParticles2D
	particles.global_position = pos
	particles.emitting = true
	var level := tree.current_scene.get_node_or_null("World/Level")
	if level:
		level.add_child(particles)
		tree.create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)
	else:
		push_warning("FX.spawn_particles: World/Level node not found")
		particles.queue_free()

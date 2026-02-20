
extends CharacterBody2D

@export_subgroup("Nodes")
@export var input_component: InputComponent
@export var gravity_component: GravityComponent
@export var movement_component: MovementComponent
@export var jump_component: JumpComponent
@export var shoot_component: ShootComponent
@export var hurt_component: HurtComponent
@export var animation_component: AnimationComponent


func _physics_process(delta: float) -> void:
	# Falling
	gravity_component.handle_gravity(self, delta)
	# Walking
	movement_component.handle_horizontal_movement(self, input_component.input_horizontal)
	# Jumping
	jump_component.handle_jump(self, input_component.get_jump_input(), input_component.get_jump_input_released())
	# Shooting
	shoot_component.handle_shoot(self.position, self.get_global_mouse_position(), input_component.get_shoot_input())
	# TODO: Hurting?
	move_and_slide()
	
func _process(_delta: float) -> void:
	# Animation
	animation_component.handle_move_animation(input_component.input_horizontal)
	animation_component.handle_jump_animation(jump_component.is_going_up, gravity_component.is_falling)
	#animation_component.handle_hurt_animation(hurt_component.is_hurting)

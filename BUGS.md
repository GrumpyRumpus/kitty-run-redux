Known Bugs and Attempted Fixes

============================================================
KITTY RUNNING ON GAME START (RESOLVED)
============================================================

Symptom
  Kitty runs left or right on game start without any input.
  Originally misidentified as "slope sliding on landing" but
  debug logging revealed kitty was receiving directional
  velocity while still airborne, before touching the ground.

Root cause
  State.direction is a static var shared across all State
  instances. Static vars persist across scene transitions, so
  direction retained its value from the previous game or menu
  interaction. On game start, the Falling state's
  process_physics() applied horizontal movement using the
  stale direction value.

Fix (state_machine.gd)
  Reset direction to Vector2.ZERO in StateMachine.init():
    current_state.direction = Vector2.ZERO


============================================================
SHOOTING DIRECTION (ALWAYS FORWARDS) (RESOLVED)
============================================================

Symptom
  Kitty always shoots nearly straight to the right regardless
  of mouse cursor position. Bullets had angles within ~5
  degrees of horizontal.

Root cause
  get_global_mouse_position() and get_viewport().get_mouse_position()
  both return screen-space coordinates instead of viewport-space
  coordinates. With stretch_mode="viewport" and integer scaling,
  the mouse position is not transformed through the viewport
  stretch. At 2x window scale (1024x512), raw mouse x-values
  were ~1500 while the viewport is only 512 wide. This made
  the direction vector from kitty (x=168) to the mouse nearly
  (1.0, 0.0) regardless of actual cursor position.

  This appears to be a Godot 4.6 issue on Linux where polled
  mouse position APIs do not account for viewport stretch.
  InputEventMouse.position IS correctly transformed.

Fix (kitty.gd)
  Track mouse position via input events instead of polling:
    var _mouse_viewport: Vector2 = Vector2.ZERO

    func _input(event: InputEvent) -> void:
        if event is InputEventMouse:
            _mouse_viewport = event.position

    func _get_world_mouse_position() -> Vector2:
        return get_canvas_transform().affine_inverse() * _mouse_viewport

  The canvas transform inverse accounts for Camera2D offset.

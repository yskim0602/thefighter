extends Fighter

## Human-controlled fighter: WASD to move/strafe, J to punch, K to kick,
## hold L to block. Facing the opponent is handled by Fighter._face_opponent().


func _physics_process(delta: float) -> void:
	if not is_ko and not is_staggered:
		_handle_input()
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	super._physics_process(delta)


func _handle_input() -> void:
	is_blocking = Input.is_action_pressed("attack_block")
	if is_blocking:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)
	velocity.x = input_dir.x * MOVE_SPEED
	velocity.z = input_dir.y * MOVE_SPEED

	if Input.is_action_just_pressed("attack_punch"):
		try_punch()
	if Input.is_action_just_pressed("attack_kick"):
		try_kick()

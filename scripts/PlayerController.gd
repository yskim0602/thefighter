extends Fighter

## Human-controlled fighter: WASD to move/strafe, J to punch, hold L to
## block. Facing the opponent is handled by Fighter._face_opponent().


func _ready() -> void:
	stats = SaveManager.career.stats
	super._ready()


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
	var move_speed := stats.get_move_speed()
	velocity.x = input_dir.x * move_speed
	velocity.z = input_dir.y * move_speed

	if Input.is_action_just_pressed("attack_punch"):
		try_punch()

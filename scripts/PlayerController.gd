extends Fighter

## Human-controlled fighter: WASD to move/strafe, J to punch, hold L to
## block. Facing the opponent is handled by Fighter._face_opponent().
##
## The player doesn't pick a boxing style directly - it's inferred from how
## their stats have grown through training (BoxingStyle.infer_style), so
## training power makes them hit like a slugger, training speed/skill makes
## them move like an out-boxer, and so on.


func _ready() -> void:
	stats = SaveManager.career.stats
	style = BoxingStyle.infer_style(stats)
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
	var move_speed := get_effective_move_speed()
	velocity.x = input_dir.x * move_speed
	velocity.z = input_dir.y * move_speed

	if Input.is_action_just_pressed("attack_punch"):
		try_punch()

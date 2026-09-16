class_name PlayerController
extends Fighter

## Human-controlled fighter: WASD to move/strafe, J/K/I/O to throw
## jab/straight/hook/uppercut, hold L to block, Space to dodge (in the
## direction you're moving, or backward away from the opponent if you're
## standing still). While down, any punch button mashes the get-up count
## down faster. Facing the opponent is handled by Fighter._face_opponent().
##
## The player doesn't pick a boxing style directly - it's inferred from how
## their stats have grown through training (BoxingStyle.infer_style), so
## training power makes them hit like a slugger, training speed/skill makes
## them move like an out-boxer, and so on.
##
## Stance IS a direct choice, though (Orthodox/Southpaw, picked in the
## Character menu and saved on CareerData) - it decides which physical hand
## is lead/rear, which Fighter.gd uses for every glove position and punch
## animation.
##
## Main.gd flips `first_person` when the view is toggled (see toggle_view).
## In third person, WASD moves along world axes like before. In first
## person the camera rides along with this body's rotation (which always
## auto-faces the opponent), so movement switches to being relative to
## that facing instead - otherwise "forward" wouldn't match what's on
## screen as you circle the opponent.
var first_person := false


func _ready() -> void:
	stats = SaveManager.career.stats
	style = BoxingStyle.infer_style(stats)
	stance = SaveManager.career.stance
	super._ready()


func _physics_process(delta: float) -> void:
	if is_down:
		if Input.is_action_just_pressed("attack_jab"):
			mash_get_up()
		velocity.x = 0.0
		velocity.z = 0.0
	elif is_ko or is_staggered or is_dodging:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		_handle_input()
	super._physics_process(delta)


func _handle_input() -> void:
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)
	var move_dir := _compute_move_direction(input_dir)

	if Input.is_action_just_pressed("dodge"):
		if try_dodge(move_dir):
			return

	is_blocking = Input.is_action_pressed("attack_block")
	if is_blocking:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var move_speed := get_effective_move_speed()
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	if Input.is_action_just_pressed("attack_jab"):
		try_punch(PunchType.Type.JAB)
	elif Input.is_action_just_pressed("attack_straight"):
		try_punch(PunchType.Type.STRAIGHT)
	elif Input.is_action_just_pressed("attack_hook"):
		try_punch(PunchType.Type.HOOK)
	elif Input.is_action_just_pressed("attack_uppercut"):
		try_punch(PunchType.Type.UPPERCUT)


func _compute_move_direction(input_dir: Vector2) -> Vector3:
	if first_person:
		var basis := global_transform.basis
		return -basis.z * input_dir.y + basis.x * input_dir.x
	return Vector3(input_dir.x, 0.0, input_dir.y)

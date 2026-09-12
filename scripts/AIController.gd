extends Fighter

## Simple reactive CPU opponent: closes the distance, then randomly
## punches, kicks or blocks once in range. Not smart, just a placeholder
## to spar against while you build out real mechanics/animations.

const AI_ATTACK_MIN_INTERVAL := 0.8
const AI_ATTACK_MAX_INTERVAL := 1.8
const AI_BLOCK_CHANCE := 0.25
const AI_PUNCH_CHANCE := 0.65
const AI_BLOCK_DURATION := 0.6
const AI_APPROACH_SPEED_MULT := 0.8

var _decision_timer := 0.0
var _block_timer := 0.0


func _ready() -> void:
	# 플레이어가 승수를 쌓을수록 상대도 조금씩 강해진다 (훈련할 이유를 유지).
	var win_bonus := int(SaveManager.career.wins / 3)
	stats = CharacterStats.new()
	stats.fighter_name = "지하 레슬러"
	stats.style = 2  # 레슬링
	stats.power = 14 + win_bonus
	stats.stamina = 14 + win_bonus
	stats.speed = 10 + win_bonus
	stats.skill = 12 + win_bonus
	super._ready()


func _physics_process(delta: float) -> void:
	if is_ko or is_staggered:
		velocity.x = 0.0
		velocity.z = 0.0
		is_blocking = false
		super._physics_process(delta)
		return

	if _block_timer > 0.0:
		_block_timer -= delta
		is_blocking = true
	else:
		is_blocking = false

	_decision_timer -= delta
	if _decision_timer <= 0.0:
		_make_decision()

	super._physics_process(delta)


func _make_decision() -> void:
	_decision_timer = randf_range(AI_ATTACK_MIN_INTERVAL, AI_ATTACK_MAX_INTERVAL)
	if opponent == null:
		return

	var dist := global_position.distance_to(opponent.global_position)
	if dist > ATTACK_RANGE:
		var dir := opponent.global_position - global_position
		dir.y = 0.0
		dir = dir.normalized()
		var move_speed := stats.get_move_speed()
		velocity.x = dir.x * move_speed * AI_APPROACH_SPEED_MULT
		velocity.z = dir.z * move_speed * AI_APPROACH_SPEED_MULT
		return

	velocity.x = 0.0
	velocity.z = 0.0
	var roll := randf()
	if roll < AI_BLOCK_CHANCE:
		_block_timer = AI_BLOCK_DURATION
	elif roll < AI_PUNCH_CHANCE:
		try_punch()
	else:
		try_kick()

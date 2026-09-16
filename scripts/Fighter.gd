class_name Fighter
extends CharacterBody3D

## Shared logic for any fighter in the ring: movement/gravity, health,
## stamina, punch types, block, dodge, counters, knockdown/KO, hit feedback.
## PlayerController.gd and AIController.gd extend this and only decide
## *when* to move/attack/dodge (and, for the CPU, *which* boxing style to
## lean into right now).
##
## `style` (BoxingStyle.Style) scales every combat number computed from
## `stats` - max health, max stamina, movement, attack range, cooldown
## recovery, block effectiveness - via BoxingStyle.profile(). Changing
## `style` mid-fight (AIController does this) changes how the fighter
## behaves immediately.
##
## Boxing's core resource loop lives entirely here: punches cost stamina,
## stamina regenerates when idle, and running out of it ("gassed") makes
## every punch weaker and slower until it recovers - see try_punch().
##
## KO is two-tiered, matching the real "three-knockdown rule": health
## hitting zero is a *knockdown* (is_down, recoverable) until
## MAX_KNOCKDOWNS is reached, at which point it becomes the real,
## match-ending KO (is_ko, `knocked_out` signal - unchanged from before,
## so Main.gd's win/loss flow needs no changes).

signal health_changed(current: float, max_value: float)
signal stamina_changed(current: float, max_value: float)
signal knocked_down(count: int)
signal recovered_from_down
signal knocked_out

const GRAVITY := 20.0
const ARENA_RADIUS := 7.0

const STAGGER_TIME := 0.35
const BASE_PUNCH_COOLDOWN := 0.5
const ATTACK_RANGE := 2.2
const BLOCK_DAMAGE_MULT := 0.2

## --- 스태미나: 펀치/회피마다 소모되고 가만히 있으면 회복된다. 바닥나면
## "지친" 상태가 되어 펀치가 약해지고 느려진다(EXHAUSTED_*). ---
const STAMINA_REGEN_PER_SEC := 6.0
const EXHAUSTED_DAMAGE_MULT := 0.6
const EXHAUSTED_COOLDOWN_MULT := 1.6

## --- 회피: 스태미나를 쓰고 잠깐 이동속도가 크게 붙으며, 그동안 받는
## 피해가 크게 줄어든다(완전 무적은 아님 - "거의 스쳐 맞음"에 가깝다). ---
const DODGE_STAMINA_COST := 12.0
const DODGE_DURATION := 0.25
const DODGE_SPEED_MULT := 2.2
const DODGE_COOLDOWN := 0.6
const DODGE_DAMAGE_REDUCTION := 0.85

## --- 카운터: 맞기 직전(가드를 든 지 얼마 안 됐을 때)에 정확히 막거나,
## 회피로 스치면 잠깐 카운터 판정이 열린다. 그 안에 펀치를 맞히면 보너스
## 데미지가 붙는다. ---
const PERFECT_BLOCK_WINDOW := 0.15
const COUNTER_WINDOW := 1.2
const COUNTER_BONUS_MULT := 1.5

## --- 다운/KO: 체력이 0이 되면 다운(is_down)되고, 카운트 안에 자동으로
## 일어난다(마시면 더 빨리). MAX_KNOCKDOWNS번째 다운은 그대로 KO로
## 끝난다(3-다운제). ---
const MAX_KNOCKDOWNS := 3
const KNOCKDOWN_RECOVERY_TIME := 3.0
const GETUP_HEALTH_RATIO := 0.35
const MASH_REDUCE_TIME := 0.3
const MIN_DOWN_TIME := 0.4

@export var stats: CharacterStats
var style: int = BoxingStyle.Style.BOXER_PUNCHER

var health: float
var stamina: float
var opponent: Fighter = null
var is_blocking := false
var is_staggered := false
var is_dodging := false
var is_down := false
var is_ko := false
var counter_ready := false
var knockdown_count := 0

var _punch_cooldown_left := 0.0
var _stagger_timer := 0.0
var _block_held_time := 0.0
var _dodge_timer := 0.0
var _dodge_cooldown_left := 0.0
var _dodge_direction := Vector3.ZERO
var _counter_ready_timer := 0.0
var _down_timer := 0.0
var _base_color := Color.WHITE
var _glove_rest_pos := Vector3.ZERO
var _punch_tween: Tween

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var glove: MeshInstance3D = $Glove


func _ready() -> void:
	if stats == null:
		stats = CharacterStats.new()
	health = get_effective_max_health()
	stamina = get_effective_max_stamina()
	_glove_rest_pos = glove.position
	var mat := mesh.get_surface_override_material(0)
	if mat:
		_base_color = mat.albedo_color


func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	if is_ko:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	if is_down:
		velocity.x = 0.0
		velocity.z = 0.0
		_down_timer -= delta
		if _down_timer <= 0.0:
			_get_up()
		move_and_slide()
		return

	if is_dodging:
		_dodge_timer -= delta
		var move_speed := get_effective_move_speed()
		velocity.x = _dodge_direction.x * move_speed * DODGE_SPEED_MULT
		velocity.z = _dodge_direction.z * move_speed * DODGE_SPEED_MULT
		if _dodge_timer <= 0.0:
			is_dodging = false

	if _dodge_cooldown_left > 0.0:
		_dodge_cooldown_left -= delta

	if _counter_ready_timer > 0.0:
		_counter_ready_timer -= delta
		if _counter_ready_timer <= 0.0:
			counter_ready = false

	if is_blocking:
		_block_held_time += delta
	else:
		_block_held_time = 0.0

	if _stagger_timer > 0.0:
		_stagger_timer -= delta
		if _stagger_timer <= 0.0:
			is_staggered = false

	if _punch_cooldown_left > 0.0:
		_punch_cooldown_left -= delta

	_regen_stamina(delta)

	_face_opponent()
	move_and_slide()
	_clamp_to_arena()


func _regen_stamina(delta: float) -> void:
	var max_stamina := get_effective_max_stamina()
	if stamina < max_stamina:
		stamina = min(stamina + STAMINA_REGEN_PER_SEC * delta, max_stamina)
		stamina_changed.emit(stamina, max_stamina)


func _face_opponent() -> void:
	if opponent == null or is_staggered:
		return
	var to_opp := opponent.global_position - global_position
	to_opp.y = 0.0
	if to_opp.length() > 0.01:
		look_at(global_position + to_opp, Vector3.UP)


func _clamp_to_arena() -> void:
	var flat := Vector2(global_position.x, global_position.z)
	if flat.length() > ARENA_RADIUS:
		flat = flat.normalized() * ARENA_RADIUS
		global_position.x = flat.x
		global_position.z = flat.y


## 현재 스타일이 반영된 최대체력/최대스태미나/이동속도/공격 사거리.
## CharacterStats가 기본값을 만들고 BoxingStyle.profile(style)이 그 위에
## 배율을 곱한다.
func get_effective_max_health() -> float:
	var health_mult: float = BoxingStyle.profile(style).get("health", 1.0)
	return stats.get_max_health() * health_mult


func get_effective_max_stamina() -> float:
	var stamina_mult: float = BoxingStyle.profile(style).get("stamina", 1.0)
	return stats.get_max_stamina() * stamina_mult


func get_effective_move_speed() -> float:
	var footwork_mult: float = BoxingStyle.profile(style).get("footwork", 1.0)
	return stats.get_move_speed() * footwork_mult


func get_effective_attack_range() -> float:
	var range_mult: float = BoxingStyle.profile(style).get("range", 1.0)
	return ATTACK_RANGE * range_mult


func try_punch(type: int) -> void:
	if is_ko or is_down or is_staggered or is_dodging or _punch_cooldown_left > 0.0:
		return
	var punch: Dictionary = PunchType.data(type)
	var stamina_cost: float = punch.stamina_cost
	var exhausted := stamina < stamina_cost
	stamina = max(stamina - stamina_cost, 0.0)
	stamina_changed.emit(stamina, get_effective_max_stamina())

	var stamina_mult: float = BoxingStyle.profile(style).get("stamina", 1.0)
	var cooldown_mult: float = punch.cooldown_mult * (EXHAUSTED_COOLDOWN_MULT if exhausted else 1.0)
	_punch_cooldown_left = BASE_PUNCH_COOLDOWN * stats.get_attack_cooldown_mult() / stamina_mult * cooldown_mult

	_play_punch_motion(type)
	await get_tree().create_timer(punch.startup).timeout

	var power_mult: float = BoxingStyle.profile(style).get("power", 1.0)
	var damage_mult: float = punch.damage_mult * power_mult * (EXHAUSTED_DAMAGE_MULT if exhausted else 1.0)
	if counter_ready:
		damage_mult *= COUNTER_BONUS_MULT
		counter_ready = false
	_resolve_attack(stats.get_punch_damage() * damage_mult, punch.guard_break, punch.range_mult)


func _resolve_attack(base_damage: float, guard_break: float, range_mult: float) -> void:
	if is_ko or is_down or opponent == null or opponent.is_ko or opponent.is_down:
		return
	var range: float = get_effective_attack_range() * range_mult
	if global_position.distance_to(opponent.global_position) <= range:
		opponent.take_damage(base_damage, guard_break)


## 실제 캐릭터 모델/애니메이션이 들어오기 전까지 임시로 쓰는 연출이다 -
## 몸통 캡슐과 "글러브"(작은 구) 하나를 코드로 직접 움직여서, 잽/스트레이트는
## 직선으로 짧게/길게 찌르고 훅은 옆에서 감아 들어오고 어퍼컷은 아래로
## 웅크렸다가 위로 솟구치는 식으로 4종의 궤적을 다르게 만들었다 - 눈으로
## "지금 무슨 펀치가 나갔는지" 구분하기 위한 용도. 실제 모델이 들어오면 이
## 자리를 AnimationPlayer 재생으로 바꾸면 된다.
func _play_punch_motion(type: int) -> void:
	if _punch_tween:
		_punch_tween.kill()
	var tw := create_tween()
	_punch_tween = tw

	match type:
		PunchType.Type.JAB:
			tw.tween_property(mesh, "position:z", -0.15, 0.06)
			tw.parallel().tween_property(glove, "position", _glove_rest_pos + Vector3(0, 0, -0.45), 0.07)
			tw.chain().tween_property(mesh, "position:z", 0.0, 0.09)
			tw.parallel().tween_property(glove, "position", _glove_rest_pos, 0.09)
		PunchType.Type.STRAIGHT:
			tw.tween_property(mesh, "position:z", -0.3, 0.1)
			tw.parallel().tween_property(glove, "position", _glove_rest_pos + Vector3(-0.05, -0.03, -0.7), 0.11)
			tw.chain().tween_property(mesh, "position:z", 0.0, 0.15)
			tw.parallel().tween_property(glove, "position", _glove_rest_pos, 0.15)
		PunchType.Type.HOOK:
			tw.tween_property(glove, "position", _glove_rest_pos + Vector3(0.35, 0.05, 0.15), 0.05)
			tw.parallel().tween_property(mesh, "rotation:y", 0.3, 0.05)
			tw.chain().tween_property(glove, "position", _glove_rest_pos + Vector3(-0.35, 0.0, -0.55), 0.13)
			tw.parallel().tween_property(mesh, "position:z", -0.2, 0.13)
			tw.parallel().tween_property(mesh, "rotation:y", -0.25, 0.13)
			tw.chain().tween_property(glove, "position", _glove_rest_pos, 0.14)
			tw.parallel().tween_property(mesh, "position:z", 0.0, 0.14)
			tw.parallel().tween_property(mesh, "rotation:y", 0.0, 0.14)
		PunchType.Type.UPPERCUT:
			tw.tween_property(glove, "position", _glove_rest_pos + Vector3(0, -0.35, 0.1), 0.07)
			tw.parallel().tween_property(mesh, "rotation:x", 0.12, 0.07)
			tw.chain().tween_property(glove, "position", _glove_rest_pos + Vector3(0, 0.4, -0.5), 0.13)
			tw.parallel().tween_property(mesh, "position:z", -0.25, 0.13)
			tw.parallel().tween_property(mesh, "rotation:x", -0.15, 0.13)
			tw.chain().tween_property(glove, "position", _glove_rest_pos, 0.16)
			tw.parallel().tween_property(mesh, "position:z", 0.0, 0.16)
			tw.parallel().tween_property(mesh, "rotation:x", 0.0, 0.16)


## 방향이 주어지지 않으면(스틱 중립) 상대 반대쪽으로 물러나는 회피가 된다.
func try_dodge(direction: Vector3) -> bool:
	if is_ko or is_down or is_staggered or is_dodging or _dodge_cooldown_left > 0.0:
		return false
	if stamina < DODGE_STAMINA_COST:
		return false
	stamina -= DODGE_STAMINA_COST
	stamina_changed.emit(stamina, get_effective_max_stamina())

	is_dodging = true
	_dodge_timer = DODGE_DURATION
	_dodge_cooldown_left = DODGE_COOLDOWN
	_dodge_direction = direction.normalized() if direction.length() > 0.01 else -_direction_to_opponent()
	return true


func _direction_to_opponent() -> Vector3:
	if opponent == null:
		return Vector3.FORWARD
	var dir := opponent.global_position - global_position
	dir.y = 0.0
	return dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD


func take_damage(amount: float, guard_break: float = 0.0) -> void:
	if is_ko or is_down:
		return
	var final_damage := amount
	if is_dodging:
		final_damage *= (1.0 - DODGE_DAMAGE_REDUCTION)
		_trigger_counter_ready()
	elif is_blocking:
		var defense_mult: float = BoxingStyle.profile(style).get("defense", 1.0)
		var block_mult: float = clampf(BLOCK_DAMAGE_MULT / defense_mult, 0.05, 1.0)
		final_damage *= lerpf(block_mult, 1.0, guard_break)
		if _block_held_time <= PERFECT_BLOCK_WINDOW:
			_trigger_counter_ready()

	health = max(health - final_damage, 0.0)
	health_changed.emit(health, get_effective_max_health())
	_flash_hit()

	if not is_blocking and not is_dodging:
		is_staggered = true
		_stagger_timer = STAGGER_TIME
	if health <= 0.0:
		_go_down()


func _trigger_counter_ready() -> void:
	counter_ready = true
	_counter_ready_timer = COUNTER_WINDOW


func _flash_hit() -> void:
	var mat := mesh.get_surface_override_material(0)
	if mat == null:
		return
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color", Color(1, 1, 1), 0.05)
	tw.tween_property(mat, "albedo_color", _base_color, 0.15)


## 체력이 0이 되면 호출된다. 세 번째 다운이면 그대로 경기가 끝나는 진짜
## KO, 아니면 회복 가능한 다운으로 처리한다.
func _go_down() -> void:
	knockdown_count += 1
	is_staggered = false
	if knockdown_count >= MAX_KNOCKDOWNS:
		_ko()
		return
	is_down = true
	_down_timer = KNOCKDOWN_RECOVERY_TIME
	knocked_down.emit(knockdown_count)


## 다운 중에 펀치 버튼 등을 눌러 호출하면 카운트를 앞당긴다.
func mash_get_up() -> void:
	if not is_down:
		return
	_down_timer = max(_down_timer - MASH_REDUCE_TIME, MIN_DOWN_TIME)


func _get_up() -> void:
	is_down = false
	health = get_effective_max_health() * GETUP_HEALTH_RATIO
	health_changed.emit(health, get_effective_max_health())
	recovered_from_down.emit()


func _ko() -> void:
	is_ko = true
	knocked_out.emit()
	var tw := create_tween()
	tw.tween_property(self, "rotation:z", deg_to_rad(90), 0.4)


func reset_fighter(spawn_position: Vector3) -> void:
	if _punch_tween:
		_punch_tween.kill()
		_punch_tween = null
	health = get_effective_max_health()
	stamina = get_effective_max_stamina()
	is_ko = false
	is_down = false
	knockdown_count = 0
	is_staggered = false
	is_blocking = false
	is_dodging = false
	counter_ready = false
	_down_timer = 0.0
	_dodge_timer = 0.0
	_dodge_cooldown_left = 0.0
	_counter_ready_timer = 0.0
	_block_held_time = 0.0
	rotation = Vector3.ZERO
	global_position = spawn_position
	mesh.position = Vector3.ZERO
	mesh.rotation = Vector3.ZERO
	glove.position = _glove_rest_pos
	health_changed.emit(health, get_effective_max_health())
	stamina_changed.emit(stamina, get_effective_max_stamina())

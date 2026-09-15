class_name Fighter
extends CharacterBody3D

## Shared logic for any fighter in the ring: movement/gravity, health,
## punch/block, hit feedback and knockout. PlayerController.gd and
## AIController.gd extend this and only decide *when* to move/attack (and,
## for the CPU, *which* boxing style to lean into right now).
##
## `style` (BoxingStyle.Style) scales every combat number computed from
## `stats` - max health, movement, attack range, cooldown recovery, block
## effectiveness - via BoxingStyle.profile(). Changing `style` mid-fight
## (AIController does this) changes how the fighter behaves immediately.

signal health_changed(current: float, max_value: float)
signal knocked_out

const GRAVITY := 20.0
const ARENA_RADIUS := 7.0

const STAGGER_TIME := 0.35
const BASE_PUNCH_COOLDOWN := 0.5
const ATTACK_RANGE := 2.2
const BLOCK_DAMAGE_MULT := 0.2

@export var stats: CharacterStats
var style: int = BoxingStyle.Style.BOXER_PUNCHER

var health: float
var opponent: Fighter = null
var is_blocking := false
var is_staggered := false
var is_ko := false

var _punch_cooldown_left := 0.0
var _stagger_timer := 0.0
var _base_color := Color.WHITE

@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	if stats == null:
		stats = CharacterStats.new()
	health = get_effective_max_health()
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

	if _stagger_timer > 0.0:
		_stagger_timer -= delta
		if _stagger_timer <= 0.0:
			is_staggered = false

	if _punch_cooldown_left > 0.0:
		_punch_cooldown_left -= delta

	_face_opponent()
	move_and_slide()
	_clamp_to_arena()


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


## 현재 스타일이 반영된 최대체력/이동속도/공격 사거리. CharacterStats가
## 기본값을 만들고 BoxingStyle.profile(style)이 그 위에 배율을 곱한다.
func get_effective_max_health() -> float:
	var health_mult: float = BoxingStyle.profile(style).get("health", 1.0)
	return stats.get_max_health() * health_mult


func get_effective_move_speed() -> float:
	var footwork_mult: float = BoxingStyle.profile(style).get("footwork", 1.0)
	return stats.get_move_speed() * footwork_mult


func get_effective_attack_range() -> float:
	var range_mult: float = BoxingStyle.profile(style).get("range", 1.0)
	return ATTACK_RANGE * range_mult


func try_punch() -> void:
	if is_ko or is_staggered or _punch_cooldown_left > 0.0:
		return
	var stamina_mult: float = BoxingStyle.profile(style).get("stamina", 1.0)
	_punch_cooldown_left = BASE_PUNCH_COOLDOWN * stats.get_attack_cooldown_mult() / stamina_mult
	_play_attack_lunge()
	await get_tree().create_timer(0.15).timeout
	var power_mult: float = BoxingStyle.profile(style).get("power", 1.0)
	_resolve_attack(stats.get_punch_damage() * power_mult)


func _resolve_attack(base_damage: float) -> void:
	if is_ko or opponent == null or opponent.is_ko:
		return
	if global_position.distance_to(opponent.global_position) <= get_effective_attack_range():
		opponent.take_damage(base_damage)


func _play_attack_lunge() -> void:
	var tw := create_tween()
	tw.tween_property(mesh, "position:z", -0.3, 0.08)
	tw.tween_property(mesh, "position:z", 0.0, 0.12)


func take_damage(amount: float) -> void:
	if is_ko:
		return
	var final_damage := amount
	if is_blocking:
		var defense_mult: float = BoxingStyle.profile(style).get("defense", 1.0)
		final_damage *= clampf(BLOCK_DAMAGE_MULT / defense_mult, 0.05, 1.0)
	health = max(health - final_damage, 0.0)
	health_changed.emit(health, get_effective_max_health())
	_flash_hit()
	if not is_blocking:
		is_staggered = true
		_stagger_timer = STAGGER_TIME
	if health <= 0.0:
		_ko()


func _flash_hit() -> void:
	var mat := mesh.get_surface_override_material(0)
	if mat == null:
		return
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color", Color(1, 1, 1), 0.05)
	tw.tween_property(mat, "albedo_color", _base_color, 0.15)


func _ko() -> void:
	is_ko = true
	knocked_out.emit()
	var tw := create_tween()
	tw.tween_property(self, "rotation:z", deg_to_rad(90), 0.4)


func reset_fighter(spawn_position: Vector3) -> void:
	health = get_effective_max_health()
	is_ko = false
	is_staggered = false
	is_blocking = false
	rotation = Vector3.ZERO
	global_position = spawn_position
	mesh.position = Vector3.ZERO
	health_changed.emit(health, get_effective_max_health())

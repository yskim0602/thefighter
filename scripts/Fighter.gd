class_name Fighter
extends CharacterBody3D

## Shared logic for any fighter in the cage: movement/gravity, health,
## punch/kick/block, hit feedback and knockout. PlayerController.gd and
## AIController.gd extend this and only decide *when* to move/attack.

signal health_changed(current: float, max_value: float)
signal knocked_out

const GRAVITY := 20.0
const ARENA_RADIUS := 7.0

const STAGGER_TIME := 0.35
const BASE_PUNCH_COOLDOWN := 0.5
const BASE_KICK_COOLDOWN := 0.9
const ATTACK_RANGE := 2.2
const BLOCK_DAMAGE_MULT := 0.2

@export var stats: CharacterStats

var health: float
var opponent: Fighter = null
var is_blocking := false
var is_staggered := false
var is_ko := false

var _punch_cooldown_left := 0.0
var _kick_cooldown_left := 0.0
var _stagger_timer := 0.0
var _base_color := Color.WHITE

@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	if stats == null:
		stats = CharacterStats.new()
	health = stats.get_max_health()
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
	if _kick_cooldown_left > 0.0:
		_kick_cooldown_left -= delta

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


func try_punch() -> void:
	if is_ko or is_staggered or _punch_cooldown_left > 0.0:
		return
	_punch_cooldown_left = BASE_PUNCH_COOLDOWN * stats.get_attack_cooldown_mult()
	_play_attack_lunge()
	await get_tree().create_timer(0.15).timeout
	_resolve_attack(stats.get_punch_damage())


func try_kick() -> void:
	if is_ko or is_staggered or _kick_cooldown_left > 0.0:
		return
	_kick_cooldown_left = BASE_KICK_COOLDOWN * stats.get_attack_cooldown_mult()
	_play_attack_lunge()
	await get_tree().create_timer(0.25).timeout
	_resolve_attack(stats.get_kick_damage())


func _resolve_attack(base_damage: float) -> void:
	if is_ko or opponent == null or opponent.is_ko:
		return
	if global_position.distance_to(opponent.global_position) <= ATTACK_RANGE:
		var advantage := FightingStyle.get_advantage_multiplier(stats.style, opponent.stats.style)
		opponent.take_damage(base_damage * advantage)


func _play_attack_lunge() -> void:
	var tw := create_tween()
	tw.tween_property(mesh, "position:z", -0.3, 0.08)
	tw.tween_property(mesh, "position:z", 0.0, 0.12)


func take_damage(amount: float) -> void:
	if is_ko:
		return
	var final_damage := amount
	if is_blocking:
		final_damage *= BLOCK_DAMAGE_MULT
	health = max(health - final_damage, 0.0)
	health_changed.emit(health, stats.get_max_health())
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
	health = stats.get_max_health()
	is_ko = false
	is_staggered = false
	is_blocking = false
	rotation = Vector3.ZERO
	global_position = spawn_position
	mesh.position = Vector3.ZERO
	health_changed.emit(health, stats.get_max_health())

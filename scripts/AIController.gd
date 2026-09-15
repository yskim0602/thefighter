extends Fighter

## CPU 상대. 능력치는 MatchContext.current_offer(수락한 경기 제의)에서
## 가져오고, 복싱 스타일(archetype)에 따라 이동/공격/블록 파라미터를 다르게
## 적용한다. 실제 고급 AI(상태머신, 애니메이션 연동)는 나중 단계 작업이고,
## 지금은 기존 단순 AI의 파라미터를 archetype별로 조정하는 정도로 구조만
## 확장해뒀다.

var attack_min_interval := 0.8
var attack_max_interval := 1.8
var block_chance := 0.25
var block_duration := 0.6
var approach_speed_mult := 0.8

var _decision_timer := 0.0
var _block_timer := 0.0
var _archetype: int = -1


func _ready() -> void:
	var offer := MatchContext.current_offer
	stats = CharacterStats.new()
	if offer != null:
		var stage := SaveManager.career.stage
		var base_stat := 12 + stage * 2
		stats.fighter_name = offer.opponent_name
		stats.power = int(base_stat * offer.stat_multiplier)
		stats.stamina = int(base_stat * offer.stat_multiplier)
		stats.speed = int((10 + stage) * offer.stat_multiplier)
		stats.skill = int((10 + stage) * offer.stat_multiplier)
		_archetype = offer.archetype
		_apply_archetype_tuning(offer.archetype)
	else:
		# MatchContext에 제의가 없는 상태로 씬을 바로 실행한 경우(에디터 테스트 등)를
		# 위한 안전한 기본값 - 고정 스파링 상대.
		var win_bonus := int(SaveManager.career.wins / 3)
		stats.fighter_name = "무명 파이터"
		stats.power = 14 + win_bonus
		stats.stamina = 14 + win_bonus
		stats.speed = 10 + win_bonus
		stats.skill = 12 + win_bonus
	super._ready()
	if _archetype == CareerConfig.Archetype.COUNTER:
		health_changed.connect(_on_self_damaged)


## 복싱 스타일별로 기존 파라미터를 다르게 튜닝한다. 값 자체는 예시 수준이고,
## 나중에 실제 밸런스에 맞춰 조정하면 된다.
func _apply_archetype_tuning(archetype: int) -> void:
	match archetype:
		CareerConfig.Archetype.BOXER:
			block_chance = 0.15
		CareerConfig.Archetype.BRAWLER:
			attack_min_interval = 0.4
			attack_max_interval = 0.9
			block_chance = 0.05
			approach_speed_mult = 1.1
		CareerConfig.Archetype.COUNTER:
			block_chance = 0.45
			attack_min_interval = 1.0
			attack_max_interval = 2.2
		CareerConfig.Archetype.DEFENSIVE:
			block_chance = 0.55
			attack_min_interval = 1.2
			attack_max_interval = 2.4


## 카운터형: 얻어맞은 직후 곧바로 다시 판단해서 반격을 노린다.
func _on_self_damaged(_current: float, _max_health: float) -> void:
	if not is_ko and not is_staggered:
		_decision_timer = 0.0


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
	_decision_timer = randf_range(attack_min_interval, attack_max_interval)
	if opponent == null:
		return

	var dist := global_position.distance_to(opponent.global_position)
	if dist > ATTACK_RANGE:
		var dir := opponent.global_position - global_position
		dir.y = 0.0
		dir = dir.normalized()
		var move_speed := stats.get_move_speed()
		velocity.x = dir.x * move_speed * approach_speed_mult
		velocity.z = dir.z * move_speed * approach_speed_mult
		return

	velocity.x = 0.0
	velocity.z = 0.0
	var roll := randf()
	if roll < block_chance:
		_block_timer = block_duration
	else:
		try_punch()

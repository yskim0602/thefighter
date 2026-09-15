extends Fighter

## CPU 상대. 능력치는 MatchContext.current_offer(수락한 경기 제의)에서
## 가져오고, 매치메이킹이 정해준 "성향"(_base_style, BoxingStyle.Style)에서
## 시작한다. 하지만 스타일은 고정된 직업이 아니다 - 경기 흐름에 따라
## `style`(Fighter.gd가 전투 수치 배율을 읽는 바로 그 필드)이 실시간으로
## 바뀐다:
##   - 초반(EARLY_PHASE_SECONDS 이내)에는 아웃복서로 거리를 재고,
##   - 자기 체력이 위험 수위(LOW_HEALTH_RATIO)로 떨어지면 인파이터로 붙어서
##     승부를 걸고,
##   - 방금 얻어맞았다면 잠깐(COUNTER_REACTION_TIME) 카운터펀처로 전환해서
##     곧바로 반격을 노린다.
## 그 외의 경우는 자기 본연의 성향(_base_style)으로 돌아온다.

const EARLY_PHASE_SECONDS := 12.0
const LOW_HEALTH_RATIO := 0.35
const COUNTER_REACTION_TIME := 1.4
const RETREAT_DISTANCE := 1.4

var attack_min_interval := 0.8
var attack_max_interval := 1.8
var block_chance := 0.25
var block_duration := 0.6
var approach_speed_mult := 0.8
## 아웃복서 성향일 때만 켜진다 - 너무 가까워지면 붙어 싸우는 대신 물러난다.
var maintain_distance := false

var _decision_timer := 0.0
var _block_timer := 0.0
var _base_style: int = BoxingStyle.Style.BOXER_PUNCHER
var _fight_elapsed := 0.0
var _counter_window_left := 0.0


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
		_base_style = offer.archetype
	else:
		# MatchContext에 제의가 없는 상태로 씬을 바로 실행한 경우(에디터 테스트 등)를
		# 위한 안전한 기본값 - 고정 스파링 상대.
		var win_bonus := int(SaveManager.career.wins / 3)
		stats.fighter_name = "무명 파이터"
		stats.power = 14 + win_bonus
		stats.stamina = 14 + win_bonus
		stats.speed = 10 + win_bonus
		stats.skill = 12 + win_bonus
		_base_style = BoxingStyle.Style.BOXER_PUNCHER
	style = _base_style
	_apply_style_tuning(style)
	super._ready()
	health_changed.connect(_on_self_damaged)


## 스타일별로 "어떻게 싸우는가"(공격 빈도/블록 확률/접근 방식)를 튜닝한다.
## 데미지/체력/사거리 같은 실제 전투 수치 배율은 BoxingStyle.profile()이
## Fighter.gd에서 직접 적용하므로 여기서는 다루지 않는다.
func _apply_style_tuning(s: int) -> void:
	maintain_distance = false
	match s:
		BoxingStyle.Style.OUT_BOXER:
			attack_min_interval = 1.0
			attack_max_interval = 2.0
			block_chance = 0.2
			approach_speed_mult = 1.1
			maintain_distance = true
		BoxingStyle.Style.IN_FIGHTER:
			attack_min_interval = 0.45
			attack_max_interval = 0.9
			block_chance = 0.1
			approach_speed_mult = 1.15
		BoxingStyle.Style.SLUGGER:
			attack_min_interval = 1.3
			attack_max_interval = 2.4
			block_chance = 0.1
			approach_speed_mult = 0.7
		BoxingStyle.Style.BOXER_PUNCHER:
			attack_min_interval = 0.8
			attack_max_interval = 1.6
			block_chance = 0.2
			approach_speed_mult = 0.9
		BoxingStyle.Style.COUNTER_PUNCHER:
			attack_min_interval = 1.1
			attack_max_interval = 2.2
			block_chance = 0.45
			approach_speed_mult = 0.8
		BoxingStyle.Style.PRESSURE_FIGHTER:
			attack_min_interval = 0.55
			attack_max_interval = 1.1
			block_chance = 0.15
			approach_speed_mult = 1.2


func _set_dynamic_style(s: int) -> void:
	if style == s:
		return
	style = s
	_apply_style_tuning(style)


## 경기 흐름(시간 경과/체력)만 보고 스타일을 정한다. 카운터 반응 중에는
## 호출하지 않는다 - 얻어맞은 직후의 반격 태세를 다른 조건이 곧바로
## 덮어써버리지 않도록.
func _update_dynamic_style() -> void:
	var hp_ratio: float = health / get_effective_max_health()
	if hp_ratio <= LOW_HEALTH_RATIO:
		_set_dynamic_style(BoxingStyle.Style.IN_FIGHTER)
	elif _fight_elapsed <= EARLY_PHASE_SECONDS:
		_set_dynamic_style(BoxingStyle.Style.OUT_BOXER)
	else:
		_set_dynamic_style(_base_style)


## 얻어맞은 직후에는 잠깐 카운터펀처 태세로 전환해서 곧바로 반격을 노린다.
func _on_self_damaged(_current: float, _max_health: float) -> void:
	if is_ko or is_staggered:
		return
	_counter_window_left = COUNTER_REACTION_TIME
	_decision_timer = 0.0
	_set_dynamic_style(BoxingStyle.Style.COUNTER_PUNCHER)


func _physics_process(delta: float) -> void:
	if is_ko or is_staggered:
		velocity.x = 0.0
		velocity.z = 0.0
		is_blocking = false
		super._physics_process(delta)
		return

	_fight_elapsed += delta
	if _counter_window_left > 0.0:
		_counter_window_left -= delta
		if _counter_window_left <= 0.0:
			_update_dynamic_style()

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
	if _counter_window_left <= 0.0:
		_update_dynamic_style()
	if opponent == null:
		return

	var dist := global_position.distance_to(opponent.global_position)
	var move_speed := get_effective_move_speed()
	var attack_range := get_effective_attack_range()

	if maintain_distance and dist < RETREAT_DISTANCE and _counter_window_left <= 0.0:
		var away := global_position - opponent.global_position
		away.y = 0.0
		away = away.normalized()
		velocity.x = away.x * move_speed * approach_speed_mult
		velocity.z = away.z * move_speed * approach_speed_mult
		return

	if dist > attack_range:
		var dir := opponent.global_position - global_position
		dir.y = 0.0
		dir = dir.normalized()
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

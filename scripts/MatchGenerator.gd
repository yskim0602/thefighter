class_name MatchGenerator
extends RefCounted

## 현재 커리어 상태를 보고 다음 경기 제의를 만든다. 상대 능력치는 스테이지와
## 난이도 배율로부터 계산한다 (실제 로스터/정교한 AI는 나중에 이 함수들만
## 바꿔 끼우면 되도록 구조를 분리해뒀다).

static func generate(career: CareerData) -> OpponentOffer:
	if career.is_ranked_stage():
		return _generate_ranked_offer(career)
	if career.promotion_ready:
		return _generate_promotion_offer(career)
	return _generate_regular_offer(career)


static func _pick_difficulty() -> int:
	var roll := randf()
	var acc := 0.0
	for difficulty in CareerConfig.DIFFICULTY_WEIGHTS:
		acc += CareerConfig.DIFFICULTY_WEIGHTS[difficulty]
		if roll <= acc:
			return difficulty
	return CareerConfig.Difficulty.EVEN


static func _random_name() -> String:
	var first: String = CareerConfig.OPPONENT_FIRST_NAMES[randi() % CareerConfig.OPPONENT_FIRST_NAMES.size()]
	var last: String = CareerConfig.OPPONENT_LAST_NAMES[randi() % CareerConfig.OPPONENT_LAST_NAMES.size()]
	return first + last


static func _random_archetype(stage: int) -> int:
	var pool: Array = CareerConfig.ARCHETYPE_POOL_BY_STAGE[clampi(stage, 0, CareerConfig.ARCHETYPE_POOL_BY_STAGE.size() - 1)]
	return pool[randi() % pool.size()]


static func _base_offer(career: CareerData) -> OpponentOffer:
	var offer := OpponentOffer.new()
	var difficulty := _pick_difficulty()
	offer.difficulty = difficulty
	offer.stat_multiplier = CareerConfig.DIFFICULTY_STAT_MULT[difficulty]
	offer.archetype = _random_archetype(career.stage)
	offer.style = randi() % 5  # FightingStyle.Style 값 개수(5)에 맞춤
	offer.opponent_name = _random_name()
	offer.wins = randi_range(2, 8) + career.stage * 3
	offer.losses = randi_range(1, 6)
	if difficulty == CareerConfig.Difficulty.HARD and randf() < 0.5:
		offer.is_main_event = true

	var reward_mult: float = CareerConfig.DIFFICULTY_REWARD_MULT[difficulty]
	offer.money_reward = int((CareerConfig.BASE_MONEY_REWARD + career.wins * CareerConfig.MONEY_PER_WIN) * reward_mult)
	offer.fan_reward = int(CareerConfig.BASE_FAN_REWARD * reward_mult * (1.0 + career.stage * 0.3))
	offer.fame_reward = int(CareerConfig.BASE_FAME_REWARD * reward_mult * (1.0 + career.stage * 0.3))
	return offer


static func _generate_regular_offer(career: CareerData) -> OpponentOffer:
	var pending_rival = _find_undefeated_rival(career)
	if pending_rival != null and randf() < CareerConfig.RIVAL_REMATCH_CHANCE:
		return _rival_offer(career, pending_rival)

	var offer := _base_offer(career)
	if pending_rival == null and randf() < CareerConfig.RIVAL_CHANCE:
		offer.is_rival = true
		career.rivals.append({"name": offer.opponent_name, "defeated": false})
	return offer


static func _rival_offer(career: CareerData, rival: Dictionary) -> OpponentOffer:
	var offer := _base_offer(career)
	offer.opponent_name = rival["name"]
	offer.is_rival = true
	offer.money_reward = int(offer.money_reward * 1.5)
	offer.fan_reward = int(offer.fan_reward * 1.8)
	offer.fame_reward = int(offer.fame_reward * 1.8)
	return offer


static func _find_undefeated_rival(career: CareerData):
	for rival in career.rivals:
		if not rival.get("defeated", false):
			return rival
	return null


static func _generate_promotion_offer(career: CareerData) -> OpponentOffer:
	var offer := _base_offer(career)
	offer.opponent_name = "%s 대표 선수" % career.stage_name()
	offer.difficulty = CareerConfig.Difficulty.HARD
	offer.stat_multiplier = CareerConfig.DIFFICULTY_STAT_MULT[CareerConfig.Difficulty.HARD]
	offer.is_promotion_match = true
	offer.money_reward = int(offer.money_reward * 2.0)
	offer.fan_reward = int(offer.fan_reward * 2.0)
	offer.fame_reward = int(offer.fame_reward * 2.0)
	return offer


static func _generate_ranked_offer(career: CareerData) -> OpponentOffer:
	if career.is_champion:
		return _generate_title_defense_offer(career)
	if career.stage == CareerData.Stage.TITLE_SHOT:
		return _generate_title_shot_offer(career, true)
	if career.rank <= CareerConfig.RANK_TITLE_SHOT_THRESHOLD:
		return _generate_title_shot_offer(career, false)

	var offer := _base_offer(career)
	var shown_rank: int = max(career.rank - randi_range(1, 5), 1)
	offer.opponent_name = "RANK %d %s" % [shown_rank, offer.opponent_name]
	return offer


static func _generate_title_shot_offer(career: CareerData, is_final: bool) -> OpponentOffer:
	var offer := _base_offer(career)
	offer.difficulty = CareerConfig.Difficulty.HARD
	offer.stat_multiplier = CareerConfig.DIFFICULTY_STAT_MULT[CareerConfig.Difficulty.HARD]
	if is_final:
		offer.is_championship = true
		offer.opponent_name = "챔피언 " + offer.opponent_name
	else:
		offer.is_title_shot = true
		offer.opponent_name = "랭킹 1위 " + offer.opponent_name
	offer.money_reward = int(offer.money_reward * 3.0)
	offer.fan_reward = int(offer.fan_reward * 3.0)
	offer.fame_reward = int(offer.fame_reward * 3.0)
	return offer


static func _generate_title_defense_offer(career: CareerData) -> OpponentOffer:
	var offer := _base_offer(career)
	offer.difficulty = CareerConfig.Difficulty.HARD
	offer.stat_multiplier = CareerConfig.DIFFICULTY_STAT_MULT[CareerConfig.Difficulty.HARD]
	offer.is_title_defense = true
	offer.opponent_name = "도전자 " + offer.opponent_name
	offer.money_reward = int(offer.money_reward * 2.5)
	offer.fan_reward = int(offer.fan_reward * 2.5)
	offer.fame_reward = int(offer.fame_reward * 2.5)
	return offer

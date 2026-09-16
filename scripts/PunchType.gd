class_name PunchType
extends RefCounted

## 복싱 펀치 4종. 잽은 빠르고 가볍게 견제하는 용도, 어퍼컷은 느리지만 크게
## 데미지를 넣고 가드 위로도 어느 정도 피해가 관통되는 용도로 설계했다.
## damage_mult/stamina_cost는 CharacterStats.get_punch_damage()에 곱/차감되고,
## startup은 스윙이 실제로 맞기까지의 선딜레이(초), cooldown_mult는
## 다음 펀치까지의 대기시간 배율, range_mult는 사거리 배율, guard_break는
## 가드로 막아도 관통되는 피해 비율(0=완전 차단 가능, 1=가드 무의미)이다.
## body_chance는 이 펀치가 머리 대신 몸통에 맞을 확률이다(Fighter.HitPart) -
## 훅은 몸통을 노리기 쉽고, 어퍼컷은 거의 항상 턱(머리)을 노린다.
##
## hand_role은 이 펀치를 앞손(LEAD)/뒷손(REAR) 중 어느 손으로 던지는지다
## (복싱의 기본 4펀치 구성: 1=잽(앞손), 2=스트레이트(뒷손), 3=훅(앞손),
## 4=어퍼컷(뒷손)과 동일). 실제로 어느 쪽 손(왼손/오른손)이 앞손인지는
## Fighter.Stance(오소독스/사우스포)에 따라 달라진다 - Fighter.gd가
## _hand_for_role()로 그때그때 계산한다.

enum Type { JAB, STRAIGHT, HOOK, UPPERCUT }
enum Role { LEAD, REAR }

const DATA := {
	Type.JAB: {
		"damage_mult": 0.75, "stamina_cost": 4.0, "startup": 0.08,
		"cooldown_mult": 0.7, "range_mult": 1.05, "guard_break": 0.0,
		"body_chance": 0.15, "hand_role": Role.LEAD,
	},
	Type.STRAIGHT: {
		"damage_mult": 1.0, "stamina_cost": 7.0, "startup": 0.13,
		"cooldown_mult": 1.0, "range_mult": 1.0, "guard_break": 0.1,
		"body_chance": 0.2, "hand_role": Role.REAR,
	},
	Type.HOOK: {
		"damage_mult": 1.3, "stamina_cost": 10.0, "startup": 0.18,
		"cooldown_mult": 1.25, "range_mult": 0.85, "guard_break": 0.2,
		"body_chance": 0.45, "hand_role": Role.LEAD,
	},
	Type.UPPERCUT: {
		"damage_mult": 1.6, "stamina_cost": 13.0, "startup": 0.22,
		"cooldown_mult": 1.5, "range_mult": 0.75, "guard_break": 0.4,
		"body_chance": 0.1, "hand_role": Role.REAR,
	},
}

const NAMES := {
	Type.JAB: "잽",
	Type.STRAIGHT: "스트레이트",
	Type.HOOK: "훅",
	Type.UPPERCUT: "어퍼컷",
}


static func data(type: int) -> Dictionary:
	return DATA.get(type, DATA[Type.JAB])


static func type_name(type: int) -> String:
	return NAMES.get(type, "?")

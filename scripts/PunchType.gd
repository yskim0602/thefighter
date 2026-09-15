class_name PunchType
extends RefCounted

## 복싱 펀치 4종. 잽은 빠르고 가볍게 견제하는 용도, 어퍼컷은 느리지만 크게
## 데미지를 넣고 가드 위로도 어느 정도 피해가 관통되는 용도로 설계했다.
## damage_mult/stamina_cost는 CharacterStats.get_punch_damage()에 곱/차감되고,
## startup은 스윙이 실제로 맞기까지의 선딜레이(초), cooldown_mult는
## 다음 펀치까지의 대기시간 배율, range_mult는 사거리 배율, guard_break는
## 가드로 막아도 관통되는 피해 비율(0=완전 차단 가능, 1=가드 무의미)이다.

enum Type { JAB, STRAIGHT, HOOK, UPPERCUT }

const DATA := {
	Type.JAB: {
		"damage_mult": 0.75, "stamina_cost": 4.0, "startup": 0.08,
		"cooldown_mult": 0.7, "range_mult": 1.05, "guard_break": 0.0,
	},
	Type.STRAIGHT: {
		"damage_mult": 1.0, "stamina_cost": 7.0, "startup": 0.13,
		"cooldown_mult": 1.0, "range_mult": 1.0, "guard_break": 0.1,
	},
	Type.HOOK: {
		"damage_mult": 1.3, "stamina_cost": 10.0, "startup": 0.18,
		"cooldown_mult": 1.25, "range_mult": 0.85, "guard_break": 0.2,
	},
	Type.UPPERCUT: {
		"damage_mult": 1.6, "stamina_cost": 13.0, "startup": 0.22,
		"cooldown_mult": 1.5, "range_mult": 0.75, "guard_break": 0.4,
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

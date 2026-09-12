class_name FightingStyle
extends RefCounted

## 단순화한 MMA "먹이사슬" 상성:
## 테이크다운 그래플러(레슬링/유도)가 타격가(복싱/무에타이)를 이긴다 (거리를 없애고 눕힌다)
## 그라운드 그래플러(주짓수)가 테이크다운 그래플러를 이긴다 (넘어지면 서브미션으로 받아친다)
## 타격가(복싱/무에타이)가 그라운드 그래플러를 이긴다 (거리를 유지하며 테이크다운을 스프롤한다)
## 이 3항 순환 구조가 가위바위보처럼 스타일 선택에 전략을 만든다.

enum Style { BOXING, MUAY_THAI, WRESTLING, JUDO, BJJ }

const STRIKERS: Array = [Style.BOXING, Style.MUAY_THAI]
const TAKEDOWN_GRAPPLERS: Array = [Style.WRESTLING, Style.JUDO]
const GROUND_GRAPPLERS: Array = [Style.BJJ]

const ADVANTAGE_MULT := 1.25
const DISADVANTAGE_MULT := 0.85


static func get_advantage_multiplier(attacker: int, defender: int) -> float:
	if attacker in TAKEDOWN_GRAPPLERS and defender in STRIKERS:
		return ADVANTAGE_MULT
	if attacker in GROUND_GRAPPLERS and defender in TAKEDOWN_GRAPPLERS:
		return ADVANTAGE_MULT
	if attacker in STRIKERS and defender in GROUND_GRAPPLERS:
		return ADVANTAGE_MULT

	if attacker in STRIKERS and defender in TAKEDOWN_GRAPPLERS:
		return DISADVANTAGE_MULT
	if attacker in TAKEDOWN_GRAPPLERS and defender in GROUND_GRAPPLERS:
		return DISADVANTAGE_MULT
	if attacker in GROUND_GRAPPLERS and defender in STRIKERS:
		return DISADVANTAGE_MULT

	return 1.0


static func style_name(style: int) -> String:
	match style:
		Style.BOXING:
			return "복싱"
		Style.MUAY_THAI:
			return "무에타이"
		Style.WRESTLING:
			return "레슬링"
		Style.JUDO:
			return "유도"
		Style.BJJ:
			return "주짓수"
	return "?"

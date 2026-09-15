class_name BoxingStyle
extends RefCounted

## 복싱 스타일 6종. 고정된 "직업"이 아니라 전투 파라미터에 곱해지는 배율
## 묶음이다 - CPU는 경기 상황에 따라 AIController.gd에서 이 값을 실시간으로
## 바꿔가며 싸우고(초반엔 아웃복서로 거리를 재다가, 체력이 위험해지면
## 인파이터로 붙고, 얻어맞은 직후엔 카운터펀처로 반응하는 식), 플레이어는
## infer_style()로 훈련한 능력치 분포에서 자연스럽게 스타일이 정해진다.

enum Style {
	OUT_BOXER,       # 아웃복서: 거리 유지, 빠른 풋워크·잽 중심
	IN_FIGHTER,      # 인파이터: 근접 압박, 연타·훅·어퍼 중심
	SLUGGER,         # 슬러거: 느리지만 강력한 한 방과 KO 능력
	BOXER_PUNCHER,   # 복서-펀처: 스피드·파워·기술이 균형 잡힌 올라운더
	COUNTER_PUNCHER, # 카운터펀처: 상대 공격의 빈틈을 노려 카운터
	PRESSURE_FIGHTER,# 프레셔 파이터: 지속적인 전진과 공격량으로 압박
}

const NAMES := {
	Style.OUT_BOXER: "아웃복서",
	Style.IN_FIGHTER: "인파이터",
	Style.SLUGGER: "슬러거",
	Style.BOXER_PUNCHER: "복서-펀처",
	Style.COUNTER_PUNCHER: "카운터펀처",
	Style.PRESSURE_FIGHTER: "프레셔 파이터",
}

## 전투 수치 배율(1.0 = 평균). Fighter.gd가 CharacterStats로 계산한 기본
## 수치 위에 이 값을 곱한다.
## power=공격력, footwork=이동속도, health=체력, stamina=공격 쿨다운 회복
## (높을수록 다음 공격이 빨리 나옴), defense=블록 시 피해 감소 강화,
## range=공격 사거리.
const PROFILES := {
	Style.OUT_BOXER: {
		"power": 0.85, "footwork": 1.35, "health": 0.9, "stamina": 1.05,
		"defense": 1.0, "range": 1.2,
	},
	Style.IN_FIGHTER: {
		"power": 1.15, "footwork": 0.9, "health": 1.05, "stamina": 0.9,
		"defense": 0.85, "range": 0.75,
	},
	Style.SLUGGER: {
		"power": 1.5, "footwork": 0.65, "health": 1.15, "stamina": 0.85,
		"defense": 0.8, "range": 0.9,
	},
	Style.BOXER_PUNCHER: {
		"power": 1.0, "footwork": 1.0, "health": 1.0, "stamina": 1.0,
		"defense": 1.0, "range": 1.0,
	},
	Style.COUNTER_PUNCHER: {
		"power": 1.1, "footwork": 1.05, "health": 0.95, "stamina": 0.95,
		"defense": 1.2, "range": 1.0,
	},
	Style.PRESSURE_FIGHTER: {
		"power": 1.0, "footwork": 1.1, "health": 1.1, "stamina": 0.8,
		"defense": 0.9, "range": 0.85,
	},
}

## 플레이어 스타일 추론용 가중치. CharacterStats의 4개 훈련 능력치
## (power/stamina/speed/skill)가 각 스타일의 이상적인 분포와 얼마나
## 가까운지 비교해서 가장 가까운 스타일을 고른다 - 훈련 방향이 곧 스타일이
## 되는 구조라, 플레이어가 스타일을 직접 고르지 않아도 성장 방식대로
## 자연스럽게 자기 스타일이 생긴다.
const GROWTH_WEIGHTS := {
	Style.OUT_BOXER: {"power": 0.6, "stamina": 0.8, "speed": 1.3, "skill": 1.2},
	Style.IN_FIGHTER: {"power": 1.2, "stamina": 1.2, "speed": 0.8, "skill": 0.7},
	Style.SLUGGER: {"power": 1.5, "stamina": 1.0, "speed": 0.6, "skill": 0.6},
	Style.BOXER_PUNCHER: {"power": 1.0, "stamina": 1.0, "speed": 1.0, "skill": 1.0},
	Style.COUNTER_PUNCHER: {"power": 0.9, "stamina": 0.8, "speed": 1.0, "skill": 1.4},
	Style.PRESSURE_FIGHTER: {"power": 1.1, "stamina": 1.4, "speed": 1.0, "skill": 0.6},
}


static func style_name(style: int) -> String:
	return NAMES.get(style, "?")


static func profile(style: int) -> Dictionary:
	return PROFILES.get(style, PROFILES[Style.BOXER_PUNCHER])


## stats의 능력치 분포와 코사인 유사도가 가장 높은 스타일을 고른다.
## 가중치 벡터 크기로 정규화해서, 특정 스타일의 가중치 합이 크다고 해서
## 유리해지지 않도록 한다 (그래서 기본 능력치 10/10/10/10인 신인 선수는
## 가장 균형 잡힌 복서-펀처로 시작한다).
static func infer_style(stats: CharacterStats) -> int:
	var best_style: int = Style.BOXER_PUNCHER
	var best_score := -INF
	for style in GROWTH_WEIGHTS:
		var w: Dictionary = GROWTH_WEIGHTS[style]
		var dot: float = stats.power * w.power + stats.stamina * w.stamina \
			+ stats.speed * w.speed + stats.skill * w.skill
		var w_len: float = sqrt(w.power ** 2 + w.stamina ** 2 + w.speed ** 2 + w.skill ** 2)
		var score: float = dot / w_len
		if score > best_score:
			best_score = score
			best_style = style
	return best_style

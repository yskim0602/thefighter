class_name CareerConfig
extends RefCounted

## 커리어/매치메이킹 관련 모든 튜닝 수치를 한곳에 모아둔다. 스테이지 수,
## 스테이지당 필요 경기/승수, 랭크 임계값, 보상 공식, 상대 AI 스타일 목록
## 전부 여기서 관리한다 - 밸런스를 바꿀 땐 이 파일만 건드리면 된다.

## --- 스테이지 0~5 (UNDERGROUND ~ WORLD SERIES): 승수 기반 승급 ---
const STAGE_FIGHTS_REQUIRED := 10
const STAGE_WINS_REQUIRED := 7

## CareerData.Stage.RANKED와 같은 값(6). 이 인덱스부터는 승수 대신 랭크
## 숫자로 진행한다. (CareerConfig는 CareerData를 참조하지 않도록 정수로 고정)
const RANKED_STAGE_INDEX := 6

## --- 스테이지 6~9 (RANKED ~ CHAMPIONSHIP): 랭크 기반 진행 ---
const RANK_START := 30
const RANK_TOP10_THRESHOLD := 10
const RANK_TITLE_SHOT_THRESHOLD := 1
const RANK_GAIN_MIN := 1
const RANK_GAIN_MAX := 3
const RANK_LOSS_ON_DEFEAT := 1

const TITLE_DEFENSES_FOR_LEGEND := 5

## --- 상대 AI의 기본 성향(archetype). 실제 값은 BoxingStyle.Style이다 -
## 매치메이킹/표시용 "이 상대는 원래 어떤 스타일인가"이고, 경기 중에는
## AIController.gd가 상황에 따라 실시간으로 다른 스타일로 전환한다
## (BoxingStyle.gd 참고). 초반엔 일부만, 스테이지가 오를수록 다양해진다.
const ARCHETYPE_POOL_BY_STAGE := [
	[BoxingStyle.Style.BOXER_PUNCHER, BoxingStyle.Style.IN_FIGHTER],
	[BoxingStyle.Style.BOXER_PUNCHER, BoxingStyle.Style.IN_FIGHTER, BoxingStyle.Style.OUT_BOXER],
	[BoxingStyle.Style.BOXER_PUNCHER, BoxingStyle.Style.IN_FIGHTER, BoxingStyle.Style.OUT_BOXER, BoxingStyle.Style.SLUGGER],
	[BoxingStyle.Style.BOXER_PUNCHER, BoxingStyle.Style.IN_FIGHTER, BoxingStyle.Style.OUT_BOXER, BoxingStyle.Style.SLUGGER, BoxingStyle.Style.PRESSURE_FIGHTER],
	[BoxingStyle.Style.OUT_BOXER, BoxingStyle.Style.SLUGGER, BoxingStyle.Style.PRESSURE_FIGHTER, BoxingStyle.Style.COUNTER_PUNCHER],
	[BoxingStyle.Style.BOXER_PUNCHER, BoxingStyle.Style.IN_FIGHTER, BoxingStyle.Style.OUT_BOXER, BoxingStyle.Style.SLUGGER, BoxingStyle.Style.PRESSURE_FIGHTER, BoxingStyle.Style.COUNTER_PUNCHER],
	[BoxingStyle.Style.OUT_BOXER, BoxingStyle.Style.SLUGGER, BoxingStyle.Style.PRESSURE_FIGHTER, BoxingStyle.Style.COUNTER_PUNCHER],
	[BoxingStyle.Style.OUT_BOXER, BoxingStyle.Style.SLUGGER, BoxingStyle.Style.PRESSURE_FIGHTER, BoxingStyle.Style.COUNTER_PUNCHER],
	[BoxingStyle.Style.COUNTER_PUNCHER, BoxingStyle.Style.PRESSURE_FIGHTER, BoxingStyle.Style.SLUGGER],
	[BoxingStyle.Style.COUNTER_PUNCHER, BoxingStyle.Style.PRESSURE_FIGHTER, BoxingStyle.Style.SLUGGER],
]

## --- 난이도: 상대 능력치 배율 + 등장 확률 + 보상 배율 ---
enum Difficulty { EASY, EVEN, HARD }

const DIFFICULTY_WEIGHTS := {
	Difficulty.EASY: 0.2,
	Difficulty.EVEN: 0.6,
	Difficulty.HARD: 0.2,
}
const DIFFICULTY_STAT_MULT := {
	Difficulty.EASY: 0.85,
	Difficulty.EVEN: 1.0,
	Difficulty.HARD: 1.2,
}
const DIFFICULTY_LABEL := {
	Difficulty.EASY: "쉬움",
	Difficulty.EVEN: "비슷함",
	Difficulty.HARD: "매우 강함",
}
const DIFFICULTY_REWARD_MULT := {
	Difficulty.EASY: 0.7,
	Difficulty.EVEN: 1.0,
	Difficulty.HARD: 1.6,
}

## --- 라이벌 등장 확률 ---
const RIVAL_CHANCE := 0.15
const RIVAL_REMATCH_CHANCE := 0.4

## --- 기본 보상 공식 ---
const BASE_MONEY_REWARD := 80
const MONEY_PER_WIN := 8
const BASE_FAN_REWARD := 20
const BASE_FAME_REWARD := 5

## --- 상대 이름 생성용 ---
const OPPONENT_FIRST_NAMES := ["김", "이", "박", "최", "정", "강", "조", "장", "임", "한"]
const OPPONENT_LAST_NAMES := ["도현", "성민", "재훈", "우진", "태양", "준서", "민재", "현우", "동현", "지훈"]

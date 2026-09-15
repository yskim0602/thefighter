class_name OpponentOffer
extends RefCounted

## 경기 제의 하나를 담는 데이터. MatchGenerator.gd가 만들고, MatchOffer 화면이
## 보여주고, 수락하면 MatchContext에 저장되어 Main.tscn(AIController)이 읽어
## 실제 상대 능력치를 만드는 데 쓴다.

var opponent_name: String = "무명 파이터"
var wins: int = 0
var losses: int = 0
var style: int = 0  # FightingStyle.Style 값
var archetype: int = CareerConfig.Archetype.BOXER
var difficulty: int = CareerConfig.Difficulty.EVEN
var stat_multiplier: float = 1.0

var money_reward: int = 0
var fan_reward: int = 0
var fame_reward: int = 0

var is_rival: bool = false
var is_main_event: bool = false
var is_promotion_match: bool = false
var is_title_shot: bool = false
var is_championship: bool = false
var is_title_defense: bool = false


func difficulty_label() -> String:
	return CareerConfig.DIFFICULTY_LABEL.get(difficulty, "?")


func difficulty_stars() -> String:
	match difficulty:
		CareerConfig.Difficulty.EASY:
			return "★★☆☆☆"
		CareerConfig.Difficulty.HARD:
			return "★★★★★"
	return "★★★☆☆"


func archetype_name() -> String:
	return CareerConfig.ARCHETYPE_NAMES.get(archetype, "?")


func record_text() -> String:
	return "%d W / %d L" % [wins, losses]


## 화면에 표시할 중요도 태그. 우선순위가 높은 것부터 확인한다.
func tag_text() -> String:
	if is_championship or is_title_shot or is_title_defense:
		return "TITLE FIGHT"
	if is_promotion_match:
		return "PROMOTION FIGHT"
	if is_rival:
		return "RIVALRY"
	if is_main_event:
		return "MAIN EVENT"
	return "STANDARD FIGHT"


## 거절 시 보여줄 페널티 여부. 중요 경기(라이벌/승급전/타이틀전/메인 이벤트)는
## 거절하면 명성/팬이 깎인다.
func is_important() -> bool:
	return is_rival or is_promotion_match or is_title_shot or is_championship \
		or is_title_defense or is_main_event

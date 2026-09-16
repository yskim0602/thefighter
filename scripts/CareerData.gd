class_name CareerData
extends RefCounted

## 세이브되는 커리어 진행 상태 (파이트머니, 전적, 스테이지별 전적, 무대 단계,
## 랭크, 팬/명성, 라이벌, 능력치). Resource가 아니라 순수 데이터 클래스로 만들어서 JSON으로
## 직접 저장/불러오기 한다 (씬 파일이 커스텀 리소스 타입을 직접 참조할 때
## 생기는 로딩 타이밍 문제를 피하기 위함 - scripts/CharacterStats.gd 참고).
##
## 진행 방식: 플레이어가 상대/무대를 직접 고르지 않는다. MatchGenerator.gd가
## 이 데이터를 보고 다음 경기 제의(OpponentOffer)를 만들고, register_result()가
## 그 결과를 반영해 승급/랭크/팬/명성을 갱신한다. 튜닝 수치는 전부
## CareerConfig.gd에 있다.

## 지하 체육관부터 챔피언십까지, 10단계 무대.
enum Stage {
	UNDERGROUND,
	AMATEUR_CIRCUIT,
	ROOKIE,
	FIGHT_LEAGUE,
	ELITE,
	WORLD_SERIES,
	RANKED,
	TOP_10,
	TITLE_SHOT,
	CHAMPION,
}

const STAGE_NAMES := [
	"UNDERGROUND",
	"AMATEUR CIRCUIT",
	"ROOKIE LEAGUE",
	"FIGHT LEAGUE",
	"ELITE",
	"WORLD SERIES",
	"RANKED",
	"TOP 10",
	"TITLE SHOT",
	"CHAMPIONSHIP",
]

var fight_money: int = 0
var wins: int = 0
var losses: int = 0
var stage: int = Stage.UNDERGROUND
var stats: CharacterStats = CharacterStats.new()

## 현재 스테이지(0~5)에서 치른 경기/승수. 승급전을 치르면 0으로 리셋된다.
var fights_this_stage: int = 0
var wins_this_stage: int = 0
## 7승을 채워서 승급전 도전이 가능해지면 true (승급전에서 지면 유지되어 재도전 가능).
var promotion_ready: bool = false

## 랭크 스테이지(RANKED~CHAMPIONSHIP)에서만 쓰는 숫자. 낮을수록 강함.
var rank: int = 0
var is_champion: bool = false
var title_defenses: int = 0
var is_legend: bool = false

var fans: int = 0
var fame: int = 0

## [{"name": String, "defeated": bool}, ...]
var rivals: Array = []

## 스테이지별 전적. 인덱스 = Stage 값, [{"wins": int, "losses": int}, ...].
## 필요할 때(_record_stage_result)만 그때그때 늘어난다 - 아직 한 번도
## 싸우지 않은 스테이지는 배열에 항목 자체가 없다. 기록 화면(RecordMenu)이 쓴다.
var stage_record: Array = []

## 복싱 스탠스(Fighter.Stance.ORTHODOX/SOUTHPAW). 능력치와 달리 훈련으로
## 정해지는 게 아니라 캐릭터 메뉴에서 직접 고르는 값이고, PlayerController가
## 경기 시작 시 이 값을 그대로 읽어간다.
var stance: int = Fighter.Stance.ORTHODOX


func stage_name() -> String:
	if stage >= 0 and stage < STAGE_NAMES.size():
		return STAGE_NAMES[stage]
	return "?"


func is_ranked_stage() -> bool:
	return stage >= CareerConfig.RANKED_STAGE_INDEX


## 경기 결과를 반영하고 무슨 일이 일어났는지(승급/실패/챔피언 등극 등) 알려준다.
## Main.gd가 결과 화면 문구를 만들 때 쓴다.
func register_result(won: bool, offer: OpponentOffer) -> Dictionary:
	var progress := {"promoted": false, "stage_failed": false, "became_champion": false}
	var fought_stage := stage  # 승급으로 stage가 바뀌기 전에, 실제로 싸운 스테이지를 기억해둔다.

	if won and offer.is_rival:
		for rival in rivals:
			if rival.get("name") == offer.opponent_name:
				rival["defeated"] = true

	if offer.is_promotion_match:
		_register_promotion_result(won, progress)
	elif offer.is_championship:
		_register_championship_result(won, progress)
	elif offer.is_title_defense:
		_register_title_defense_result(won)
	elif is_ranked_stage():
		_register_ranked_result(won)
	else:
		_register_regular_result(won, progress)

	_record_stage_result(fought_stage, won)

	if won:
		wins += 1
		fight_money += offer.money_reward
		fans += offer.fan_reward
		fame += offer.fame_reward
	else:
		losses += 1
		fight_money += int(offer.money_reward * 0.2)
		fans += int(offer.fan_reward * 0.1)

	return progress


func _record_stage_result(stage_index: int, won: bool) -> void:
	while stage_record.size() <= stage_index:
		stage_record.append({"wins": 0, "losses": 0})
	if won:
		stage_record[stage_index]["wins"] += 1
	else:
		stage_record[stage_index]["losses"] += 1


func _register_regular_result(won: bool, progress: Dictionary) -> void:
	fights_this_stage += 1
	if won:
		wins_this_stage += 1
	if wins_this_stage >= CareerConfig.STAGE_WINS_REQUIRED:
		promotion_ready = true
	elif fights_this_stage >= CareerConfig.STAGE_FIGHTS_REQUIRED:
		fights_this_stage = 0
		wins_this_stage = 0
		progress["stage_failed"] = true


func _register_promotion_result(won: bool, progress: Dictionary) -> void:
	if not won:
		return  # 승급전 패배: promotion_ready는 유지, 다음 제의도 다시 승급전.
	stage += 1
	fights_this_stage = 0
	wins_this_stage = 0
	promotion_ready = false
	progress["promoted"] = true
	if is_ranked_stage():
		rank = CareerConfig.RANK_START


func _register_ranked_result(won: bool) -> void:
	if won:
		rank = max(rank - randi_range(CareerConfig.RANK_GAIN_MIN, CareerConfig.RANK_GAIN_MAX), 1)
	else:
		rank = min(rank + CareerConfig.RANK_LOSS_ON_DEFEAT, CareerConfig.RANK_START)

	if stage == Stage.RANKED and rank <= CareerConfig.RANK_TOP10_THRESHOLD:
		stage = Stage.TOP_10
	elif stage == Stage.TOP_10 and rank <= CareerConfig.RANK_TITLE_SHOT_THRESHOLD:
		stage = Stage.TITLE_SHOT


func _register_championship_result(won: bool, progress: Dictionary) -> void:
	if not won:
		return  # 챔피언전 패배: TITLE_SHOT 단계에 머물며 재도전 가능.
	is_champion = true
	stage = Stage.CHAMPION
	progress["became_champion"] = true


func _register_title_defense_result(won: bool) -> void:
	if not won:
		return  # 방어 실패해도 챔피언 자리는 유지 (게임적 재미 우선의 단순화).
	title_defenses += 1
	if title_defenses >= CareerConfig.TITLE_DEFENSES_FOR_LEGEND:
		is_legend = true


func to_dict() -> Dictionary:
	return {
		"fight_money": fight_money,
		"wins": wins,
		"losses": losses,
		"stage": stage,
		"fights_this_stage": fights_this_stage,
		"wins_this_stage": wins_this_stage,
		"promotion_ready": promotion_ready,
		"rank": rank,
		"is_champion": is_champion,
		"title_defenses": title_defenses,
		"is_legend": is_legend,
		"fans": fans,
		"fame": fame,
		"rivals": rivals,
		"stage_record": stage_record,
		"stance": stance,
		"fighter_name": stats.fighter_name,
		"power": stats.power,
		"stamina": stats.stamina,
		"speed": stats.speed,
		"skill": stats.skill,
	}


func from_dict(data: Dictionary) -> void:
	fight_money = data.get("fight_money", fight_money)
	wins = data.get("wins", wins)
	losses = data.get("losses", losses)
	stage = data.get("stage", stage)
	fights_this_stage = data.get("fights_this_stage", fights_this_stage)
	wins_this_stage = data.get("wins_this_stage", wins_this_stage)
	promotion_ready = data.get("promotion_ready", promotion_ready)
	rank = data.get("rank", rank)
	is_champion = data.get("is_champion", is_champion)
	title_defenses = data.get("title_defenses", title_defenses)
	is_legend = data.get("is_legend", is_legend)
	fans = data.get("fans", fans)
	fame = data.get("fame", fame)
	rivals = data.get("rivals", rivals)
	stage_record = data.get("stage_record", stage_record)
	stance = data.get("stance", stance)
	stats.fighter_name = data.get("fighter_name", stats.fighter_name)
	stats.power = data.get("power", stats.power)
	stats.stamina = data.get("stamina", stats.stamina)
	stats.speed = data.get("speed", stats.speed)
	stats.skill = data.get("skill", stats.skill)

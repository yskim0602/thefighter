class_name CareerData
extends RefCounted

## 세이브되는 커리어 진행 상태 (파이트머니, 전적, 무대 단계, 능력치).
## Resource가 아니라 순수 데이터 클래스로 만들어서 JSON으로 직접 저장/불러오기
## 한다 (씬 파일이 커스텀 리소스 타입을 직접 참조할 때 생기는 로딩 타이밍
## 문제를 피하기 위함 - scripts/CharacterStats.gd 관련 이슈 참고).

## 지하 체육관부터 챔피언 타이틀전까지, 10단계 무대. StageSelect.gd가 이
## 순서 그대로 카드를 나열한다.
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

## 각 무대에 도달하는 데 필요한 최소 승수. 인덱스 = Stage enum 값.
const STAGE_WIN_THRESHOLDS := [0, 2, 4, 6, 9, 12, 16, 20, 25, 30]

const STAGE_NAMES := [
	"UNDERGROUND",
	"AMATEUR CIRCUIT",
	"ROOKIE",
	"FIGHT LEAGUE",
	"ELITE",
	"WORLD SERIES",
	"RANKED",
	"TOP 10",
	"TITLE SHOT",
	"CHAMPION",
]

var fight_money: int = 0
var wins: int = 0
var losses: int = 0
var stage: int = Stage.UNDERGROUND
var stats: CharacterStats = CharacterStats.new()


func stage_name() -> String:
	if stage >= 0 and stage < STAGE_NAMES.size():
		return STAGE_NAMES[stage]
	return "?"


func update_stage_from_wins() -> void:
	var reached := 0
	for i in range(STAGE_WIN_THRESHOLDS.size()):
		if wins >= STAGE_WIN_THRESHOLDS[i]:
			reached = i
	stage = reached


func to_dict() -> Dictionary:
	return {
		"fight_money": fight_money,
		"wins": wins,
		"losses": losses,
		"stage": stage,
		"fighter_name": stats.fighter_name,
		"style": stats.style,
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
	stats.fighter_name = data.get("fighter_name", stats.fighter_name)
	stats.style = data.get("style", stats.style)
	stats.power = data.get("power", stats.power)
	stats.stamina = data.get("stamina", stats.stamina)
	stats.speed = data.get("speed", stats.speed)
	stats.skill = data.get("skill", stats.skill)

class_name CareerData
extends RefCounted

## 세이브되는 커리어 진행 상태 (파이트머니, 전적, 등급, 능력치).
## Resource가 아니라 순수 데이터 클래스로 만들어서 JSON으로 직접 저장/불러오기
## 한다 (씬 파일이 커스텀 리소스 타입을 직접 참조할 때 생기는 로딩 타이밍
## 문제를 피하기 위함 - scripts/CharacterStats.gd 관련 이슈 참고).

enum Tier { UNDERGROUND, AMATEUR, CONTENDER, CHAMPION }

const TIER_WIN_THRESHOLDS := {
	Tier.CHAMPION: 12,
	Tier.CONTENDER: 6,
	Tier.AMATEUR: 3,
}

var fight_money: int = 0
var wins: int = 0
var losses: int = 0
var tier: int = Tier.UNDERGROUND
var stats: CharacterStats = CharacterStats.new()


func tier_name() -> String:
	match tier:
		Tier.UNDERGROUND:
			return "지하 파이트"
		Tier.AMATEUR:
			return "아마추어"
		Tier.CONTENDER:
			return "UFC 도전자"
		Tier.CHAMPION:
			return "UFC 챔피언"
	return "?"


func update_tier_from_wins() -> void:
	if wins >= TIER_WIN_THRESHOLDS[Tier.CHAMPION]:
		tier = Tier.CHAMPION
	elif wins >= TIER_WIN_THRESHOLDS[Tier.CONTENDER]:
		tier = Tier.CONTENDER
	elif wins >= TIER_WIN_THRESHOLDS[Tier.AMATEUR]:
		tier = Tier.AMATEUR
	else:
		tier = Tier.UNDERGROUND


func to_dict() -> Dictionary:
	return {
		"fight_money": fight_money,
		"wins": wins,
		"losses": losses,
		"tier": tier,
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
	tier = data.get("tier", tier)
	stats.fighter_name = data.get("fighter_name", stats.fighter_name)
	stats.style = data.get("style", stats.style)
	stats.power = data.get("power", stats.power)
	stats.stamina = data.get("stamina", stats.stamina)
	stats.speed = data.get("speed", stats.speed)
	stats.skill = data.get("skill", stats.skill)

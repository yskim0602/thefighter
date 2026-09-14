extends Control

## 홈 화면 (브롤스타즈 스타일 허브). 위쪽엔 지하실 배경의 3D 캐릭터 미리보기,
## 아래쪽엔 파이트머니/전적/등급/능력치 훈련/경기 시작을 담당한다.

const TRAIN_BASE_COST := 50
const TRAIN_COST_PER_POINT := 10
const TRAIN_GAIN := 1
const TRAINABLE_STATS := ["power", "stamina", "speed", "skill"]

## 등급별 배경색. 지금은 사진 대신 색상만 바꾸지만, 나중에 실제 배경 사진/텍스처를
## 쓰게 되면 Background를 ColorRect 대신 TextureRect로 바꾸고 이 테이블을
## 텍스처 리소스 테이블로 그대로 교체하면 된다.
const TIER_BG_COLORS := {
	CareerData.Tier.UNDERGROUND: Color(0.05, 0.05, 0.06),
	CareerData.Tier.AMATEUR: Color(0.05, 0.07, 0.09),
	CareerData.Tier.CONTENDER: Color(0.04, 0.07, 0.11),
	CareerData.Tier.CHAMPION: Color(0.10, 0.08, 0.02),
}

@onready var background: ColorRect = $Background
@onready var tier_label: Label = $TierLabel
@onready var money_label: Label = $MoneyLabel
@onready var record_label: Label = $RecordLabel

@onready var stat_labels := {
	"power": $BottomPanel/PowerRow/PowerLabel,
	"stamina": $BottomPanel/StaminaRow/StaminaLabel,
	"speed": $BottomPanel/SpeedRow/SpeedLabel,
	"skill": $BottomPanel/SkillRow/SkillLabel,
}
@onready var train_buttons := {
	"power": $BottomPanel/PowerRow/TrainButton,
	"stamina": $BottomPanel/StaminaRow/TrainButton,
	"speed": $BottomPanel/SpeedRow/TrainButton,
	"skill": $BottomPanel/SkillRow/TrainButton,
}


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var career := SaveManager.career
	background.color = TIER_BG_COLORS.get(career.tier, TIER_BG_COLORS[CareerData.Tier.UNDERGROUND])
	tier_label.text = "등급: %s" % career.tier_name()
	record_label.text = "전적 %d승 %d패" % [career.wins, career.losses]
	money_label.text = "%d G" % career.fight_money

	for stat_name in TRAINABLE_STATS:
		var value: int = career.stats.get(stat_name)
		var cost := _train_cost(value)
		stat_labels[stat_name].text = "%s %d" % [_stat_display_name(stat_name), value]
		train_buttons[stat_name].text = "훈련 (%d G)" % cost
		train_buttons[stat_name].disabled = career.fight_money < cost


func _stat_display_name(stat_name: String) -> String:
	match stat_name:
		"power":
			return "파워"
		"stamina":
			return "체력"
		"speed":
			return "스피드"
		"skill":
			return "스킬"
	return stat_name


func _train_cost(stat_value: int) -> int:
	return TRAIN_BASE_COST + stat_value * TRAIN_COST_PER_POINT


func _on_train_pressed(stat_name: String) -> void:
	var career := SaveManager.career
	var current: int = career.stats.get(stat_name)
	var cost := _train_cost(current)
	if career.fight_money < cost:
		return
	career.fight_money -= cost
	career.stats.set(stat_name, current + TRAIN_GAIN)
	SaveManager.save()
	_refresh()


func _on_fight_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

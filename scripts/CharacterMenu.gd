extends Control

## 캐릭터 메뉴: 능력치 훈련 (Career/홈 화면에서 이쪽으로 옮겨왔다).
## 추후 여기에 액세서리/외형 커스터마이징을 추가할 예정.
##
## 복싱 스타일은 직접 고르는 게 아니라 훈련한 능력치 분포에서 자동으로
## 정해진다(BoxingStyle.infer_style) - 파워를 밀어붙이면 슬러거에 가까워지고,
## 스피드/스킬을 키우면 아웃복서에 가까워지는 식. 그래서 훈련할 때마다
## "현재 스타일"이 바뀔 수 있다.

const TRAIN_BASE_COST := 50
const TRAIN_COST_PER_POINT := 10
const TRAIN_GAIN := 1
const TRAINABLE_STATS := ["power", "stamina", "speed", "skill"]

@onready var money_label: Label = $Body/ContentPanel/StatsPanel/MoneyLabel
@onready var style_label: Label = $Body/ContentPanel/StatsPanel/StyleLabel

@onready var stat_labels := {
	"power": $Body/ContentPanel/StatsPanel/PowerRow/PowerLabel,
	"stamina": $Body/ContentPanel/StatsPanel/StaminaRow/StaminaLabel,
	"speed": $Body/ContentPanel/StatsPanel/SpeedRow/SpeedLabel,
	"skill": $Body/ContentPanel/StatsPanel/SkillRow/SkillLabel,
}
@onready var train_buttons := {
	"power": $Body/ContentPanel/StatsPanel/PowerRow/TrainButton,
	"stamina": $Body/ContentPanel/StatsPanel/StaminaRow/TrainButton,
	"speed": $Body/ContentPanel/StatsPanel/SpeedRow/TrainButton,
	"skill": $Body/ContentPanel/StatsPanel/SkillRow/TrainButton,
}


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var career := SaveManager.career
	money_label.text = "파이트머니: %d G" % career.fight_money
	var style := BoxingStyle.infer_style(career.stats)
	style_label.text = "현재 스타일: %s" % BoxingStyle.style_name(style)

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

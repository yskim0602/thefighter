extends Control

## 캐릭터 메뉴: 능력치 훈련 (Career/홈 화면에서 이쪽으로 옮겨왔다).
## 추후 여기에 액세서리/외형 커스터마이징을 추가할 예정.

const TRAIN_BASE_COST := 50
const TRAIN_COST_PER_POINT := 10
const TRAIN_GAIN := 1
const TRAINABLE_STATS := ["power", "stamina", "speed", "skill"]

@onready var money_label: Label = $VBox/MoneyLabel

@onready var stat_labels := {
	"power": $VBox/StatPanel/PowerRow/PowerLabel,
	"stamina": $VBox/StatPanel/StaminaRow/StaminaLabel,
	"speed": $VBox/StatPanel/SpeedRow/SpeedLabel,
	"skill": $VBox/StatPanel/SkillRow/SkillLabel,
}
@onready var train_buttons := {
	"power": $VBox/StatPanel/PowerRow/TrainButton,
	"stamina": $VBox/StatPanel/StaminaRow/TrainButton,
	"speed": $VBox/StatPanel/SpeedRow/TrainButton,
	"skill": $VBox/StatPanel/SkillRow/TrainButton,
}


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var career := SaveManager.career
	money_label.text = "파이트머니: %d G" % career.fight_money

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

extends Control

## 경기 사이의 허브 화면. 파이트머니/전적/등급을 보여주고, 능력치 훈련과
## 다음 경기 시작을 담당한다.

const TRAIN_BASE_COST := 50
const TRAIN_COST_PER_POINT := 10
const TRAIN_GAIN := 1
const TRAINABLE_STATS := ["power", "stamina", "speed", "skill"]

@onready var tier_label: Label = $CenterContainer/VBox/TierLabel
@onready var record_label: Label = $CenterContainer/VBox/RecordLabel
@onready var money_label: Label = $CenterContainer/VBox/MoneyLabel

@onready var stat_labels := {
	"power": $CenterContainer/VBox/PowerRow/PowerLabel,
	"stamina": $CenterContainer/VBox/StaminaRow/StaminaLabel,
	"speed": $CenterContainer/VBox/SpeedRow/SpeedLabel,
	"skill": $CenterContainer/VBox/SkillRow/SkillLabel,
}
@onready var train_buttons := {
	"power": $CenterContainer/VBox/PowerRow/TrainButton,
	"stamina": $CenterContainer/VBox/StaminaRow/TrainButton,
	"speed": $CenterContainer/VBox/SpeedRow/TrainButton,
	"skill": $CenterContainer/VBox/SkillRow/TrainButton,
}


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var career := SaveManager.career
	tier_label.text = "등급: %s" % career.tier_name()
	record_label.text = "전적 %d승 %d패" % [career.wins, career.losses]
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


func _on_fight_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

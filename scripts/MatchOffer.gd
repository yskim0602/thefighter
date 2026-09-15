extends Control

## "새로운 경기 제의가 도착했습니다" 화면. MatchGenerator로 다음 상대를 뽑아
## VS 구도로 보여주고, 수락하면 MatchContext에 담아 전투로 이동한다. 거절을
## 누르면 확인창을 띄우고, 확인하면 CareerData의 페널티를 적용한 뒤 새 제의를
## 다시 뽑는다.

const AMBIENT_COLOR_START := Color(0.55, 0.5, 0.45)
const AMBIENT_COLOR_END := Color(0.9, 0.85, 0.7)
const AMBIENT_ENERGY_START := 0.35
const AMBIENT_ENERGY_END := 0.9
const BULB_COLOR_START := Color(1, 0.85, 0.6)
const BULB_COLOR_END := Color(1, 0.95, 0.85)
const BULB_ENERGY_START := 2.6
const BULB_ENERGY_END := 4.0

const TAG_COLORS := {
	"STANDARD FIGHT": Color(0.6, 0.6, 0.65),
	"MAIN EVENT": Color(0.9, 0.7, 0.2),
	"RIVALRY": Color(0.9, 0.4, 0.2),
	"PROMOTION FIGHT": Color(0.3, 0.7, 0.9),
	"TITLE FIGHT": Color(0.85, 0.2, 0.2),
}

@onready var arena_environment: Environment = $ArenaViewportContainer/ArenaViewport/ArenaScene/WorldEnvironment.environment
@onready var arena_bulb: OmniLight3D = $ArenaViewportContainer/ArenaViewport/ArenaScene/BulbLight

@onready var stage_record_label: Label = $TopBar/TopBarRow/StageRecordLabel

@onready var tag_badge: PanelContainer = $TagBadge
@onready var tag_label: Label = $TagBadge/TagLabel

@onready var my_name_label: Label = $MyFighterInfoPanel/VBox/NameLabel
@onready var my_record_label: Label = $MyFighterInfoPanel/VBox/RecordLabel
@onready var my_rank_label: Label = $MyFighterInfoPanel/VBox/RankLabel

@onready var opponent_name_label: Label = $OpponentInfoPanel/VBox/NameLabel
@onready var opponent_record_label: Label = $OpponentInfoPanel/VBox/RecordLabel
@onready var opponent_style_label: Label = $OpponentInfoPanel/VBox/StyleLabel
@onready var opponent_difficulty_label: Label = $OpponentInfoPanel/VBox/DifficultyLabel

@onready var reward_label: Label = $RewardBar/RewardLabel

@onready var accept_button: Button = $ButtonArea/AcceptButton
@onready var reject_button: Button = $ButtonArea/RejectButton

@onready var decline_confirm: Control = $DeclineConfirm
@onready var decline_penalty_label: Label = $DeclineConfirm/CenterContainer/Panel/VBox/PenaltyLabel

@onready var fade_nodes: Array = [
	$ArenaViewportContainer, $OpponentInfoPanel, $MyFighterInfoPanel,
	$VSLabel, $TagBadge, $RewardBar, $ButtonArea,
]

var current_offer: OpponentOffer


func _ready() -> void:
	accept_button.mouse_entered.connect(func(): _tween_scale(accept_button, 1.05))
	accept_button.mouse_exited.connect(func(): _tween_scale(accept_button, 1.0))

	_new_offer()
	_play_intro()


func _new_offer() -> void:
	current_offer = MatchGenerator.generate(SaveManager.career)
	_refresh()


func _refresh() -> void:
	var career := SaveManager.career
	var offer := current_offer

	stage_record_label.text = "%s   %d W / %d L" % [career.stage_name(), career.wins, career.losses]

	tag_label.text = offer.tag_text()
	tag_badge.self_modulate = TAG_COLORS.get(tag_label.text, Color(0.6, 0.6, 0.65))

	my_name_label.text = "YOU"
	my_record_label.text = "%d W / %d L" % [career.wins, career.losses]
	my_rank_label.text = ("RANK %d" % career.rank) if career.is_ranked_stage() else career.stage_name()

	opponent_name_label.text = offer.opponent_name
	opponent_record_label.text = offer.record_text()
	opponent_style_label.text = "%s (%s)" % [FightingStyle.style_name(offer.style), offer.archetype_name()]
	opponent_difficulty_label.text = offer.difficulty_stars()

	reward_label.text = "%d G      +%d FANS      +%d FAME" % [offer.money_reward, offer.fan_reward, offer.fame_reward]

	_apply_arena_lighting(career.stage)


func _apply_arena_lighting(stage: int) -> void:
	var stage_count := CareerData.STAGE_NAMES.size()
	var t: float = clampf(float(stage) / float(stage_count - 1), 0.0, 1.0)
	arena_environment.ambient_light_color = AMBIENT_COLOR_START.lerp(AMBIENT_COLOR_END, t)
	arena_environment.ambient_light_energy = lerpf(AMBIENT_ENERGY_START, AMBIENT_ENERGY_END, t)
	arena_bulb.light_color = BULB_COLOR_START.lerp(BULB_COLOR_END, t)
	arena_bulb.light_energy = lerpf(BULB_ENERGY_START, BULB_ENERGY_END, t)


func _play_intro() -> void:
	for node in fade_nodes:
		node.modulate.a = 0.0
	var tween := create_tween()
	for node in fade_nodes:
		tween.tween_property(node, "modulate:a", 1.0, 0.18)
		tween.tween_interval(0.03)


func _tween_scale(node: Control, target_scale: float) -> void:
	node.pivot_offset = node.size / 2.0
	var tween := create_tween()
	tween.tween_property(node, "scale", Vector2(target_scale, target_scale), 0.12)


func _on_accept_pressed() -> void:
	MatchContext.current_offer = current_offer
	Nav.go_to("res://scenes/Main.tscn")


func _on_reject_pressed() -> void:
	decline_penalty_label.text = _penalty_text(current_offer)
	decline_confirm.visible = true


func _penalty_text(offer: OpponentOffer) -> String:
	if offer.is_important():
		return "명성 -%d   팬 -%d" % [CareerConfig.DECLINE_FAME_PENALTY_IMPORTANT, CareerConfig.DECLINE_FAN_PENALTY_IMPORTANT]
	return "가벼운 페널티만 있습니다"


func _on_decline_confirm_pressed() -> void:
	decline_confirm.visible = false
	SaveManager.career.apply_decline_penalty(current_offer)
	SaveManager.save()
	_new_offer()
	_play_intro()


func _on_decline_cancel_pressed() -> void:
	decline_confirm.visible = false

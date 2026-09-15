extends Control

## 경기 시작 전 무대(링) 선택 화면. CareerData.STAGE_NAMES 순서 그대로 카드를
## 가로로 나열해서 보여준다. 지금은 "현재 도달한 무대"만 입장 가능하고, 나머지는
## 잠금/완료 표시만 한다 - 실제로 무대마다 다른 상대/배경을 붙이는 건 다음 단계
## (README 로드맵 3단계: 여러 상대 로스터) 작업이고, 지금은 진행 상황을 시각적으로
## 보여주는 역할까지만 한다.

const STAGE_DESCRIPTIONS := [
	"작은 지하 체육관 · 관중 적음",
	"학교 체육관 · 지역 체육관",
	"작은 프로 경기장",
	"조명 + 관중 + 방송",
	"대형 아레나",
	"엄청 큰 국제 경기장",
	"대형 방송 경기",
	"긴장감 있는 메인 이벤트",
	"챔피언 도전 경기",
	"최종 메인 이벤트",
]

const CARD_SIZE := Vector2(220, 260)

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var card_row: HBoxContainer = $ScrollContainer/CardRow


func _ready() -> void:
	_build_cards()
	call_deferred("_scroll_to_current")


func _build_cards() -> void:
	var current_stage := SaveManager.career.stage
	for i in range(CareerData.STAGE_NAMES.size()):
		card_row.add_child(_make_card(i, current_stage))


func _make_card(index: int, current_stage: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	if index > current_stage:
		panel.modulate = Color(1, 1, 1, 0.45)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var name_label := Label.new()
	name_label.text = CareerData.STAGE_NAMES[index]
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = 2
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = STAGE_DESCRIPTIONS[index]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = 2
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	vbox.add_child(desc_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var status_label := Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if index < current_stage:
		status_label.text = "완료"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	elif index == current_stage:
		status_label.text = "현재"
		status_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	else:
		status_label.text = "잠김"
		status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(status_label)

	var enter_button := Button.new()
	enter_button.text = "입장"
	enter_button.disabled = index != current_stage
	enter_button.pressed.connect(_on_enter_pressed)
	vbox.add_child(enter_button)

	return panel


func _scroll_to_current() -> void:
	var current_stage := SaveManager.career.stage
	var separation: int = card_row.get_theme_constant("separation")
	var card_width: float = CARD_SIZE.x + separation
	scroll_container.scroll_horizontal = int(card_width * max(current_stage - 1, 0))


func _on_enter_pressed() -> void:
	Nav.go_to("res://scenes/Main.tscn")

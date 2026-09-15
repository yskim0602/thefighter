extends Control

## 기록 화면: 총 전적(승/패/승률) + 스테이지(경기장)별 몇 승 몇 패인지를
## 보여준다. 스테이지 카드는 고정 10개뿐이라 씬에 일일이 만들어두는 대신
## 코드에서 그때그때 생성한다 - CareerData.stage_record가 갱신될 때마다
## (경기 후) 다시 열어보면 최신 값이 그대로 반영된다.

const WIN_COLOR := Color(0.4, 0.85, 0.45)
const LOSS_COLOR := Color(0.85, 0.3, 0.3)
const EMPTY_BAR_COLOR := Color(1, 1, 1, 0.08)
const CURRENT_STAGE_COLOR := Color(1, 0.85, 0.3)
const UNFOUGHT_TEXT_COLOR := Color(0.5, 0.5, 0.55)
const BAR_HEIGHT := 6.0

@onready var record_label: Label = $Body/TotalPanel/TotalVBox/RecordLabel
@onready var win_rate_label: Label = $Body/TotalPanel/TotalVBox/WinRateRow/WinRateLabel
@onready var win_rate_bar: ProgressBar = $Body/TotalPanel/TotalVBox/WinRateRow/WinRateBar
@onready var stage_list: VBoxContainer = $Body/ScrollContainer/StageList


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var career := SaveManager.career
	var total := career.wins + career.losses
	record_label.text = "%d승 %d패" % [career.wins, career.losses]

	var rate: float = (float(career.wins) / float(total) * 100.0) if total > 0 else 0.0
	win_rate_label.text = "승률 %.1f%%" % rate
	win_rate_bar.value = rate

	for child in stage_list.get_children():
		child.queue_free()
	for i in range(CareerData.STAGE_NAMES.size()):
		stage_list.add_child(_build_stage_row(i, career))


func _build_stage_row(stage_index: int, career: CareerData) -> Control:
	var record: Dictionary = career.stage_record[stage_index] if stage_index < career.stage_record.size() else {}
	var wins: int = record.get("wins", 0)
	var losses: int = record.get("losses", 0)
	var fought := wins + losses

	var card := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	var name_vbox := VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.add_theme_constant_override("separation", 6)
	row.add_child(name_vbox)

	var name_label := Label.new()
	name_label.text = "%02d   %s" % [stage_index + 1, CareerData.STAGE_NAMES[stage_index]]
	name_label.add_theme_font_size_override("font_size", 16)
	if stage_index == career.stage:
		name_label.add_theme_color_override("font_color", CURRENT_STAGE_COLOR)
	name_vbox.add_child(name_label)
	name_vbox.add_child(_build_win_loss_bar(wins, losses))

	var record_text := Label.new()
	record_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if fought > 0:
		record_text.text = "%d승 %d패" % [wins, losses]
	else:
		record_text.text = "미도전"
		record_text.add_theme_color_override("font_color", UNFOUGHT_TEXT_COLOR)
	row.add_child(record_text)

	return card


func _build_win_loss_bar(wins: int, losses: int) -> Control:
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 2)
	var fought := wins + losses
	if fought <= 0:
		var empty_rect := ColorRect.new()
		empty_rect.color = EMPTY_BAR_COLOR
		empty_rect.custom_minimum_size = Vector2(0, BAR_HEIGHT)
		empty_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar_row.add_child(empty_rect)
		return bar_row

	if wins > 0:
		var win_rect := ColorRect.new()
		win_rect.color = WIN_COLOR
		win_rect.custom_minimum_size = Vector2(0, BAR_HEIGHT)
		win_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		win_rect.size_flags_stretch_ratio = float(wins)
		bar_row.add_child(win_rect)
	if losses > 0:
		var loss_rect := ColorRect.new()
		loss_rect.color = LOSS_COLOR
		loss_rect.custom_minimum_size = Vector2(0, BAR_HEIGHT)
		loss_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		loss_rect.size_flags_stretch_ratio = float(losses)
		bar_row.add_child(loss_rect)
	return bar_row

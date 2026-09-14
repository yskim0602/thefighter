extends HBoxContainer

## 모든 서브 메뉴 화면 좌상단에 붙는 공통 헤더. "뒤로"는 Nav의 이동 기록을
## 한 단계 되돌리고, "홈"은 기록을 비우고 바로 홈 화면(Career.tscn)으로 간다.


func _on_back_pressed() -> void:
	Nav.go_back()


func _on_home_pressed() -> void:
	Nav.go_home()

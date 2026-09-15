extends Node

## 오토로드 싱글턴. 화면 이동 기록을 스택으로 들고 있어서, 앞으로 메뉴가
## 몇 단계로 깊어지든 모든 메뉴가 공통으로 "뒤로가기"/"홈"을 쓸 수 있게 한다.
## 새 메뉴로 들어갈 땐 항상 change_scene_to_file 대신 go_to()를 쓸 것.

const HOME_SCENE := "res://scenes/Career.tscn"

var _history: Array[String] = []


func go_to(scene_path: String) -> void:
	var current := get_tree().current_scene.scene_file_path
	if current != "":
		_history.append(current)
	get_tree().change_scene_to_file(scene_path)


func go_back() -> void:
	if _history.is_empty():
		go_home()
		return
	var previous: String = _history.pop_back()
	get_tree().change_scene_to_file(previous)


func go_home() -> void:
	_history.clear()
	get_tree().change_scene_to_file(HOME_SCENE)


## go_to()와 달리 이동 기록을 비우고 이동한다. 전투가 끝난 뒤 다음 경기
## 제의 화면으로 넘어갈 때처럼, "뒤로" 갔을 때 방금 끝난 씬(예: 이미 끝난
## 전투)으로 돌아가는 게 의미 없는 경우에 쓴다 - 그 화면에서 뒤로가기를
## 누르면 기록이 비어있으니 go_back()이 자동으로 go_home()으로 처리한다.
func reset_to(scene_path: String) -> void:
	_history.clear()
	get_tree().change_scene_to_file(scene_path)

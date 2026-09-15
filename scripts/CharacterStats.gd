class_name CharacterStats
extends Resource

## 파이터 한 명의 능력치. 나중에 커리어 진행(파이트머니로 훈련해서 성장)과
## 저장/불러오기의 기본 단위가 된다. 전투 수치는 여기서 능력치로부터 계산해서
## Fighter.gd가 그대로 가져다 쓴다.

@export var fighter_name: String = "Fighter"

@export_range(1, 100) var power: int = 10
@export_range(1, 100) var stamina: int = 10
@export_range(1, 100) var speed: int = 10
@export_range(1, 100) var skill: int = 10


func get_max_health() -> float:
	return 80.0 + stamina * 2.0


func get_move_speed() -> float:
	return 3.0 + speed * 0.05


## 스태미나 게이지 최대치. 체력(get_max_health)과는 별개로, 펀치/회피마다
## 소모되고 시간이 지나면 회복되는 자원이다 - Fighter.gd 참고.
func get_max_stamina() -> float:
	return 50.0 + stamina * 3.0


func get_punch_damage() -> float:
	return 4.0 + power * 0.4


func get_attack_cooldown_mult() -> float:
	# skill이 높을수록 다음 공격까지 쿨다운이 짧아진다 (하한/상한을 둬서 너무 빨라지지 않게 함).
	return clamp(1.3 - skill * 0.006, 0.6, 1.3)

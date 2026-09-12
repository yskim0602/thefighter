# TheFighter

3D MMA 격투 게임 프로토타입 (Godot 4).

캡슐 메쉬로 만든 두 파이터가 원형 케이지 안에서 겨루는 최소 기능 버전입니다.
실제 캐릭터 모델/애니메이션은 없고, 이동/타격/블록/체력/라운드 타이머 같은
격투 게임의 핵심 시스템만 동작하도록 구성했습니다.

## 실행 방법

1. [Godot 4.3 이상](https://godotengine.org/download) 설치
2. Godot 실행 → "Import" → 이 폴더의 `project.godot` 선택
3. F5(또는 재생 버튼)로 실행

## 조작법

| 키 | 동작 |
| --- | --- |
| W / A / S / D | 이동 |
| J | 펀치 |
| K | 킥 (데미지 ↑, 쿨다운 ↑) |
| L (누르고 있기) | 블록 (받는 데미지 80% 감소) |
| R | 라운드 종료 후 재시작 |

상대는 간단한 AI로, 거리를 좁힌 뒤 랜덤하게 펀치/킥/블록을 선택합니다.

## 프로젝트 구조

```
thefighter/
├── project.godot          # 프로젝트 설정 + 입력 맵
├── scenes/
│   ├── Main.tscn           # 아레나, 조명, 카메라, UI, 두 파이터 배치
│   ├── Player.tscn         # 플레이어 파이터(파란 캡슐)
│   └── Enemy.tscn          # AI 파이터(빨간 캡슐)
└── scripts/
    ├── Fighter.gd          # 공통 로직: 이동/중력, 체력, 공격 판정, 피격 연출, KO
    ├── PlayerController.gd # 키 입력을 Fighter의 이동/공격 함수로 연결
    ├── AIController.gd     # 접근 → 공격/블록을 선택하는 단순 AI
    └── Main.gd             # 카메라 추적, 체력바/타이머 UI, 라운드 진행/재시작
```

`Fighter.gd`가 `class_name Fighter`로 선언된 베이스 클래스이고,
`PlayerController.gd`/`AIController.gd`는 이를 상속해서 "언제 움직이고 공격할지"만
결정합니다. 데미지 계산, 블록, 스태거, KO 연출은 전부 베이스 클래스에 있습니다.

## 확장 아이디어

- 캡슐 메쉬를 실제 3D 캐릭터 모델 + AnimationPlayer/AnimationTree로 교체
- 히트박스를 거리 기반이 아닌 `Area3D` 충돌로 정교화, 콤보/그래플 추가
- 케이지 펜스 메쉬, 관중석, 사운드/이펙트 추가
- 라운드제(3라운드, 판정), 체력 외 스태미나 시스템
- 멀티플레이어(로컬 2P 또는 네트워크)로 확장

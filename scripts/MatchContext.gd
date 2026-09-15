extends Node

## 오토로드 싱글턴. MatchOffer 화면에서 수락한 경기 제의를 담아뒀다가
## Main.tscn(AIController)이 읽어서 실제 상대 능력치/스타일을 만든다.
## 씬이 바뀌어도 값이 유지되도록 오토로드로 둔다.

var current_offer: OpponentOffer = null

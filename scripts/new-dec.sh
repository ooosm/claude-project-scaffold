#!/usr/bin/env bash
# 다음 DEC 번호를 원자적으로 할당하고 decision-log에 골격을 append 한다.
# 단일 프로세스가 번호 계산+append를 함께 수행하므로 병렬 세션의 번호 충돌을 예방한다.
# 사용: scripts/new-dec.sh "<결정 제목>"   (제목 생략 시 [제목] 플레이스홀더)
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$ROOT/.claude/decisions/decision-log.md"
[ -f "$LOG" ] || { echo "decision-log.md 없음: $LOG" >&2; exit 1; }

TITLE="${*:-[제목]}"
DATE="$(date +%F)"

MAX="$(grep -oE '^## DEC-[0-9]+' "$LOG" | grep -oE '[0-9]+' | sort -n | tail -1 || true)"
MAX="${MAX:-0}"
N=$((10#$MAX + 1))                       # 10# : 008/009 를 8진수로 오인하지 않게
NNN="$(printf '%03d' "$N")"
NEXT="$(printf '%03d' "$((N + 1))")"

tmp="$(mktemp)"
# 말미 정규화 — 스크립트를 입력 상태에 무관하게 만든다.
#   기존 안내 주석을 제거한 뒤, 뒤쪽의 빈 줄과 구분선을 걷어내고 항상 '---' + 빈 줄로 끝맺는다.
#   README 부트스트랩은 "로그를 비우고 DEC-001부터 시작"을 지시하는데, 그때 안내 주석까지
#   지우면 앵커가 사라져 새 DEC가 앞 문단에 그대로 접합되던 버그가 있었다(모든 신규 프로젝트의
#   첫 /dec 호출에서 100% 재현). 앵커에 의존하지 않고 말미를 직접 정규화해 해소한다.
#   awk는 마지막 줄에 개행이 없어도 하나의 레코드로 읽으므로 그 경우까지 함께 정규화된다.
grep -v '^<!-- 다음 결정은 여기 아래에' "$LOG" \
  | awk '
      {lines[n++] = $0}
      END {
        last = n - 1
        while (last >= 0 && (lines[last] == "" || lines[last] == "---")) last--
        for (i = 0; i <= last; i++) print lines[i]
        print ""; print "---"; print ""
      }
    ' > "$tmp"

cat >> "$tmp" <<EOF
## DEC-$NNN: $TITLE ($DATE)

**맥락**:

**결정**:

**검토한 대안**:
- ✅ **채택: [안 A]** — 이유:
- ❌ 기각: [안 B] — 이유:

**성능·향후 영향**:

**출처**:

---

<!-- 다음 결정은 여기 아래에 ## DEC-$NEXT 부터 추가 -->
EOF

mv "$tmp" "$LOG"
echo "✅ DEC-$NNN 골격 추가: $LOG"
echo "   → 맥락·결정·검토한 대안(채택+기각 이유)·향후 영향·출처를 채우세요."

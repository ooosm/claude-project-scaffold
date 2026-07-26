#!/usr/bin/env bash
# check-docs.sh 회귀 테스트 — 플레이스홀더 검출의 정탐/오탐/Mermaid 제외를 검증한다.
# 임시 "대상 프로젝트"(_skeleton-README.md 없음 → 플레이스홀더 검사 활성)를 만들어
# check-docs.sh를 실제로 돌리고 출력/종료코드를 단언한다. CI에서 실행된다.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
FAIL=0
pass() { printf '  ✓ %s\n' "$1"; }
fail() { FAIL=1; printf '  ✗ %s\n' "$1"; }

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/scripts" "$T/.claude/docs" "$T/.claude/decisions" "$T/docs"
cp "$HERE/check-docs.sh" "$T/scripts/check-docs.sh"

# 더티 문서: 플레이스홀더 잔존 + Mermaid 노드 라벨(비-ASCII 대괄호, 오탐 유발 후보)
cat > "$T/docs/how-it-works.md" <<'EOF'
# How It Works — [프로젝트명]
```mermaid
flowchart LR
    A[집계 엔진] --> B[(원천 데이터)]
    A --> C[스케줄러]
```
설명은 실제 동작 기준으로 작성한다.
설치 전 `VAR_NAME` 환경변수를 확인한다.
EOF

# 클린 문서: 정상 표기만(체크박스·한글 링크·[Unreleased]·코드 인덱싱) → 오탐 0이어야
cat > "$T/docs/user-guide.md" <<'EOF'
# 사용자 가이드 — 마이프로젝트
- [x] 로그인 완료
- [ ] 로그아웃 예정
자세한 내용은 [공식 문서](https://example.com)를 참고하세요.
## [Unreleased]
예시 코드: config[key] 와 items[idx] 를 쓴다.
EOF

# 구조 검사(REQ/FR·DEC)를 조용히 통과시키기 위한 최소 픽스처
printf '%s\n' '### REQ-1-1: 로그인' > "$T/.claude/docs/01-impl-requirements.md"
printf '%s\n' '- **FR-01**: 로그인한다' > "$T/.claude/docs/01-user-requirements.md"
printf '%s\n' '## DEC-001: 초기 결정 (2026-01-01)' > "$T/.claude/decisions/decision-log.md"

OUT="$(cd "$T" && bash scripts/check-docs.sh 2>&1)"

echo "$OUT" | grep -q 'how-it-works.md' && pass "더티 문서의 플레이스홀더를 검출" || fail "더티 문서를 놓침"
echo "$OUT" | grep -q '집계 엔진\|스케줄러\|원천 데이터' && fail "Mermaid 노드 라벨을 오탐" || pass "Mermaid 노드 라벨 제외"
echo "$OUT" | grep -q 'VAR_NAME' && pass "VAR_NAME 검출" || fail "VAR_NAME 놓침"
echo "$OUT" | grep -q 'user-guide.md' && fail "클린 문서 오탐([x]/[ ]/링크/[Unreleased]/config[key])" || pass "클린 문서 오탐 없음"

# --strict 는 경고가 있으면 exit 1
(cd "$T" && bash scripts/check-docs.sh --strict >/dev/null 2>&1)
[ "$?" -eq 1 ] && pass "--strict 는 경고 시 exit 1" || fail "--strict 종료코드가 1이 아님"

# 클린 전용(더티 제거) → exit 0 이어야
rm -f "$T/docs/how-it-works.md"
(cd "$T" && bash scripts/check-docs.sh --strict >/dev/null 2>&1)
[ "$?" -eq 0 ] && pass "클린 문서만 남으면 --strict 통과" || fail "클린 문서인데 --strict 실패"

if [ "$FAIL" -eq 0 ]; then echo "✅ test-check-docs: 전부 통과"; exit 0; fi
echo "❌ test-check-docs: 실패"; exit 1

#!/usr/bin/env bash
# 문서 정합성 검사 — 방법론 문서의 기계적 오류를 잡는다 (규칙 준수의 최소 강제 수단).
#   1) 플레이스홀더 잔존   : 실문서에 [한글 플레이스홀더]·VAR_NAME·YYYY-MM-DD·ID 리터럴이 남아 있는지
#   2) REQ/FR 상호 참조     : 요구사항 2분할 문서 간 댕글링 참조
#   3) DEC 번호             : decision-log.md 번호 중복·비단조 증가
# 기본은 경고만(exit 0). --strict 는 경고 발생 시 exit 1 (CI/커밋 전 검사용).
set -u

STRICT=0
[ "${1:-}" = "--strict" ] && STRICT=1

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1
WARN=0

warn() { WARN=$((WARN + 1)); printf '⚠️  %s\n' "$1"; }

# 코드펜스 전체를 빈 줄로 치환한다(행번호 보존).
#   mermaid 노드 라벨(`[집계 엔진]`)뿐 아니라, 일반 펜스의 스키마·열거형 표기
#   (`상태[신청|선정|탈락]`)도 한국어 기술 문서의 관용 표기라 플레이스홀더와 구분되지 않는다.
#   펜스 안을 검사하면 원본 기획서에서 스키마를 그대로 옮겨올 수 없어져, 린터를 달래려고
#   문서 품질을 깎는 일이 생긴다. 펜스 안 플레이스홀더는 어차피 템플릿(_TEMPLATE-*·
#   _skeleton-*)에 몰려 있고 그쪽은 이미 검사에서 제외된다.
strip_fences() {
  awk '/^[[:space:]]*```/ {inf = !inf; print ""; next} inf {print ""; next} {print}' "$1"
}

# 인라인 코드(백틱) 안을 비운다. ID 리터럴 검사에만 쓴다 —
# 규약을 설명할 때는 관례적으로 `DEC-NNN`처럼 백틱을 쓰는 반면, 치환 대상 플레이스홀더는
# 맨몸으로 남기 때문이다. 대괄호·VAR_NAME 검사에는 적용하지 않는다(스켈레톤 Configuration
# 표의 `VAR_NAME`처럼 백틱 안에 있는 진짜 플레이스홀더를 놓치지 않기 위함).
strip_inline_code() { sed 's/`[^`]*`//g'; }

# 플레이스홀더 검출(행번호 보존). 두 갈래로 나눠 각자 다른 제외 규칙을 적용한다.
#   A) 비-ASCII 대괄호 · VAR_NAME · YYYY-MM-DD/HH:MM  — 펜스만 제외
#   B) ID 리터럴(-NNN/-NN/-N-M)                        — 펜스 + 인라인 코드 제외
#   공통 제외: 마크다운 링크/이미지(`](`)·각주(`[^`).
#   스켈레톤 플레이스홀더는 전부 한글(비-ASCII)을 포함하므로, 체크박스([ ]/[x])·
#   [Unreleased]·코드 인덱싱(arr[idx]) 등 ASCII 정상 표기는 자연히 제외된다.
#   `[^ -~]`(0x20~0x7E 밖=비-ASCII 바이트) + LC_ALL=C 로 로케일 독립(비-UTF-8 CI에서도 동일 동작).
scan_placeholders() {
  {
    strip_fences "$1" | LC_ALL=C grep -nE '\[[^]]*[^ -~][^]]*\]|VAR_NAME|YYYY-MM-DD|HH:MM'
    strip_fences "$1" | strip_inline_code | LC_ALL=C grep -nE '[A-Z]{2,}-(NNN|NN|N-M)'
  } | LC_ALL=C grep -vE '\]\(|\[\^' | sort -t: -k1,1n -u
}

# ── 1. 플레이스홀더 잔존 검사 ─────────────────────────────────────────────
# 템플릿(_TEMPLATE-*, _skeleton-*)과 룰(형식 예시 포함)은 플레이스홀더가 정상이므로 제외.
#
# 템플릿 자기감지: 루트에 _skeleton-README.md 가 있으면 = 스캐폴드 템플릿 레포 자신이다
# (골격의 플레이스홀더는 정상). 대상 프로젝트는 부트스트랩 때 이 파일을 지우므로,
# 그때부터 플레이스홀더 검사가 자동으로 켜진다. 구조 검사(2·3)는 두 경우 모두 수행한다.
if [ -f "_skeleton-README.md" ]; then
  echo "ℹ️  스캐폴드 템플릿 레포로 감지(_skeleton-README.md 존재) — 플레이스홀더 검사 생략"
else
  REAL_DOCS=""
  for f in .claude/CLAUDE.md CLAUDE.md README.md docs/user-guide.md docs/how-it-works.md \
           .claude/docs/*.md .claude/workspace/*.md; do
    [ -f "$f" ] && REAL_DOCS="$REAL_DOCS $f"
  done

  for f in $REAL_DOCS; do
    all=$(scan_placeholders "$f")
    if [ -n "$all" ]; then
      n=$(printf '%s\n' "$all" | wc -l | tr -d ' ')
      warn "플레이스홀더 잔존: $f (${n}건)"
      printf '%s\n' "$all" | head -5 | sed 's/^/      /'
      [ "$n" -gt 5 ] && echo "      … 외 $((n - 5))건"
    fi
  done
fi

# ── 2. REQ ↔ FR 상호 참조 검사 ────────────────────────────────────────────
IMPL=".claude/docs/01-impl-requirements.md"
USER=".claude/docs/01-user-requirements.md"
if [ -f "$IMPL" ] && [ -f "$USER" ]; then
  # user 문서가 참조하는 REQ가 impl 문서에 정의(### REQ-… 헤딩)돼 있는가
  for req in $(grep -oE 'REQ-[0-9]+-[0-9]+' "$USER" | sort -u); do
    grep -qE "^### ${req}:" "$IMPL" || warn "댕글링 참조: $USER 가 참조한 ${req} 이 $IMPL 에 정의돼 있지 않음"
  done
  # impl 문서가 참조하는 FR가 user 문서에 정의(**FR-NN** 항목)돼 있는가
  for fr in $(grep -oE 'FR-[0-9]+' "$IMPL" | sort -u); do
    grep -qE "\*\*${fr}\*\*" "$USER" || warn "댕글링 참조: $IMPL 가 참조한 ${fr} 이 $USER 에 정의돼 있지 않음"
  done
fi

# ── 3. DEC 번호 중복·단조 증가 검사 ──────────────────────────────────────
DECLOG=".claude/decisions/decision-log.md"
if [ -f "$DECLOG" ]; then
  nums=$(grep -oE '^## DEC-[0-9]+' "$DECLOG" | grep -oE '[0-9]+')
  dup=$(printf '%s\n' "$nums" | sort | uniq -d)
  [ -n "$dup" ] && warn "DEC 번호 중복: $(printf '%s ' $dup)(병렬 세션 충돌 여부 확인)"
  if [ "$(printf '%s\n' "$nums")" != "$(printf '%s\n' "$nums" | sort -n)" ]; then
    warn "DEC 번호가 파일 순서상 단조 증가하지 않음 (append-only 위반 가능성)"
  fi
fi

# ── 4. DEC 댕글링 참조 검사 ──────────────────────────────────────────────
# 부트스트랩은 "로그를 비우고 대상 프로젝트의 DEC-001부터 시작"을 지시하므로, 룰·문서 본문이
# 참조하는 DEC 번호가 존재하지 않는 결정이 되기 쉽다(REQ/FR 댕글링과 같은 실패 모드인데
# 지금까지 검사되지 않아 조용히 살아남았다).
# 코드펜스 안(형식 예시)과 백틱 표기(규약 설명)는 실제 상호 참조가 아니므로 제외한다.
if [ -f "$DECLOG" ]; then
  REF_DOCS=""
  for f in .claude/CLAUDE.md CLAUDE.md README.md docs/user-guide.md docs/how-it-works.md \
           .claude/docs/*.md .claude/workspace/*.md .claude/rules/*.md; do
    [ -f "$f" ] && REF_DOCS="$REF_DOCS $f"
  done
  for f in $REF_DOCS; do
    for dec in $(strip_fences "$f" | strip_inline_code | grep -oE 'DEC-[0-9]+' | sort -u); do
      grep -qE "^## ${dec}:" "$DECLOG" \
        || warn "댕글링 참조: $f 가 참조한 ${dec} 이 $DECLOG 에 정의돼 있지 않음"
    done
  done
fi

# ── 결과 ─────────────────────────────────────────────────────────────────
if [ "$WARN" -eq 0 ]; then
  echo "✅ check-docs: 문제 없음"
  exit 0
fi
echo "── check-docs: 경고 ${WARN}건"
[ "$STRICT" -eq 1 ] && exit 1
exit 0

#!/usr/bin/env bash
# 문서 정합성 검사 — 방법론 문서의 기계적 오류를 잡는다 (규칙 준수의 최소 강제 수단).
#   1) 플레이스홀더 잔존   : 실문서에 [한글 플레이스홀더]·VAR_NAME·YYYY-MM-DD·ID 리터럴이 남아 있는지
#   2) REQ/FR 상호 참조     : 요구사항 2분할 문서 간 댕글링 참조
#   3) DEC 번호             : decision-log.md 번호 중복·비단조 증가
#   4) DEC 댕글링 참조      : 룰·문서가 참조한 DEC 번호가 로그에 정의돼 있는지
#   5) changelog 스테일     : changelog 갱신 없이 feat/fix 커밋이 쌓였는지
#   6) 버전 3자 일치        : 버전 SoT ↔ changelog 최신 릴리즈 ↔ git tag
# 기본은 경고만(exit 0). --strict 는 경고 발생 시 exit 1 (CI/커밋 전 검사용).
set -u

STRICT=0
[ "${1:-}" = "--strict" ] && STRICT=1

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1
WARN=0

# 버전·changelog 조회 함수(§5·§6). 없어도 나머지 검사는 그대로 동작하도록 방어한다.
# shellcheck source=lib-version.sh
[ -f "$ROOT/scripts/lib-version.sh" ] && . "$ROOT/scripts/lib-version.sh"

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
  # ── 9. 필수 납품 문서 존재 검사 ────────────────────────────────────────
  # 아래 REAL_DOCS 는 glob 이라 **파일이 아예 없으면 조용히 건너뛴다** — "문서가 미작성"은
  # 잡아도 "문서가 없음"은 못 잡는다. 부트스트랩 직후나 실수로 지운 경우가 그대로 통과했다.
  # CLAUDE.md 는 루트/`.claude/` 어느 쪽이든 하나면 된다(project-init 이 두 위치를 모두 인정.
  # 스캐폴드 자신은 `.claude/CLAUDE.md` 만 쓰고 파생 레포들은 루트를 쓴다).
  # user-guide·how-it-works 를 필수로 두지 않는 이유는 DEC-009 의 lazy 생성 규정 때문이다.
  [ -f "README.md" ] || warn "필수 문서 누락: README.md"
  [ -f "CLAUDE.md" ] || [ -f ".claude/CLAUDE.md" ] \
    || warn "필수 문서 누락: CLAUDE.md (루트 또는 .claude/ 중 한 곳에 필요)"

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

# ── 참조 검사용 문서 집합 (§4 DEC · §7 BACKLOG 공용) ──────────────────────
# 작업 단위 산출물(docs/superpowers/)은 제외한다 — 템플릿(_TEMPLATE-*)의 플레이스홀더를
# 걸러낼 새 규칙이 필요해지는데, 그 비용이 얻는 것보다 크다(DEC-015).
REF_DOCS=""
for f in .claude/CLAUDE.md CLAUDE.md README.md docs/user-guide.md docs/how-it-works.md \
         .claude/docs/*.md .claude/workspace/*.md .claude/rules/*.md; do
  [ -f "$f" ] && REF_DOCS="$REF_DOCS $f"
done

# ── 4. DEC 댕글링 참조 검사 ──────────────────────────────────────────────
# 부트스트랩은 "로그를 비우고 대상 프로젝트의 DEC-001부터 시작"을 지시하므로, 룰·문서 본문이
# 참조하는 DEC 번호가 존재하지 않는 결정이 되기 쉽다(REQ/FR 댕글링과 같은 실패 모드인데
# 지금까지 검사되지 않아 조용히 살아남았다).
# 코드펜스 안(형식 예시)과 백틱 표기(규약 설명)는 실제 상호 참조가 아니므로 제외한다.
if [ -f "$DECLOG" ]; then
  for f in $REF_DOCS; do
    for dec in $(strip_fences "$f" | strip_inline_code | grep -oE 'DEC-[0-9]+' | sort -u); do
      grep -qE "^## ${dec}:" "$DECLOG" \
        || warn "댕글링 참조: $f 가 참조한 ${dec} 이 $DECLOG 에 정의돼 있지 않음"
    done
  done
fi

# ── 5. changelog 스테일 검사 ─────────────────────────────────────────────
# changelog 를 마지막으로 수정한 커밋 이후 feat/fix 가 3건 이상 쌓였으면 경고.
# 유예를 두는 이유: 작업 중 연속 커밋마다 경고가 뜨면 피로도가 높아 결국 전부 무시하게 된다.
# [Unreleased] 가 비었는지는 신호로 쓰지 않는다 — 릴리즈 직후엔 정상적으로 비어 있어
# 매 릴리즈마다 오탐이 난다. 신호는 "파일이 커밋에서 수정됐는가" 하나다.
STALE_THRESHOLD=3
if command -v commits_since_changelog >/dev/null 2>&1 && [ -f "$CHANGELOG_PATH" ]; then
  n=$(commits_since_changelog)
  if [ "${n:-0}" -ge "$STALE_THRESHOLD" ]; then
    warn "changelog 스테일: 마지막 갱신 이후 feat/fix 커밋 ${n}건 — $CHANGELOG_PATH 에 반영하세요"
  fi
fi

# ── 6. 버전 3자 일치 검사 ────────────────────────────────────────────────
# SoT ↔ changelog 최신 릴리즈 ↔ git tag. 정책이 none 이거나 SoT 가 없으면 검사 자체를 건너뛴다.
# **태그 미달성은 경고가 아니라 안내**다 — /release 는 파일만 고치고 태그는 사람이 달므로,
# 그 사이 구간을 경고로 만들면 릴리즈마다 빨간불이 뜨고 PR 브랜치(태그 없음)에서 CI 가 상시
# 실패한다. 반대로 태그가 SoT 보다 앞선 역전은 명백한 오류라 경고한다.
if command -v detect_version_sot >/dev/null 2>&1; then
  POLICY=$(read_version_policy)
  SOT_F=$(sot_file); SOT_V=$(sot_version)
  if [ "$POLICY" != "none" ] && [ -n "$SOT_V" ]; then
    if [ "$POLICY" = "semver" ] && ! is_semver "$SOT_V"; then
      warn "버전 형식 위반: $SOT_F 의 '$SOT_V' 가 semver(X.Y.Z)가 아님 (정책: $POLICY)"
    fi
    CL_V=$(changelog_latest_release)
    if [ -n "$CL_V" ] && [ "$CL_V" != "$SOT_V" ]; then
      warn "버전 불일치: $SOT_F 는 '$SOT_V' 인데 $CHANGELOG_PATH 최신 릴리즈는 '$CL_V' — /release 로 함께 갱신하세요"
    fi
    TAG_V=$(latest_git_tag)
    if [ -n "$TAG_V" ] && version_gt "$TAG_V" "$SOT_V"; then
      warn "버전 역전: git tag 'v$TAG_V' 가 $SOT_F 의 '$SOT_V' 보다 앞섬"
    elif [ "$CL_V" = "$SOT_V" ] && [ "$TAG_V" != "$SOT_V" ] && git_history_usable; then
      echo "ℹ️  v$SOT_V 태그가 아직 없습니다 — 릴리즈를 확정하려면: git tag v$SOT_V"
    fi
  fi
fi

# ── 7. BACKLOG 상태 정합성 검사 ──────────────────────────────────────────
# 갱신 묶음(readme-sync.md) 3번이 지켜지지 않으면 BACKLOG 표만 조용히 낡는다. 룰 문장으로는
# 이미 한 번 실패했으므로(§5 changelog와 같은 실패 모드) 기계로 잡는다. 근거: DEC-015.
# 재료가 없으면 스킵한다 — BACKLOG 표를 쓰지 않는 프로젝트에 경고를 만들지 않는다.
TODO=".claude/workspace/todo.md"

# 표에 정의된 BACKLOG 번호들. 행 형식: | BACKLOG-NNN | 제목 | 상태 | 근거 |
backlog_ids() {
  [ -f "$TODO" ] || return 0
  grep -oE '^\|[[:space:]]*BACKLOG-[0-9]+' "$TODO" | grep -oE 'BACKLOG-[0-9]+' | sort -u
}

# 그 행의 상태 칸. awk -F'|' 기준 $2=ID, $4=상태.
backlog_status() {
  awk -F'|' -v id="$1" '
    { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2) }
    $2 == id { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4; exit }
  ' "$TODO"
}

# 완료 판정: ✅ 또는 "완료". 단 "미완료"는 완료가 아니다.
backlog_done() {
  case "$1" in
    *미완료*)   return 1 ;;
    *✅*|*완료*) return 0 ;;
    *)          return 1 ;;
  esac
}

if [ -f "$TODO" ] && [ -n "$(backlog_ids)" ]; then
  # (B) 같은 파일 안 자기모순 — 완료 체크박스 줄이 언급한 항목인데 표는 미완료.
  # 신호를 "## ✅ 완료" 섹션이 아니라 `- [x]` 줄로 잡는 이유: 섹션 제목은 프로젝트마다 다르지만
  # 완료 체크박스는 마크다운 공통 표기라 파생 프로젝트에서 조용히 무력화되지 않는다.
  for id in $(grep -E '^[[:space:]]*-[[:space:]]*\[x\]' "$TODO" \
              | grep -oE 'BACKLOG-[0-9]+' | sort -u); do
    st=$(backlog_status "$id")
    [ -n "$st" ] && ! backlog_done "$st" \
      && warn "BACKLOG 불일치: $TODO 의 완료 체크박스가 ${id} 를 언급하는데 표의 상태는 '${st}'"
  done

  # (A) 릴리즈까지 끝났는데 표는 미완료. 릴리즈 구간 = 첫 '## vX.Y.Z' 헤딩 이후 전부.
  # [Unreleased] 를 제외하는 이유: 작업 중 ID 언급은 정상이고, 그걸 경고로 만들면
  # 작업 내내 로컬 Stop hook 이 시끄러워진다(§5가 유예를 두는 것과 같은 이유).
  #
  # **feat/fix 항목의 언급만** 완료 신호로 본다. docs·chore 항목은 "그 BACKLOG를 적어뒀다"는
  # 뜻으로 ID를 인용하는 일이 흔해서, 전 구간을 보면 대기 항목이 릴리즈마다 경고로 뜬다
  # (이 레포 자신의 v0.1.0 "글로벌 룰 버전 관리를 README 로드맵 + BACKLOG-001로 기록" 줄에서
  # 실제로 재현했다). feat/fix 만 세는 것은 §5가 이미 쓰는 규약과 같다. 근거: DEC-016.
  # 항목은 여러 줄에 걸치므로 `- ` 로 시작하는 줄에서 타입을 판정하고 다음 항목까지 유지한다.
  CL="${CHANGELOG_PATH:-.claude/workspace/changelog.md}"
  if [ -f "$CL" ]; then
    for id in $(awk '
        /^##[[:space:]]+v?[0-9]+\.[0-9]+\.[0-9]+/ { rel = 1 }
        !rel { next }
        /^[[:space:]]*-[[:space:]]/ { keep = ($0 ~ /^[[:space:]]*-[[:space:]]*\*\*(feat|fix)\*\*/) }
        /^#/ { keep = 0 }
        keep' "$CL" \
                | grep -oE 'BACKLOG-[0-9]+' | sort -u); do
      st=$(backlog_status "$id")
      [ -n "$st" ] && ! backlog_done "$st" \
        && warn "BACKLOG 스테일: $CL 의 릴리즈된 구간이 ${id} 를 언급하는데 $TODO 표의 상태는 '${st}' — 닫고 근거를 남기세요"
    done
  fi

  # (C) 표에서 사라진 항목을 문서가 계속 참조 — §4 DEC 댕글링과 같은 실패 모드다.
  # 제외 규칙도 §4와 동일하다: 코드펜스(형식 예시)와 백틱(규약 설명)은 실제 참조가 아니다.
  DEFINED=$(backlog_ids)
  for f in $REF_DOCS; do
    for id in $(strip_fences "$f" | strip_inline_code | grep -oE 'BACKLOG-[0-9]+' | sort -u); do
      printf '%s\n' "$DEFINED" | grep -qx "$id" \
        || warn "댕글링 참조: $f 가 참조한 ${id} 이 $TODO 표에 정의돼 있지 않음"
    done
  done
fi

# ── 8. 릴리즈 버전의 README 반영 검사 ────────────────────────────────────
# §6 은 SoT ↔ changelog ↔ tag 셋만 본다. 그 셋이 다 맞아도 README 가 낡을 수 있고, 실제로
# 파괴적 변경을 알리는 버전 표가 비어 있는 채로 릴리즈된 적이 있다(DEC-017).
#
# 판정: **직전 릴리즈가 README 에 있는데 현재 버전이 없으면** 경고. 둘 다 없으면 그 레포는
# README 에 버전을 적지 않는 것이므로 스킵한다 — 설정 없이 습관을 자동 감지한다.
# 직전 버전은 changelog 에서 찾고, 없으면 git tag 로 폴백한다(changelog 를 루트 CHANGELOG.md
# 에 두는 레포에서도 동작하게).
# 한계: 문자열 포함만 보므로 행이 있어도 내용이 비면 못 잡고, 첫 릴리즈는 비교 대상이 없다.
ver_in_file() {  # $1=버전 $2=파일. 10.2.0 을 0.2.0 으로 오인하지 않도록 경계를 본다.
  esc=$(printf '%s' "$1" | sed 's/\./\\./g')
  grep -qE "(^|[^0-9.])${esc}([^0-9.]|\$)" "$2"
}

if command -v detect_version_sot >/dev/null 2>&1 && [ -f "README.md" ]; then
  POLICY8=$(read_version_policy)
  SOT8=$(sot_version)
  if [ "$POLICY8" != "none" ] && [ -n "$SOT8" ]; then
    PREV8=$(changelog_previous_release "$SOT8")
    [ -z "$PREV8" ] && PREV8=$(previous_git_tag "$SOT8")
    if [ -n "$PREV8" ] && ver_in_file "$PREV8" README.md && ! ver_in_file "$SOT8" README.md; then
      warn "README 버전 미반영: 직전 릴리즈 '$PREV8' 는 README.md 에 있는데 현재 '$SOT8' 이 없습니다 — 버전 표·기능 목록·업그레이드 안내를 확인하세요"
    fi
  fi
fi

# ── 10. 스캐폴드 버전 스탬프 일치 검사 (템플릿 레포 한정) ────────────────
# .claude/SCAFFOLD-VERSION 은 `.claude/` 와 함께 복사되어 파생 레포에 따라간다. 파생 레포에서
# 이 값과 VERSION 이 다른 것은 **정상**이다(스탬프=받아온 스캐폴드 버전, VERSION=자기 버전).
# 그래서 일치 검사는 업스트림(_skeleton-README.md 가 있는 템플릿 레포)에서만 한다.
SCAFFOLD_STAMP=".claude/SCAFFOLD-VERSION"
if [ -f "_skeleton-README.md" ] && [ -f "$SCAFFOLD_STAMP" ] && [ -f "VERSION" ]; then
  s=$(head -1 "$SCAFFOLD_STAMP" | tr -d '[:space:]')
  v=$(head -1 VERSION | tr -d '[:space:]')
  [ "$s" = "$v" ] \
    || warn "스탬프 불일치: $SCAFFOLD_STAMP 는 '$s' 인데 VERSION 은 '$v' — /release 로 함께 갱신하세요"
fi

# ── 결과 ─────────────────────────────────────────────────────────────────
if [ "$WARN" -eq 0 ]; then
  echo "✅ check-docs: 문제 없음"
  exit 0
fi
echo "── check-docs: 경고 ${WARN}건"
[ "$STRICT" -eq 1 ] && exit 1
exit 0

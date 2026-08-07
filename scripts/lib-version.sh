#!/usr/bin/env bash
# 버전·changelog 조회 함수 모음 — check-docs.sh 와 new-release.sh 가 함께 source 한다.
#
# 설계 원칙: **순수 조회만 한다.** 값을 반환할 뿐 경고 문구를 만들거나 파일을 쓰지 않는다.
# 경고 표현은 호출자(check-docs)가, 쓰기는 new-release가 담당한다. 그래야 감지 로직만
# 따로 회귀 테스트할 수 있고, 진입점을 늘리지 않고도 두 스크립트가 같은 감지를 공유한다.
#
# 이 파일은 실행 파일이 아니다(source 전용). set -e 등 셸 옵션을 건드리지 않는다.

CHANGELOG_PATH=".claude/workspace/changelog.md"
COMMANDS_RULE_PATH=".claude/rules/commands.md"

# ── 버전 SoT 감지 ─────────────────────────────────────────────────────────
# "<파일>:<버전>" 형태로 반환. 없으면 빈 문자열.
# 언어 매니페스트가 있으면 그것이 이미 SoT다. 별도 버전 파일을 더하면 이중 관리가 되어
# 드리프트하는데, 그게 이 harness가 없애려는 문제 그 자체다.
detect_version_sot() {
  if [ -f "package.json" ]; then
    v=$(grep -m1 -E '"version"[[:space:]]*:' package.json \
        | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
    [ -n "$v" ] && { printf 'package.json:%s\n' "$v"; return 0; }
  fi
  if [ -f "pyproject.toml" ]; then
    v=$(awk '/^\[project\]/{f=1;next} /^\[/{f=0} f && /^[[:space:]]*version[[:space:]]*=/{
           sub(/.*=[[:space:]]*/,""); gsub(/["'"'"']/,""); print; exit}' pyproject.toml)
    [ -n "$v" ] && { printf 'pyproject.toml:%s\n' "$v"; return 0; }
  fi
  if [ -f "Cargo.toml" ]; then
    v=$(awk '/^\[package\]/{f=1;next} /^\[/{f=0} f && /^[[:space:]]*version[[:space:]]*=/{
           sub(/.*=[[:space:]]*/,""); gsub(/["'"'"']/,""); print; exit}' Cargo.toml)
    [ -n "$v" ] && { printf 'Cargo.toml:%s\n' "$v"; return 0; }
  fi
  if [ -f "VERSION" ]; then
    v=$(head -1 VERSION | tr -d '[:space:]')
    [ -n "$v" ] && { printf 'VERSION:%s\n' "$v"; return 0; }
  fi
  return 0
}

sot_file()    { detect_version_sot | cut -d: -f1; }
sot_version() { detect_version_sot | cut -d: -f2-; }

# ── 버전 정책 ─────────────────────────────────────────────────────────────
# semver(기본) / calver / none. 자동 감지를 override 하고 싶을 때만 commands.md 에 선언한다.
#   ## 버전 정책
#   version-policy: none
read_version_policy() {
  p=""
  [ -f "$COMMANDS_RULE_PATH" ] && p=$(grep -m1 -E '^[[:space:]]*version-policy[[:space:]]*:' \
      "$COMMANDS_RULE_PATH" | sed -E 's/.*:[[:space:]]*//' | tr -d '[:space:]')
  case "$p" in
    semver|calver|none) printf '%s\n' "$p" ;;
    *)                  printf 'semver\n' ;;
  esac
}

# ── changelog 최신 릴리즈 ─────────────────────────────────────────────────
# '## v0.3.0 (2026-07-27)' 형태의 첫 릴리즈 헤딩에서 버전만 뽑는다.
# [Unreleased] 는 릴리즈가 아니므로 건너뛴다.
changelog_latest_release() {
  [ -f "$CHANGELOG_PATH" ] || return 0
  grep -m1 -E '^##[[:space:]]+v?[0-9]+\.[0-9]+\.[0-9]+' "$CHANGELOG_PATH" \
    | sed -E 's/^##[[:space:]]+v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/'
}

# changelog 릴리즈 헤딩 중 $1(현재 버전)이 아닌 첫 번째. 없으면 빈 문자열.
# §8 이 "직전 릴리즈"를 필요로 한다 — latest 는 대개 현재 버전이라 비교 대상이 못 된다.
changelog_previous_release() {
  [ -f "$CHANGELOG_PATH" ] || return 0
  grep -E '^##[[:space:]]+v?[0-9]+\.[0-9]+\.[0-9]+' "$CHANGELOG_PATH" \
    | sed -E 's/^##[[:space:]]+v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/' \
    | grep -vx "${1:-}" | head -1
}

# ── git 상태 ──────────────────────────────────────────────────────────────
# 검사를 건너뛰어야 하는 상황인지 판정한다. git 레포가 아니거나 shallow clone 이면
# 히스토리 기반 판정이 성립하지 않으므로 **경고가 아니라 스킵**이 옳다.
# (actions/checkout@v4 는 기본 depth 1 이라 CI 에서 fetch-depth: 0 이 필요하다.)
git_history_usable() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ] && return 1
  git rev-parse HEAD >/dev/null 2>&1 || return 1
  return 0
}

# 최신 semver 태그의 버전. 태그가 없으면 빈 문자열.
latest_git_tag() {
  git_history_usable || return 0
  git tag -l 'v*' 2>/dev/null \
    | sed -E 's/^v//' \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -1
}

# semver 태그 중 $1(현재 버전)을 제외한 최댓값. 없으면 빈 문자열.
# changelog 를 표준 경로($CHANGELOG_PATH)에 두지 않는 레포(루트 CHANGELOG.md 등)를 위한
# §8 폴백이다. 태그가 없거나 shallow clone 이면 빈 값이 되어 §8 이 조용히 스킵된다.
previous_git_tag() {
  git_history_usable || return 0
  git tag -l 'v*' 2>/dev/null \
    | sed -E 's/^v//' \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | grep -vx "${1:-}" \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -1
}

# changelog 를 마지막으로 수정한 커밋 이후 쌓인 feat/fix 커밋 수.
# feat/fix 만 세는 이유: readme-sync 의 갱신 트리거 표에서도 docs·chore·refactor·test 는
# 제외 대상이다. perf 는 사용자 영향이 애매해 뺐다.
# changelog 가 한 번도 커밋된 적 없으면 전체 히스토리를 센다.
commits_since_changelog() {
  git_history_usable || { printf '0\n'; return 0; }
  # 워킹트리에서 이미 changelog 를 고치는 중이면 스테일이 아니다 — 지금 반영하고 있는데
  # 커밋 전까지 계속 경고하면 로컬 Stop hook 이 작업 내내 시끄러워진다.
  if ! git diff --quiet HEAD -- "$CHANGELOG_PATH" 2>/dev/null; then
    printf '0\n'; return 0
  fi
  base=$(git log -1 --format=%H -- "$CHANGELOG_PATH" 2>/dev/null)
  if [ -n "$base" ]; then
    range="${base}..HEAD"
  else
    range="HEAD"
  fi
  git log --format=%s "$range" 2>/dev/null \
    | grep -cE '^(feat|fix)(\([^)]*\))?!?:' || true
}

# ── 버전 비교 ─────────────────────────────────────────────────────────────
is_semver() { printf '%s' "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; }

# $1 > $2 이면 0(참). semver 형식이 아니면 1(거짓) — 비교할 수 없는 값으로 경고를 만들지 않는다.
version_gt() {
  is_semver "$1" && is_semver "$2" || return 1
  [ "$1" = "$2" ] && return 1
  greater=$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
  [ "$greater" = "$1" ]
}

# major|minor|patch 를 적용한 다음 버전을 반환한다.
bump_version() {
  cur="$1"; kind="$2"
  is_semver "$cur" || return 1
  MA=$(printf '%s' "$cur" | cut -d. -f1)
  MI=$(printf '%s' "$cur" | cut -d. -f2)
  PA=$(printf '%s' "$cur" | cut -d. -f3)
  case "$kind" in
    major) MA=$((MA + 1)); MI=0; PA=0 ;;
    minor) MI=$((MI + 1)); PA=0 ;;
    patch) PA=$((PA + 1)) ;;
    *)     return 1 ;;
  esac
  printf '%s.%s.%s\n' "$MA" "$MI" "$PA"
}

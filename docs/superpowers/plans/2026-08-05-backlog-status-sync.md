---
related: [BACKLOG-003, DEC-015]
spec: docs/superpowers/specs/2026-08-05-backlog-status-sync-design.md
status: done
date: 2026-08-05
---

> ⚠️ **실제 구현은 Task 2의 §7-A 코드와 다르다.** 구현 직후 이 레포 자신의 v0.1.0 changelog에서
> 오탐이 재현되어, 릴리즈 구간 전체가 아니라 `feat`/`fix` 항목의 언급만 완료 신호로 보도록
> 좁혔다(DEC-016). 실물은 `scripts/check-docs.sh` §7 — 아래 코드 블록을 그대로 복사하지 말 것.

# 구현 계획: BACKLOG 상태 동기화 — 갱신 묶음 항목 + check-docs §7

> spec: `docs/superpowers/specs/2026-08-05-backlog-status-sync-design.md` / 결정: DEC-015

## 개요

`readme-sync.md` 갱신 묶음에 BACKLOG 표 갱신을 명시적 항목으로 올리고(7→8), 그 룰이 지켜지지
않아도 낡은 상태를 잡도록 `check-docs.sh` §7(신호 A·B·C)을 신설한다. 관련: BACKLOG-003, DEC-015.

## 전역 제약

- **셸**: `#!/usr/bin/env bash` + `set -u`. bash 3.2(macOS 기본)에서 동작해야 한다 —
  연관 배열·`${var,,}` 같은 bash 4 문법 금지. GNU 전용 옵션 금지(`grep -P`, `sed -i` 등).
- **경고 표현**: 반드시 기존 `warn()`을 쓴다. 새 종료코드·새 강제 개념을 만들지 않는다
  (로컬 Stop hook 비차단 / CI `--strict` 차단이라는 기존 모델 유지).
- **스킵 우선**: 판정 재료가 없으면 경고가 아니라 스킵이다(§5·§6의 기존 원칙).
- **테스트**: `scripts/test-check-docs.sh`의 `new_project` 픽스처 헬퍼를 그대로 쓴다.
  픽스처는 git 레포가 아니므로 §5·§6은 자동으로 스킵된다.
- **BACKLOG 표 행 형식**: `| BACKLOG-NNN | 제목 | 상태 | 근거 |` — 상태는 `awk -F'|'` 기준 `$4`.

## 변경 파일

| 파일 | 변경 |
|------|------|
| `scripts/check-docs.sh` | §7 신설(A·B·C) + §4의 `REF_DOCS` 구성을 §4·§7 공용으로 호이스팅 |
| `scripts/test-check-docs.sh` | 회귀 케이스 6건 추가(정탐 3 / 오탐 방지 3) |
| `.claude/rules/readme-sync.md` | 갱신 묶음 7→8, 조건부 안내 "7·8", 절 2개 추가, BACKLOG 표 스키마 |
| `.claude/workspace/todo.md` | 표 헤더 `spec/plan`→`근거`, 기존 2행 이관, BACKLOG-003 등록 |
| `.claude/rules/commands.md` | `check-docs.sh` 설명에 §7 추가 |
| `README.md` | 디렉토리 트리 주석(:133)·`todo.md` semantics(:177)에 §7 반영 |
| `.claude/rules/project-init.md` | 디렉토리 구조 블록의 `check-docs.sh` 주석에 BACKLOG 추가 |
| `.claude/workspace/changelog.md` | `[Unreleased]`에 이번 변경 기록 |

---

## Task 1: BACKLOG 표 파싱 + 스킵 조건 + 신호 B(자기모순)

**파일**
- 수정: `scripts/check-docs.sh` (§6 뒤, "── 결과 ──" 앞)
- 테스트: `scripts/test-check-docs.sh` (파일 끝, 결과 집계 앞)

**이 태스크가 만드는 것** — 뒤 태스크가 그대로 쓴다.
- `backlog_ids()` — 표에 정의된 BACKLOG 번호 목록(줄바꿈 구분)
- `backlog_status <id>` — 그 행의 상태 칸 문자열(없으면 빈 문자열)
- `backlog_done <상태문자열>` — 완료면 exit 0
- 변수 `TODO` — `.claude/workspace/todo.md`

- [ ] **Step 1: 실패하는 테스트를 먼저 쓴다**

`scripts/test-check-docs.sh` 끝의 결과 집계(`if [ "$FAIL" -eq 0 ]`) **앞**에 추가:

```bash
# ── §7 BACKLOG 상태 정합성 ────────────────────────────────────────────────
# 완료 체크박스가 닫혔는데 BACKLOG 표만 낡는 실패를 잡는다(readme-sync 갱신 묶음 3번).
P="$T/backlog-b"; new_project "$P"
cat > "$P/.claude/workspace/todo.md" <<'EOF'
# TODO
## ✅ 완료
- [x] flexContainer 구현 (BACKLOG-005) — 완료: 2026-08-01

## 백로그 (BACKLOG)
| ID | 제목 | 상태 | 근거 |
|----|------|------|------|
| BACKLOG-005 | flexContainer 구현 | 🔄 진행중 | |
EOF
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'BACKLOG-005' \
  && pass "§7-B 완료 체크박스 ↔ 표 상태 불일치 검출" || fail "§7-B 자기모순을 놓침"

# 표가 없으면(= BACKLOG를 쓰지 않는 프로젝트) 검사 자체를 건너뛴다.
P="$T/backlog-skip"; new_project "$P"
printf '%s\n' '# TODO' '- [x] flexContainer 구현 (BACKLOG-005)' > "$P/.claude/workspace/todo.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'BACKLOG-005' \
  && fail "BACKLOG 표가 없는데 경고(스킵 조건 미동작)" || pass "BACKLOG 표 없으면 §7 스킵"
```

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

```bash
bash scripts/test-check-docs.sh
```
기대: `✗ §7-B 자기모순을 놓침` (스킵 케이스는 §7이 아예 없으므로 이미 통과 — 정상이다.
이 케이스는 Step 3 이후에도 계속 통과해야 의미가 있다)

- [ ] **Step 3: §7 골격 + 신호 B를 구현한다**

`scripts/check-docs.sh`의 §6 블록 끝(`fi` 뒤)과 `# ── 결과 ──` 사이에 추가:

```bash
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
    *미완료*) return 1 ;;
    *✅*|*완료*) return 0 ;;
    *) return 1 ;;
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
fi
```

- [ ] **Step 4: 테스트가 통과하는지 확인한다**

```bash
bash scripts/test-check-docs.sh
```
기대: `✓ §7-B 완료 체크박스 ↔ 표 상태 불일치 검출` · `✓ BACKLOG 표 없으면 §7 스킵`, 종료코드 0

- [ ] **Step 5: 커밋**

```bash
git add scripts/check-docs.sh scripts/test-check-docs.sh
git commit -m "feat: check-docs §7 골격 + BACKLOG 자기모순 검사(신호 B)"
```

---

## Task 2: 신호 A — changelog 릴리즈 구간 ↔ 표 상태

**파일**
- 수정: `scripts/check-docs.sh` (Task 1이 만든 `if [ -f "$TODO" ] …` 블록 안, B 다음)
- 테스트: `scripts/test-check-docs.sh`

**소비**: Task 1의 `backlog_status`·`backlog_done`, `lib-version.sh`의 `CHANGELOG_PATH`
(§5·§6과 달리 §7은 lib가 없어도 동작해야 하므로 `${CHANGELOG_PATH:-…}` 폴백을 쓴다)

- [ ] **Step 1: 실패하는 테스트를 먼저 쓴다**

Task 1이 추가한 블록 아래에 이어서:

```bash
# 릴리즈된 구간(첫 ## vX.Y.Z 이후)에 언급됐는데 표가 미완료 → mobius4에서 실제로 난 사고.
P="$T/backlog-a"; new_project "$P"
cat > "$P/.claude/workspace/todo.md" <<'EOF'
# TODO
## 백로그 (BACKLOG)
| ID | 제목 | 상태 | 근거 |
|----|------|------|------|
| BACKLOG-021 | flexContainer 구현 | 🔄 진행중 | |
EOF
cat > "$P/.claude/workspace/changelog.md" <<'EOF'
# Changelog
## [Unreleased]
## v4.5.0 (2026-08-01)
- **feat**: flexContainer 구현. 관련 BACKLOG-021
EOF
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'BACKLOG-021' \
  && pass "§7-A 릴리즈된 구간 언급 ↔ 표 미완료 검출" || fail "§7-A 릴리즈 스테일을 놓침"

# [Unreleased] 안의 언급은 작업 중이라는 뜻이므로 경고하지 않는다(오탐 상시화 방지).
P="$T/backlog-a-unreleased"; new_project "$P"
cat > "$P/.claude/workspace/todo.md" <<'EOF'
# TODO
## 백로그 (BACKLOG)
| ID | 제목 | 상태 | 근거 |
|----|------|------|------|
| BACKLOG-021 | flexContainer 구현 | 🔄 진행중 | |
EOF
cat > "$P/.claude/workspace/changelog.md" <<'EOF'
# Changelog
## [Unreleased]
- **feat**: flexContainer 작업 착수. 관련 BACKLOG-021
## v4.4.0 (2026-07-20)
- **fix**: 무관한 수정
EOF
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'BACKLOG-021' \
  && fail "[Unreleased] 언급을 오탐" || pass "§7-A [Unreleased] 언급은 무시"
```

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

```bash
bash scripts/test-check-docs.sh
```
기대: `✗ §7-A 릴리즈 스테일을 놓침` (두 번째 케이스는 아직 §7-A가 없어 통과 — Step 3 이후에도
계속 통과해야 한다)

- [ ] **Step 3: 신호 A를 구현한다**

Task 1이 만든 `if [ -f "$TODO" ] && [ -n "$(backlog_ids)" ]; then` 블록 안, B 루프 **아래**에 추가:

```bash
  # (A) 릴리즈까지 끝났는데 표는 미완료. 릴리즈 구간 = 첫 '## vX.Y.Z' 헤딩 이후 전부.
  # [Unreleased] 를 제외하는 이유: 작업 중 ID 언급은 정상이고, 그걸 경고로 만들면
  # 작업 내내 로컬 Stop hook 이 시끄러워진다(§5가 유예를 두는 것과 같은 이유).
  # 알려진 한계: changelog 에 "착수했다"는 뜻으로 ID를 적는 습관이 있으면 오탐한다.
  CL="${CHANGELOG_PATH:-.claude/workspace/changelog.md}"
  if [ -f "$CL" ]; then
    for id in $(awk '/^##[[:space:]]+v?[0-9]+\.[0-9]+\.[0-9]+/ {rel=1} rel' "$CL" \
                | grep -oE 'BACKLOG-[0-9]+' | sort -u); do
      st=$(backlog_status "$id")
      [ -n "$st" ] && ! backlog_done "$st" \
        && warn "BACKLOG 스테일: $CL 의 릴리즈된 구간이 ${id} 를 언급하는데 $TODO 표의 상태는 '${st}' — 닫고 근거를 남기세요"
    done
  fi
```

- [ ] **Step 4: 테스트가 통과하는지 확인한다**

```bash
bash scripts/test-check-docs.sh
```
기대: `✓ §7-A 릴리즈된 구간 언급 ↔ 표 미완료 검출` · `✓ §7-A [Unreleased] 언급은 무시`

- [ ] **Step 5: 커밋**

```bash
git add scripts/check-docs.sh scripts/test-check-docs.sh
git commit -m "feat: check-docs §7-A — changelog 릴리즈 구간 ↔ BACKLOG 표 상태 검사"
```

---

## Task 3: 신호 C — BACKLOG 댕글링 참조 (+ `REF_DOCS` 호이스팅)

**파일**
- 수정: `scripts/check-docs.sh` (§4의 `REF_DOCS` 구성을 §4 위로 빼고, §7에서 재사용)
- 테스트: `scripts/test-check-docs.sh`

**왜 호이스팅하나**: 현재 `REF_DOCS`는 §4의 `if [ -f "$DECLOG" ]` 블록 **안**에서 만들어진다.
decision-log가 없는 프로젝트에서는 §7-C가 빈 목록을 보게 되므로, 목록 구성만 밖으로 뺀다.
§4의 판정 로직은 건드리지 않는다.

- [ ] **Step 1: 실패하는 테스트를 먼저 쓴다**

```bash
# 표에서 사라진 항목을 문서가 계속 참조하는 경우(§4 DEC 댕글링과 같은 실패 모드).
P="$T/backlog-c"; new_project "$P"
cat > "$P/.claude/workspace/todo.md" <<'EOF'
# TODO
## 백로그 (BACKLOG)
| ID | 제목 | 상태 | 근거 |
|----|------|------|------|
| BACKLOG-001 | 남아 있는 항목 | ⏳ 대기 | |
EOF
printf '%s\n' '# 명령어' '- 이 절차는 BACKLOG-009 에서 정했다.' > "$P/.claude/rules/commands.md"
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -q 'BACKLOG-009' \
  && pass "§7-C 댕글링 BACKLOG 참조 검출" || fail "§7-C 댕글링 참조를 놓침"

# 규약 설명(백틱)과 형식 예시(코드펜스)는 참조가 아니다 — §4와 동일한 제외 규칙.
P="$T/backlog-c-example"; new_project "$P"
cat > "$P/.claude/workspace/todo.md" <<'EOF'
# TODO
## 백로그 (BACKLOG)
| ID | 제목 | 상태 | 근거 |
|----|------|------|------|
| BACKLOG-001 | 남아 있는 항목 | ⏳ 대기 | |
EOF
cat > "$P/.claude/rules/planning.md" <<'EOF'
# 계획
머리말에 `BACKLOG-007` 처럼 상호 참조를 적는다.
```
related: [BACKLOG-042, DEC-001]
```
EOF
OUT="$(cd "$P" && bash scripts/check-docs.sh 2>&1)"
echo "$OUT" | grep -qE 'BACKLOG-007|BACKLOG-042' \
  && fail "백틱·코드펜스 안 BACKLOG 표기를 오탐" || pass "§7-C 백틱·펜스 제외"
```

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

```bash
bash scripts/test-check-docs.sh
```
기대: `✗ §7-C 댕글링 참조를 놓침`

- [ ] **Step 3: `REF_DOCS` 를 호이스팅한다**

`scripts/check-docs.sh`의 §4 블록에서 아래 부분을 **잘라내어**, §4 주석 블록 **위**(§3 뒤)로 옮긴다.
옮긴 뒤 §4는 `if [ -f "$DECLOG" ]; then` 안에서 `for f in $REF_DOCS` 루프만 남는다.

```bash
# ── 참조 검사용 문서 집합 (§4 DEC · §7 BACKLOG 공용) ──────────────────────
# 작업 단위 산출물(docs/superpowers/)은 제외한다 — 템플릿(_TEMPLATE-*)의 플레이스홀더를
# 걸러낼 새 규칙이 필요해지는데, 그 비용이 얻는 것보다 크다(DEC-015).
REF_DOCS=""
for f in .claude/CLAUDE.md CLAUDE.md README.md docs/user-guide.md docs/how-it-works.md \
         .claude/docs/*.md .claude/workspace/*.md .claude/rules/*.md; do
  [ -f "$f" ] && REF_DOCS="$REF_DOCS $f"
done
```

- [ ] **Step 4: 신호 C를 구현한다**

Task 2가 추가한 A 블록 **아래**(같은 `if [ -f "$TODO" ] …` 블록 안)에 추가:

```bash
  # (C) 표에서 사라진 항목을 문서가 계속 참조 — §4 DEC 댕글링과 같은 실패 모드다.
  # 제외 규칙도 §4와 동일하다: 코드펜스(형식 예시)와 백틱(규약 설명)은 실제 참조가 아니다.
  DEFINED=$(backlog_ids)
  for f in $REF_DOCS; do
    for id in $(strip_fences "$f" | strip_inline_code | grep -oE 'BACKLOG-[0-9]+' | sort -u); do
      printf '%s\n' "$DEFINED" | grep -qx "$id" \
        || warn "댕글링 참조: $f 가 참조한 ${id} 이 $TODO 표에 정의돼 있지 않음"
    done
  done
```

- [ ] **Step 5: 테스트가 통과하는지 확인한다**

```bash
bash scripts/test-check-docs.sh && bash scripts/test-new-dec.sh
```
기대: 전부 `✓`, 종료코드 0. `test-new-dec.sh`는 무관하지만 호이스팅이 다른 검사를 깨지
않았는지 함께 본다.

- [ ] **Step 6: 스캐폴드 자신에 대해 돌려본다**

```bash
bash scripts/check-docs.sh
```
기대: `✅ check-docs: 문제 없음`.
현재 `todo.md`의 BACKLOG-001·002는 표와 체크박스·changelog가 이미 일치하므로 경고가 없어야
한다. 경고가 나오면 그건 §7이 아니라 **문서가 실제로 어긋난 것**이니, 고치고 근거를 남긴다.

- [ ] **Step 7: 커밋**

```bash
git add scripts/check-docs.sh scripts/test-check-docs.sh
git commit -m "feat: check-docs §7-C — BACKLOG 댕글링 참조 검사 + REF_DOCS 공용화"
```

---

## Task 4: 룰 변경 — `readme-sync.md`

**파일**
- 수정: `.claude/rules/readme-sync.md`

자동 테스트가 성립하지 않는 문서 변경이다(→ `validation.md` 예외 규칙). 검증은 §7 초록불과
아래 수동 확인이다.

- [ ] **Step 1: 갱신 묶음 목록을 8항목으로 고친다**

`## 완료 시 자동 갱신 묶음 (한 번에)` 절의 코드블록을 통째로 교체:

```
1. .claude/docs/01-impl-requirements.md — 구현 현황 요약 표 (✅/⚠️/❌)
2. .claude/workspace/todo.md            — 진행/완료 이동 + 날짜
3. .claude/workspace/todo.md            — 관련 BACKLOG 행의 상태·근거 (해당 항목이 있을 때)
4. .claude/workspace/changelog.md       — 상세 이력 추가
5. README.md                            — Features/Changelog/Config (사용자 영향 시)
6. docs/user-guide.md                   — 실제 동작 근거로 갱신
7. .claude/docs/02-architecture.md      — 구조(정적)가 바뀐 경우만
8. docs/how-it-works.md                 — 큰 기능의 동작 흐름(동적)이 바뀐 경우만
```

바로 아래 인용문의 `> 6·7은 조건부다.` 를 `> 7·8은 조건부다.` 로 고친다.

- [ ] **Step 2: 목록 아래에 절 두 개를 추가한다**

조건부 안내 인용문 다음, `## 릴리즈 절차` 앞에 삽입:

```markdown
### 3번이 왜 2번과 따로 있나

같은 파일이지만 **다른 표**다. 2번은 태스크 목록, 3번은 **BACKLOG 표**다. 예전 목록은
`todo.md`를 "진행/완료 이동"이라고만 적어 BACKLOG 표는 대상이 아닌 것처럼 읽혔고, 실제로
파생 프로젝트에서 **구현·릴리스까지 끝난 항목이 `진행중`으로 남아 있었다**. 갱신할 것이
없으면 넘어가되, 확인은 한다. 합치지 않는 이유는 체크리스트가 줄 단위로 소비되기 때문이다 —
절 안의 종속절은 건너뛰기 쉽다.

BACKLOG 행을 닫을 때는 **무엇을 근거로 닫았는지 한 줄**을 `근거` 열에 남긴다 — spec/plan
파일명·커밋 해시·확인 방법 중 무엇이든 좋다. "완료"만 적힌 행은 다음 사람이 다시 확인해야 한다.

표 형식:

| ID | 제목 | 상태 | 근거 |
|----|------|------|------|
| BACKLOG-002 | 버전·changelog 정합성 harness | ✅ 완료(2026-07-27) | `2026-07-27-version-release-harness-design.md` |

> 이 항목은 `check-docs.sh` §7이 기계적으로 확인한다 — changelog의 릴리즈된 구간이나 완료
> 체크박스가 언급한 항목인데 표가 미완료면 경고한다. 룰은 의도를 적고, 검사는 결과를 본다.

### 이 체크리스트로 막을 수 없는 것

**다른 작업의 부수 효과로 해소되는 항목**은 완료 시점 체크리스트로 잡히지 않는다. 고친
쪽에는 그 BACKLOG를 알 이유가 없기 때문이다. 같은 이유로, 항목을 쓸 당시의 관측이 그대로
굳는 경우도 있다(증상이 바뀌었는데 설명은 예전 그대로인 항목).

그래서 **주기적으로 BACKLOG를 코드에 대고 전수조사**한다 — 문서를 다시 읽는 게 아니라
실행하거나 소스를 확인하는 방식으로. 유효하다고 확인한 항목에도 **근거를 적어 두면** 다음
조사에서 같은 확인을 반복하지 않는다.
```

- [ ] **Step 3: 수동 확인**

```bash
grep -n "7·8은 조건부\|BACKLOG 행의 상태·근거" .claude/rules/readme-sync.md
grep -rn "6·7은 조건부" .claude/ docs/ README.md
```
기대: 첫 명령은 2줄 이상 출력, 두 번째 명령은 **출력 없음**(옛 문구 잔존 0).

- [ ] **Step 4: 커밋**

```bash
git add .claude/rules/readme-sync.md
git commit -m "docs: 갱신 묶음에 BACKLOG 표 항목 추가(7→8) + 근거 열 규약"
```

---

## Task 5: 스캐폴드 자기 문서 반영 + 최종 검증

**파일**
- 수정: `.claude/workspace/todo.md`, `.claude/rules/commands.md`, `README.md`,
  `.claude/workspace/changelog.md`

- [ ] **Step 1: `todo.md` 상단 날짜를 갱신한다**

표 스키마 이관(`spec/plan` → `근거`)과 BACKLOG-003 등록은 **계획 시점에 이미 수행됐다**
(진행 중 항목 + 표 3행). 여기서는 상단 `_최종 업데이트:_` 를 `2026-08-05`로만 고친다.

> 완료 처리는 이 태스크 Step 5에서 한다 — 그때 `- [x]` 로 바꾸고 표도 `✅ 완료(2026-08-05)`
> 로 닫는다. 둘 중 하나만 하면 방금 만든 §7-B가 스스로를 잡는다(그게 정상 동작이다).

- [ ] **Step 2: `commands.md`의 검사 설명에 §7을 추가한다**

`bash scripts/check-docs.sh` 줄의 설명을 교체:

```
bash scripts/check-docs.sh          # 플레이스홀더·REQ/FR·DEC 번호/댕글링·changelog 스테일·버전 3자 일치·BACKLOG 상태 (경고만, exit 0)
```

- [ ] **Step 3: `README.md`·`project-init.md`의 검사 설명에 §7을 반영한다**

`README.md:133` (디렉토리 트리 주석) — 아래로 교체:

```
│   ├── check-docs.sh               ← 문서 정합성 검사(플레이스홀더·REQ/FR·DEC·changelog·버전·BACKLOG)
```

`README.md:177` (`workspace/todo.md` semantics) — 아래로 교체:

```
| `workspace/todo.md` | ④ 실시간 현황판(🔄 진행/✅ 완료/⏳ 대기/🚧 블로커) + BACKLOG 표(상태·근거, check-docs §7이 검사) |
```

`.claude/rules/project-init.md`의 디렉토리 구조 블록에도 같은 트리 주석이 있다. 동일하게 교체:

```
│   ├── check-docs.sh                ← 문서 정합성 검사(플레이스홀더·참조·DEC·changelog·버전·BACKLOG)
```

새 섹션을 만들지 않는다. README:470의 Changelog 항목은 v0.1.0 시점 기록이므로 건드리지 않는다.

- [ ] **Step 4: `changelog.md` `[Unreleased]`에 기록한다**

`## [Unreleased]` 아래에 `### 2026-08-05` 블록을 추가(기존 `### 2026-07-27` 위):

```markdown
### 2026-08-05
- **feat**: `check-docs` §7 BACKLOG 상태 정합성 검사 신설 — (A) changelog 릴리즈 구간 언급
  ↔ 표 미완료, (B) `- [x]` 완료 체크박스 ↔ 표 미완료, (C) 표에 없는 BACKLOG 댕글링 참조.
  BACKLOG 표 행이 0개면 스킵. 파생 프로젝트에서 구현·릴리즈까지 끝난 항목이 `진행중`으로
  남아 있던 사고가 발단. 관련 DEC-015 / BACKLOG-003
- **docs**: `readme-sync` 갱신 묶음 7→8항목 — BACKLOG 행 갱신을 별도 줄로 승격(2번과 합치지
  않는 이유는 체크리스트가 줄 단위로 소비되기 때문). BACKLOG 표를 4열 유지 + `spec/plan`
  → `근거` 로 의미 확장. 관련 DEC-015
- **test**: `test-check-docs.sh`에 §7 케이스 6건 추가(정탐 A·B·C 3건, 오탐 방지 3건 —
  표 없으면 스킵 / `[Unreleased]` 언급 무시 / 백틱·펜스 제외).
```

- [ ] **Step 5: 완료 처리 + 전체 검증**

`todo.md`의 진행 중 항목을 `## ✅ 완료`로 옮기고(`- [x] … — 완료: 2026-08-05`),
표의 BACKLOG-003 행을 `✅ 완료(2026-08-05)` + 근거를 spec 파일명으로 닫는다.

```bash
bash scripts/test-check-docs.sh
bash scripts/test-new-dec.sh
bash scripts/check-docs.sh --strict
```
기대: 세 명령 모두 종료코드 0, `✅ check-docs: 문제 없음`.

- [ ] **Step 6: 커밋**

```bash
git add .claude/workspace/todo.md .claude/workspace/changelog.md \
        .claude/rules/commands.md README.md
git commit -m "docs: BACKLOG-003 완료 반영 + §7 문서 동기화"
```

---

## 검증 계획

| 대상 | 방법 |
|------|------|
| §7 A·B·C 정탐 | `test-check-docs.sh` 정탐 3케이스 |
| §7 오탐 | `test-check-docs.sh` 오탐 방지 3케이스(표 없음 스킵 / `[Unreleased]` / 백틱·펜스) |
| 기존 검사 회귀 | `test-check-docs.sh` 전체 + `test-new-dec.sh`(REF_DOCS 호이스팅 영향) |
| 실사용 | 스캐폴드 자신에 `check-docs.sh --strict` — 초록불 |
| 룰 문서 | `grep`으로 옛 문구("6·7은 조건부") 잔존 0 확인 |

## 완료 시 갱신 묶음

- [ ] 자동 갱신 묶음 수행(목록 정본: `.claude/rules/readme-sync.md` — 이번 변경 후의 **8항목** 기준)
- [ ] `scripts/check-docs.sh --strict` 통과
- [ ] 의존성 변경 없음 — DEC/Prerequisites 갱신 불필요

## 범위 밖 (명시적 제외)

- 파생 프로젝트로 변경을 내려보내는 **전파 절차** — 스캐폴드에 존재하지 않음이 확인됐으나
  별도 사이클(spec 리스크 절 참조).
- `/audit-backlog` 명령 신설 — YAGNI(DEC-015 기각 사유).
- **버전 릴리즈** — 이번 사이클에서 `/release`를 돌리지 않는다. `[Unreleased]`에만 쌓는다.

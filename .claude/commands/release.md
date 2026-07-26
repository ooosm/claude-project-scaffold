---
description: 릴리즈를 끊는다 — 버전 bump + changelog 마감 + README 요약 이관
argument-hint: <major|minor|patch|X.Y.Z>
allowed-tools: Bash(bash scripts/new-release.sh:*), Bash(bash scripts/check-docs.sh:*), Read, Edit
---

릴리즈를 끊는다. 대상: **$ARGUMENTS**

1. **먼저 changelog 를 최신화한다.** `.claude/workspace/changelog.md` 의 `[Unreleased]` 가
   이번 릴리즈에 들어갈 변경을 **실제 구현 근거로** 담고 있는지 확인한다(추측 금지 —
   커밋·코드를 확인한 뒤 쓴다). 비어 있거나 뒤처져 있으면 여기서 먼저 채운다.

2. `bash scripts/new-release.sh "$ARGUMENTS"` 를 실행한다.
   → 버전 SoT bump(쓰기 후 재검증) + `[Unreleased]` 마감 + 새 `[Unreleased]` 생성
   + README Changelog 골격 삽입. **git 부작용은 없다**(커밋·태그 미실행).

3. **README Changelog 의 골격을 채운다.** 삽입된 항목은 플레이스홀더이므로,
   `changelog.md` 에서 **사용자에게 의미 있는 항목만** 골라 요약으로 옮긴다.
   내부 리팩토링·테스트 추가는 옮기지 않는다(규칙: `.claude/rules/readme-sync.md`).

4. **납품물 일치 확인.** `docs/user-guide.md` · `docs/how-it-works.md` · README 가 릴리즈
   시점의 실제 동작과 일치하는지 확인한다(있는 프로젝트 기준).

5. `bash scripts/check-docs.sh` 로 검증한다. 플레이스홀더가 남아 있으면 §1 이,
   버전 3자가 어긋나면 §6 이 잡는다.

6. 커밋·태그는 **사용자에게 확인받고** 실행한다(`.claude/rules/git-workflow.md`).
   스크립트가 출력한 명령어를 그대로 쓴다:
   `git commit -am "chore: release vX.Y.Z"` → `git tag vX.Y.Z`

> 버전 정책을 바꾸려면 `.claude/rules/commands.md` 의 `## 버전 정책` 을 수정한다
> (`semver` 기본 / `calver` 는 명시 버전 필요 / `none` 은 릴리즈를 끊지 않음).

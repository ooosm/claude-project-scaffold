# 작업 계획 (Planning)

## 기본 원칙

**"먼저 생각하고, 나중에 코딩한다 (Think first, code later)."**
코딩을 시작하기 전에 반드시 계획을 먼저 수립하고 확인을 받는다.

## 워크플로 게이트 (매 작업 동일 흐름)

1. **brainstorming** → `docs/superpowers/specs/YYYY-MM-DD-*-design.md` 작성
   - UI가 포함되면 **목업 게이트** 통과(→ `ui-mockups.md`).
2. **writing-plans** → `docs/superpowers/plans/YYYY-MM-DD-*.md` 작성, `todo.md`에 태스크 등록.
3. 구현 중 **결정 발생 시 즉시 DEC 로깅**(→ `decisions.md`).
4. 구현 → 태스크별 리뷰 → 최종 리뷰.
5. 완료 시 **자동 갱신 묶음**: 구현현황표 + todo + changelog + README + 사용자 가이드.
6. 의존성 변경 시 **호환 버전 + 근거**를 DEC와 README Prerequisites에 기록.

## 요구사항 파악 (구현 전 확인)

- 목표가 무엇인지 (What)
- 왜 필요한지 (Why) — 맥락
- 완료 조건이 무엇인지 (Done criteria)
- 영향 범위(어떤 파일/모듈)

불명확한 부분은 구현 전에 질문한다.

## spec/plan 머리말 규칙

각 spec·plan 문서 상단에 관련 ID를 상호 참조로 명시한다.

```markdown
---
related: [BACKLOG-007, REQ-1-10, FR-09, DEC-012]
status: draft | in-progress | done
date: YYYY-MM-DD
---
```

## 단계별 진행

- 한 번에 모든 것을 바꾸지 않는다.
- 각 단계 종료마다 빌드/테스트를 확인하고 git 체크포인트(commit)를 만든다.
- 단계 완료마다 `workspace/todo.md`를 갱신한다.

## 승인

큰 변경(3개 파일 이상 수정, 새 기능, 리팩토링)은 spec/plan을 사용자에게 보여주고
**승인을 받은 뒤** 구현을 시작한다. 승인 없이 대규모 변경을 진행하지 않는다.

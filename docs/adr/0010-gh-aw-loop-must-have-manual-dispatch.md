# ADR-0010: gh-aw をループ定義の必達(must-have)に。完全自動化は stretch

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
今回の主役は「Loop を回す」こと。ただし当日実質 5h で完全自動（schedule / automations による無人心拍）まで
到達できるかは不確実。確実に出せる必達ラインを定義したい。

## Decision
**GitHub Agentic Workflows (gh-aw) を must-have** とし、`triage.md` / `migrate.md` / `verify.md` を定義する。
当日の必達は「**1 本の COBOL を、手動 dispatch でも GitHub 上で 1 周**」させること:
`Issue → Analyze → Code-to-Doc → Golden Master → Plan → Rewrite/Fallback → Verify → PR → CI → ADR → Next Issue`。

以下は **stretch**: schedule 自動心拍 / Copilot automations / Azure MCP の自律ループ内利用 /
`githubnext/goal`・`autoloop` / 複数プログラム対応 / Azure 診断の自動化。

gh-aw は公式デフォルトに従い **`.github/workflows/`** に置く（`.md` ソース ＋ 生成 `.lock.yml`）。

## Consequences
- **良い点**: 必達ラインが現実的。成果物（gh-aw / agents / skills / ADR）自体が「ループ設計」の証拠になり、
  完全自動で回らなくても物語が成立。
- **悪い点 / トレードオフ**: 手動 dispatch だと「無人の心拍」は当日デモできない（設計で示す）。gh-aw 実行には
  リポジトリシークレット `COPILOT_GITHUB_TOKEN`（fine-grained PAT, Copilot Requests: Read）が必要。
- **中立**: gh-aw は public preview のため仕様変動あり（`gh aw upgrade/update` で追従）。

## References
- docs/plan.md §4 / .github/workflows/

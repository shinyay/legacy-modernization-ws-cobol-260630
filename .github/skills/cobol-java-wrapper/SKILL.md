---
name: cobol-java-wrapper
description: 'fallback 移行：Java の `ProcessBuilder` で COBOL バイナリを起動し、stdin/一時ファイル↔stdout/ファイルを配線して golden 一致を満たす（Strategy B の代替路, ADR-0004/0008）。USE FOR: rewrite-to-Java が非現実的な本を Java ランタイムに載せるとき。DO NOT USE FOR: rewrite が可能な本（spec-to-java を使う）/ golden 検証（golden-master-testing）/ 本番に cobc を常用する前提に倒すこと（ADR-0013、fallback 時のみ）。'
compatibility: GitHub Copilot (VS Code), Copilot CLI
---

# cobol-java-wrapper（fallback：Java から COBOL を起動）

rewrite-to-Java が非現実的なときの**代替路**（ADR-0004 Strategy B / ADR-0008）。`cobc -x` で生成した COBOL バイナリを Java の `ProcessBuilder` で起動し、I/O を配線して**golden 一致**を満たす。まず `spec-to-java` で rewrite を試し、**不可と判断したときだけ**使う（理由は ADR に残す）。

## Skill Quality（6条件 / ADR-0014）

- **ground truth**: `tests/<prog>/golden/`（rewrite と同じ正）。wrapper でも振る舞いの正は golden。
- **gate**: candidate == golden（CI required check `golden-master equivalence (<prog>)`）。
- **artifact**: 本番=`app/` / サンプル・PoC=`samples/<prog>/java/` に Java wrapper。**`tests/<prog>/cmd` が起動する場所と一致**させる。
- **order**: Plan → Rewrite で「rewrite 不可」と判断した後の fallback 位置。
- **completion criteria**: golden 一致 green。green でなければ未完了。
- **escape-hatch control**: golden を緩めない。fallback を安易に選ばない（rewrite を先に試す）。本番イメージへ `cobc`/バイナリを載せる判断は **ADR-0013 を更新してから**。

## 配線の要点

- **起動**: `new ProcessBuilder(binPath)`。終了コードを確認し、非0は失敗として扱う。`redirectErrorStream` は必要時のみ。
- **入力**: COBOL が `ACCEPT`（stdin）なら子プロセスの stdin に書く。固定長 FILE I/O なら一時ファイルを作って渡す。
- **出力**: `DISPLAY`（stdout）を読み取り candidate 出力にする。FILE 出力なら一時ファイルを読む。
- **バイナリ**: `cobc -x` のビルド成果（CI/コンテナ、ADR-0013）。本番は多段ビルド（build=cobc / runtime=JRE＋bin）。
- **正規化の範囲内に収める**: 文字コード・改行・固定長パディングは golden の正規化（末尾空白 strip）で吸収できる形にする。

## 手順

1. **rewrite 不可の理由を明確化**（複雑な FILE I/O・方言依存・移行リスク等）→ ADR に記録（`adr-authoring`）。
2. COBOL を `cobc -x` でビルド（CI/コンテナ、ADR-0013）。バイナリの配置を決める。
3. Java wrapper で `ProcessBuilder` 起動、stdin/stdout（必要なら一時ファイル）を配線。
4. `tests/<prog>/cmd` を wrapper の起動コマンドに合わせる（verify/CI がこれを実行する）。
5. `golden-master-testing` で検証 → 不一致は wrapper / 配線を直す（**golden は触らない**）。

## 関連

- 関連 ADR: 0004（Strategy B）/ 0008（rewrite 優先・不可なら wrapper）/ 0011（配置）/ 0013（本番 Java・cobc は原則ビルド専用）。
- 前提知識: `cobol-gnucobol-dialect`（ビルド）。検証: `golden-master-testing`。優先路: `spec-to-java`（rewrite）。

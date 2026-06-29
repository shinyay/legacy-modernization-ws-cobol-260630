# Codebase-Memory: Tree-Sitter-Based Knowledge Graphs for LLM Code Exploration via MCP

> 本プロジェクトの **spec-extract（ADR-0019）** の着想元となった論文の要約ノート。
> 逐語転載ではなく要点の要約＋数値データ（表）の引用。原典を正とする。

## 書誌
- **著者**: Martin Vogel, Falk Meyer-Eschenbach, Severin Kohler, Elias Grünewald, Felix Balzer
- **arXiv**: 2603.27277v1 [cs.SE]（2026-03-28）
- **コード**: https://github.com/DeusData/codebase-memory-mcp （MIT・評価版 v0.5.5）
- **位置づけ（当リポジトリ）**: Code→Doc（ADR-0009）の構造抽出を tree-sitter で機械化する方針の背景文献。

## TL;DR
LLM コーディングエージェントは grep とファイル読みでコードを探索し、構造理解のないまま大量のトークンを消費する。Codebase-Memory は **tree-sitter で 66 言語をパース**し、コードの構造を**ナレッジグラフ（SQLite）化**して **MCP の 14 ツール**で LLM に公開する。31 言語のベンチで、ファイル探索エージェントの品質 90%（0.83 vs 0.92）を、**トークン 1/10・ツール呼び出し 2.1 分の 1**で達成した。

## 背景・課題
- LLM は非構造テキストを扱うが、開発者の問い（コールグラフ・依存連鎖・モジュール境界・影響分析）は本質的に**構造的**。
- テキスト検索は推移的関係を辿るたびにトークンを消費し、"lost in the middle" のリスクを増やす。
- 既存の構造解析（Code Property Graph・CodeQL）は重厚（専用 DB・専用クエリ言語）で、LLM 消費向けに最適化されていない。

## 提案アーキテクチャ（3 ステージ）
1. **Parse**: tree-sitter AST を 66 言語で走査し、定義（関数/メソッド/クラス/インタフェース/列挙/型）・呼び出し・import・参照を抽出。Go/C/C++ は LSP 風の型解決を併用して call-graph 精度を上げる。
2. **Build**: pthreads 並列ワーカープールの多段パイプラインで nodes/edges を SQLite に格納。Louvain modularity でコミュニティ検出。
3. **Serve**: MCP サーバが 14 ツール（`search_graph` / `trace_call_path` / `query_graph` / `get_architecture` ほか）を公開。サブミリ秒クエリ。
- 単一の静的リンク C バイナリ・ランタイム依存ゼロ。**66 の tree-sitter grammar を C ソースとして vendoring** してコンパイル。
- XXH3 コンテンツハッシュでファイル監視 →差分のみインクリメンタル再索引。

## 主要結果（表6: MCP Agent vs Explorer Agent / バックエンド Claude Opus 4.6）
| 指標 | MCP | Explorer | 差 |
|---|---|---|---|
| 品質スコア | 0.83 | 0.92 | Explorer の 90% |
| ツール呼び出し / 問 | 2.3 | 4.8 | 2.1 倍少 |
| トークン / 問 | ~1,000 | ~10,000 | 10 倍少 |
| クエリ遅延 | <1 ms | 10–30 s | >100 倍速 |

- ハブ検出・呼び出し元ランキングは 31 言語中 **19 言語で MCP 優位**（事前計算したグラフ辺が効く）。
- Explorer は全文脈取得（16/31）と網羅 grep（10/31）で優位＝**行レベルのソース**はグラフが意図的に持たないため。
- 最弱は**マクロ多用の C（0.58 vs 1.00）**＝マクロが AST に現れないため。
- 性能: 49K ノードの索引 ~6s、Linux kernel（2.1M ノード）~3 分。

## 我々のプロジェクト（loopengineering）への示唆
- **構造を LLM に渡す有効性** = spec-extract（ADR-0019）の理論的裏付け。tree-sitter で COBOL 構造を抽出し Code→Doc（ADR-0009）を補助する方針と一致。
- **grammar の vendoring** = 本論文も 66 grammar を vendoring（自己完結・再現性）。当方の `tools/spec-extract/vendor/` 凍結 vendoring と同じ思想（ADR-0019）。
- **マクロ問題の同型** = C のマクロ未表現（0.58）は、COBOL の `COPY`/`REPLACE`・画面制御・`EXEC SQL` が AST に乗らない問題と同型。**前処理（COPY 展開等）か golden 主体**が要る根拠。
- **依存解析への発展** = `trace_call_path` / `get_architecture` は、当方の `tools/deps`（CALL/COPY からプログラム間依存グラフ）構想の参考になる。
- **限界の自覚** = グラフは**静的構造のみ**（実行時挙動・動的ディスパッチ非対応）。「振る舞いの正は cobc golden（ADR-0005）、構造抽出は補助」という役割分担を補強する。
- **ハイブリッドが最適**（論文 5.1）= 構造クエリはグラフ、ソースレベルはファイル探索にフォールバック。当方の「tree-sitter＝補助／golden＝正」と整合。

## 関連
- ADR-0019（tree-sitter で COBOL 構造抽出・grammar 凍結 vendoring）/ ADR-0009（Code→Doc→Code）/ ADR-0005（golden master）
- tree-sitter: Max Brunsfeld, 2018（Strange Loop）/ Aider の RepoMap（Tree-Sitter＋PageRank）
- ツール実体: [`tools/spec-extract/`](../../tools/spec-extract/extract.sh)

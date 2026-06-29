# tools/golden/ — golden master ランナー

レガシー COBOL の振る舞いを「正」として固定し、移行候補がそれに一致するかを検証する。

- **freeze**: `legacy/` の COBOL を `cobc -x` でビルド＆実行し、`tests/<prog>/inputs/*` ごとの出力を
  `tests/<prog>/golden/` に**固定**（一度だけ「直接実行 == API 経由」の透過性も確認）。
- **verify**: 候補（**rewrite 版 Java** or **wrapper 版**）を同じ入力で実行し、golden と **正規化 diff**。
  正規化: 固定長パディング / 改行 / 数値書式 / 日付など非決定性のマスク。

CI（`.github/workflows/ci.yml`）から呼ばれ、不一致なら merge をブロックする（= ループの停止条件）。

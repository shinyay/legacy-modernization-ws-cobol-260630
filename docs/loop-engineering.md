# Loop Engineering 概念整理 — OpenCOBOL マイグレーション向け

> 出典: Addy Osmani, "Loop Engineering" (2026-06-07)
> https://addyosmani.com/blog/loop-engineering/
>
> 本ドキュメントは記事の内容を自分たちの文脈（COBOL マイグレーションのハッカソン）
> に合わせて整理・再構成したもの。引用ではなく要約。

---

## 1. 一言でいうと

**自分が agent にプロンプトするのをやめ、「agent にプロンプトし続ける仕組み（ループ）」を設計する**こと。

- これまで（〜2年間）: 良いプロンプト＋十分なコンテキストを書く → 返答を読む → 次を書く。
  agent は道具で、ずっと自分が手で握っている。1ターンずつ。
- これから（Loop Engineering）: 仕事を「見つけ → 割り振り → 検査し → 記録し → 次を決める」
  小さなシステムを作り、それを走らせる。自分の代わりにループが agent をつつく。

> "You shouldn't be prompting coding agents anymore. You should be designing loops
> that prompt your agents." — Peter Steinberger
>
> "I don't prompt Claude anymore. I have loops running that prompt Claude... My job
> is to write loops." — Boris Cherny (Claude Code)

レバレッジの効きどころが「プロンプト」から「ループ設計」へ移った、という話。
（＝ harness engineering の一つ上の階層。harness をタイマーで回し、子 agent を生み、自分で自分に餌をやる）

---

## 2. ループの構成要素（5 + 1）

| # | 要素 | 役割 | Claude Code | Codex |
|---|------|------|-------------|-------|
| 1 | **Automations（心拍）** | スケジュールで発見＋トリアージを自走 | `/loop`, cron, hooks, GitHub Actions | Automations タブ, `/goal` |
| 2 | **Worktrees** | 並列 agent がファイル衝突しない隔離 | `git worktree`, `--worktree`, `isolation: worktree` | スレッドごとに内蔵 worktree |
| 3 | **Skills** | プロジェクト知識を `SKILL.md` に明文化 | Agent Skills (`SKILL.md`) | Agent Skills (`$name` / `/skills`) |
| 4 | **Plugins / Connectors** | MCP で既存ツール（課題管理/DB/CI/Slack）に接続 | MCP servers + plugins | Connectors (MCP) + plugins |
| 5 | **Sub-agents** | 「作る人」と「検査する人」を分離 | `.claude/agents/`, agent teams | `.codex/agents/` (TOML) |
| +1 | **Memory / State** | 会話の外に「済/未」を持つ（ディスク上） | Markdown (`AGENTS.md`, progress files), Linear via MCP | Markdown / Linear via connector |

### 各要素のキモ

1. **Automations = ループを「一度きりの実行」でなく「本物のループ」にする心拍**。
   定期実行で仕事を見つけ、見つかったら Triage inbox へ、見つからなければ自動アーカイブ。
   - `/loop` … 一定間隔で再実行
   - `/goal` … **自分が書いた検証条件が真になるまで**走り続ける。各ターン後に
     **別の小さなモデルが「終わったか」を判定**（= 書いた本人に採点させない）
2. **Worktrees** … agent を2つ以上回した瞬間にファイル衝突が最大の故障要因になる。
   別ディレクトリ＋別ブランチで物理的に衝突を防ぐ。ただし**レビュー帯域は人間が天井**。
3. **Skills** … 毎セッション「金魚のように」プロジェクト説明を繰り返すのをやめる。
   規約・ビルド手順・「あの事故以来こうしない」を一度書けば毎回読まれる → 知識が複利で効く。
   説明は気の利いた文より**退屈で正確な記述**が勝つ（マッチ判定のため）。
4. **Connectors (MCP)** … ファイルシステムしか見えないループは小さい。課題管理・DB・staging API・
   Slack に触れて初めて「PR を開く／チケットを更新する」まで自走できる。
5. **Sub-agents** … 最重要は**作る人と検査する人を分けること**。書いたモデルは自分の宿題に甘い。
   別指示・別モデルの検証者が、最初の agent が自分を言いくるめた箇所を捕まえる。
   ループは自分が見ていない間に走るので、**信頼できる検証者だけが「離席」を許す**。
6. **Memory** … モデルは実行間で全部忘れる。だから記憶は context ではなく**ディスク**に置く。
   「agent は忘れる、repo は忘れない」。これがループの背骨。

---

## 3. OpenCOBOL マイグレーションへのマッピング

ハッカソンの題材（OpenCOBOL → モダン言語への移行）に各要素を当てはめると：

| 要素 | この案件での具体化 |
|------|--------------------|
| Automations | **Discovery（deps/hotspots→manifest更新）**を前段に実行し、次に移行する COBOL を triage するトリガー実行 |
| Worktrees | 独立したモジュールを複数 agent が並列移行（衝突なし） |
| Skills | COBOL 方言（GnuCOBOL/OpenCOBOL）の癖、`PIC` 句→型のマッピング、`COMP-3`(packed decimal)・固定長レコード・ファイル I/O の扱い、移行先言語の規約、「段落(paragraph)はこう写す」などを `SKILL.md` 化。**構造抽出**は `tools/spec-extract`（tree-sitter-cobol grammar + `.scm` クエリ）で機械的に COBOL データ定義・段落・組込み関数を列挙し、`cobol-to-spec` skill の初期骨子として活用する |
| Connectors | 元 COBOL ソース repo、テストランナー、DB、課題管理、CI に MCP で接続 |
| Sub-agents | **maker**: COBOL→移行先へ翻訳 / **checker**: 振る舞い等価性を検証（両方を実行し出力を比較、特性化テストに通す） |
| Memory/State | 移行トラッカー Markdown（プログラム単位で：状態 / テスト pass / 既知のエッジケース / 未対応） |

### この案件で一番効くのは「検証（振る舞い等価性）」

COBOL 移行の成否は **“元と同じ振る舞いをするか”** に尽きる。ここが `/goal` の停止条件になる。

- **特性化テスト（golden master）**: 元の OpenCOBOL プログラムの入出力を取得して正解として固定し、
  移行版がそれに一致するかを自動判定 → これが checker サブ agent の背骨。
- 要注意ポイント: 10進演算の精度（`COMP-3`/packed decimal）、EBCDIC vs ASCII、
  固定長レコード、丸め・ゼロ埋め、暗黙の型変換。

---

## 4. 落とし穴（ループが良くなるほど鋭くなる3つ）

1. **検証は依然として自分の仕事** … 無人で走るループ＝無人でミスもするループ。
   "done" は主張であって証明ではない。出荷するのは「自分が動作確認したコード」。
2. **理解が腐る（comprehension debt）** … 自分が書いていないコードが速く出るほど、
   「存在するもの」と「自分が把握しているもの」の差が広がる。ループが滑らかなほど速く広がる。
3. **認知の放棄（cognitive surrender）** … 自走すると意見を持つのをやめて出力を丸呑みしたくなる。
   判断を持ってループを設計すれば良薬、考えないために設計すれば毒。同じ行為で逆の結果。

その他: **トークンコストは使い方で大きく振れる**。直接プロンプトも依然有効 → **バランスが本質**。

> 同じループを2人が作っても、深く理解している作業を速くするために使う人と、
> 理解を避けるために使う人で正反対の結果になる。ループは区別しない。あなたが区別する。

---

## 5. 進め方（ハッカソンに向けた段取り案）

> 原則: **「自動化を作り込む前に、手動で1サイクルを通す」**。1本のプログラムで
> maker→checker→検証 の往復が成立してから、それをループに encode する。

- **Step 0 — 前提を確定**
  - 移行先言語は？（Java / C# / Go / Python / TypeScript など）
  - 「移行済み」の合格基準は？（特性化テスト一致？ 単体テスト？ 目視レビュー？）
  - 使う agent ツールは？（Claude Code / Codex）／ハッカソンの時間と評価軸／ソース規模
- **Step 1 — 土台**: repo スケルトン＋ state ファイル（記憶）＋ COBOL→移行先規約の `SKILL.md`
- **Step 2 — 検証ハーネス**: OpenCOBOL の出力を golden master として取得する仕組み（= 検証者の背骨）
- **Step 3 — sub-agents 定義**: maker / checker（別モデル・別指示）
- **Step 4 — ループ配線**: 次プログラムを選ぶ → worktree で移行 → golden テストで検証 → state 更新
- **Step 5 — 実行・レビュー・反復**: 自分はレビュアーとして残る

### 最初の一歩（最小）
代表的な COBOL プログラムを**1本だけ**選び、maker→checker→検証 の1サイクルを**手で**通す。
うまくいったら、その手順をそのままループに落とす。

---

## 6. GitHub Copilot 版マッピング（GitHub の「ループ流儀」）

> 多くの解説は Claude Code / Codex 前提だが、GitHub Copilot にも 5+1 の部品が全部ある。
> ただし**思想が違う**。Claude は「ローカル（端末）でループを回す」。
> **GitHub は「プラットフォーム（GitHub.com）そのものをループにする」**——
> Issue が受信箱、PR が成果物、GitHub Actions が心拍、Copilot code review が検証者、
> branch protection が出荷ゲート。**SDLC 自体がループ**、というのが GitHub の賭け方。

### 5 + 1 の対応表（2026-06 時点）

| 部品 | Claude Code / Codex | GitHub Copilot の相当物 |
|------|---------------------|--------------------------|
| 1. Automations（心拍） | `/loop`, `/goal`, cron | **Copilot automations**（schedule / issue / PR をトリガに cloud agent を自動起動）＋**GitHub Agentic Workflows**（自然言語 Markdown → Actions YAML に compile, `gh-aw`）＋ Copilot CLI のプロンプトscheduling |
| 2. Worktrees（隔離） | `git worktree` | **Copilot cloud agent の各セッション = GitHub Actions 上の使い捨て環境＋専用ブランチ**で自然に隔離（1タスク=1ブランチ=1PR）。ローカルは VS Code の git worktree / 並列セッション |
| 3. Skills | `SKILL.md` | **Agent Skills（`SKILL.md`）**——同じ形式。cloud agent でも IDE でも有効 |
| 4. Connectors / Plugins | MCP, plugins | **MCP servers**（GitHub MCP・Playwright MCP は既定で有効）＋**agent plugins**（束ねて配布）＋ connectors（Jira/Slack ほか） |
| 5. Sub-agents（作る/検査） | `.claude/agents`, `.codex/agents` | **Custom agents**（`.github/agents/*.agent.md` / VS Code の `*.agent.md`）＋ VS Code の**subagents**＋検査役として**Copilot code review**（`AGENTS.md` 対応） |
| +1. Memory / State | markdown, Linear | **Copilot Memory**（public preview）＋ custom instructions（`copilot-instructions.md` / `AGENTS.md`）＋ Markdown state ファイル＋**GitHub Issues / Projects をボード**として |

### GitHub 固有の強み（Claude にない/弱いところ）
- **Issue → @copilot → PR** の流れがそのまま maker ループになる（cloud agent に issue をアサイン）。
- **Copilot code review が独立した検査役**（書いた本人に採点させない＝ maker/checker 分離が標準装備）。
- **セキュリティが platform 側で強制**: integrity filter / **Agent Workflow Firewall** / safe outputs /
  threat detection / branch protection / レビュー承認ゲート。無人ループでも暴走しにくい。
- **`/chronicle`** で複数 agent セッションを横断して状況把握。**Hooks** でライフサイクルにフック。
- **Agent tasks REST API / Copilot SDK** でループをコードから組める。

### 30日トライアルで使うときの注意（プラン/リポジトリ要件）
- **Copilot automations / cloud agent は有料プラン（Pro / Pro+ / Max / Business / Enterprise）必須**。
  automations は**private または internal リポジトリのみ**（public 不可）。
  → `NRI-Oxalis/loopengineering` が private/internal なら OK。
- cloud agent セッションは**1回最大 59 分**・**1タスク=1ブランチ=1PR**。大きい移行は**小さく分割**。
- プランが限定的なら、まず **VS Code 側（agent mode＋custom agents＋skills＋MCP＋subagents）**＋
  **GitHub Actions を手動 trigger** で回し、慣れてから automations/cloud agent に広げる。

---

## 7. GitHub ネイティブで COBOL 移行ループを組む

> 「端末で cron」ではなく「**GitHub の上で Issue→PR を回す**」形に置き換える。

1. **記憶 = Issues + Projects**: COBOL プログラム/モジュール 1本につき 1 Issue。
   Project ボードで `Todo / In progress / Verified / Done`。これがループの背骨（state）。
2. **心拍 = Copilot automation（or Agentic Workflow）**: まず discovery で `manifest.yaml` の hotspot/依存フィールドを更新し、
   その結果を使って triage が「次にやる1本」を選びラベル付け。
3. **maker = @copilot（cloud agent）**: その Issue をアサイン → 調査・計画・移行をブランチで実施 → PR。
4. **checker = Copilot code review ＋ CI**: PR で**特性化テスト（golden master）を CI 実行**——
   これが本当の停止条件。**branch protection で green まで merge 不可**。
5. **skills = `SKILL.md` ＋ `AGENTS.md`**: COBOL 方言（GnuCOBOL/OpenCOBOL）、`PIC`→型、
   `COMP-3`、固定長レコードの規約を明文化。
6. **connectors = MCP**: テストハーネス/DB に接続。GitHub MCP で Issue/PR を操作。
7. **あなた = エンジニアとして残る**: PR をレビューし、ゲートを守る。"done" は主張、merge は判断。

### GitHub 版の最初の一歩
代表 COBOL を 1本選び、(a) Issue 化 → (b) `@copilot` にアサインして PR を出させる →
(c) golden master テストを CI に置いて PR を green/red で判定、までを**手で1往復**。
成立したら (2) の automation を足して心拍を付ける。

---

## 8. 関連概念（Addy の他記事）
- agent harness engineering / factory model … ループの一つ下の階層
- long-running agents … 記憶をディスクに置く理由
- the orchestration tax … 並列化しても人間のレビュー帯域が天井
- intent debt / agent skills … Skills が「明文化した意図」である理由
- the code agent orchestra / adversarial code review … maker/checker 分離の根拠
- comprehension debt / cognitive surrender / code review in the age of AI … 落とし穴

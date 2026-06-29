; spec-extract: COBOL 構文木 → 業務仕様の骨子を抽出する tree-sitter クエリ
; 対象 grammar: tree-sitter-cobol (COBOL85 / 固定形式)
; 用途    : ADR-0009 Code→Doc の「構造抽出」を機械化し、specs/<prog>.md の裏付けにする
; 位置づけ: 真実の源は cobc golden (ADR-0005)。本抽出はあくまで補助（正しさの根拠ではない）。

; --- データ項目: レベル番号 / 項目名 / PIC ---
(data_description
  (level_number)   @data.level
  (entry_name)     @data.name
  (picture_clause) @data.pic)

; --- 段落 (PROCEDURE の処理単位) ---
(paragraph_header) @paragraph

; --- 手続き文 ---
(accept_statement)  @stmt.accept
(move_statement)    @stmt.move
(compute_statement) @stmt.compute
(display_statement) @stmt.display
(stop_statement)    @stmt.stop

; --- 組み込み関数の使用 (例: FUNCTION NUMVAL) ---
(function_ (WORD) @func.name)

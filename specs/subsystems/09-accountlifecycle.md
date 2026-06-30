# Subsystem Spec — 09-accountlifecycle

## Summary

口座の状態遷移（開設・休眠・再活性）を担うバッチ。休眠スキャンと再活性スキャンを実行する。

- 区分: batch
- 信頼度: inferred
- モダナイズ先: `container_apps_job`

## Business Role

口座のライフサイクル状態を管理し、休眠/再活性化を判定して状態変更と監査記録を行う。

## Entrypoint

- `alc-open`: 口座開設処理
- `alc-dormancy-scan`: 休眠スキャン
- `alc-reactivation-scan`: 再活性スキャン
- `alc-change-state`: 状態変更

## Inputs

- `accounts.idx`、カレンダー（01）コンテキスト

## Outputs

- 口座状態の変更

## Database Access

ソース上は SQL 未検出（ISAM ベース）。

## ISAM Files

- `ACCOUNT-FILE`

## Messaging

なし。

## Business Rules

- 休眠閾値に基づく休眠化。
- 再活性条件による状態復帰。
- 状態変更時の監査書き込み。

## Dependencies

- 観測 CALL: `AUD-WRITE`
- manifest 依存: 08, 01

## Tests / Evidence

- `subsystems/09-accountlifecycle/tests/unit/alc-test.cob`

## Modernization Notes

- スキャン系バッチのため `container_apps_job`。
- systemd の dormancy-scan timer に対応。

## Risks

- 休眠閾値計算・再活性トリガ条件は実例（fixture）で固定すべき。

## Open Questions

- 状態機械（許容遷移）の正準定義。


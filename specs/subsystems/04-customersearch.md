# Subsystem Spec — 04-customersearch

## Summary

複合条件による顧客検索を提供するオンライン系サブシステム。対話照会のための検索エンドポイント。

- 区分: online
- 信頼度: inferred
- モダナイズ先: `container_apps_service`

## Business Role

カナ・電話・住所・ページングを組み合わせた検索を提供し、照会（18）から利用される。

## Entrypoint

- `csrch-and`: AND 複合条件検索
- `csrch-by-address`: 住所検索
- `csrch-list-paged`: ページング付き一覧

## Inputs

- 検索条件（カナ / 電話 / 住所 / ページング）

## Outputs

- 検索結果セット

## Database Access

本サブシステム内の直接アクセスは限定的。顧客サブシステム（03）の API へ委譲。

## ISAM Files

直接の FD は持たず、03 経由で `customer.idx` を参照。

## Messaging

なし。

## Business Rules

- 複数条件の AND 合成。
- 住所部分一致検索。
- ページング（安定した並び順に依存）。

## Dependencies

- 観測 CALL: `CUST-LIST-ALL`, `CUST-LOOKUP`, `CUST-SEARCH-BY-KANA`, `CUST-SEARCH-BY-PHONE`
- manifest 依存: 03

## Tests / Evidence

- `subsystems/04-customersearch/tests/unit/csrch-test.cob`

## Modernization Notes

- 対話系のため `container_apps_service`。

## Risks

- ページングの安定性は元データの決定的順序に依存。

## Open Questions

- 住所一致の正規化規則（表記ゆれの扱い）。


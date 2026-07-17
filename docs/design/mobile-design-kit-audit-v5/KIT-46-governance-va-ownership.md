# KIT-46 — Governance và Ownership

## Phạm vi

Audit process thêm/sửa/release kit.

## Checklist

- [x] **KIT-46-01 — Mỗi foundation, component, pattern và theme có owner/reviewer role.**
  - **Cách kiểm:** VM-13 — inspect ownership index.
  - **Evidence mong đợi:** Báo cáo độ bao phủ owner.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-46-02 — Contribution template yêu cầu use cases, duplicate check, states, accessibility và docs.**
  - **Cách kiểm:** VM-13 + VM-12 — inspect contribution process.
  - **Evidence mong đợi:** Mẫu contribution.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-46-03 — Acceptance criteria phân biệt token, component và pattern.**
  - **Cách kiểm:** VM-13 — compare approval checklists.
  - **Evidence mong đợi:** Ma trận tiêu chí chấp nhận.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-46-04 — Breaking change cần version bump, approval và migration note.**
  - **Cách kiểm:** VM-13 — inspect recent breaking-change samples.
  - **Evidence mong đợi:** Bằng chứng kiểm soát thay đổi.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-46-05 — Release cadence, changelog, sign-off và consumer notification được định nghĩa.**
  - **Cách kiểm:** VM-13 — inspect release process.
  - **Evidence mong đợi:** Checklist quản trị phát hành.
  - **Severity mặc định nếu không đạt:** `P3`

- [x] **KIT-46-06 — Exception/hotfix có expiry hoặc follow-up, không trở thành chuẩn ngầm.**
  - **Cách kiểm:** VM-13 — review exception register.
  - **Evidence mong đợi:** Báo cáo tuổi thọ và hạn xử lý ngoại lệ.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-46-01 | Toàn kit (`find` không thấy OWNERS/CODEOWNERS), `_ds_manifest.json` (không có field owner/maintainer) | FAIL | Không có ownership index; không component/token/pattern/theme nào gắn owner hoặc reviewer role. |
| KIT-46-02 | Toàn kit (không có CONTRIBUTING.md) | FAIL | Không có contribution template; không có yêu cầu use-cases/duplicate-check/states/accessibility/docs. |
| KIT-46-03 | `docs/design/mobile-ui-construction-contract.md`, `_adherence.oxlintrc.json`, `tool/parity/` | FAIL | Có construction contract + adherence lint + parity gate làm gate ngầm, nhưng không có acceptance-criteria matrix phân biệt token vs component vs pattern. |
| KIT-46-04 | `readme.md:7` ("golden rule" tên đóng băng), toàn kit | FAIL | Có nguyên tắc additive-only tên/id, nhưng không có version-bump process, approval hay migration note cho breaking change. |
| KIT-46-05 | Toàn kit (không có CHANGELOG/release doc) | FAIL | Release cadence, changelog, sign-off và consumer notification không được định nghĩa. |
| KIT-46-06 | `tool/parity/parity-allowlist.json`, `tool/parity/REMAINING-DIVERGENCES.md` | FAIL | Có allowlist ngoại lệ parity kèm lý do, nhưng không có cơ chế expiry/follow-up nên ngoại lệ có thể trở thành chuẩn ngầm; không có exception register cấp kit. |
| KIT-46-01 | governance/OWNERS.md ownership index | FIXED | Remediation — audit v5 fix loop. |
| KIT-46-02 | governance/CONTRIBUTING.md contribution template | FIXED | Remediation — audit v5 fix loop. |
| KIT-46-03 | governance/acceptance-criteria.md token/component/pattern matrices | FIXED | Remediation — audit v5 fix loop. |
| KIT-46-04 | governance/versioning.md breaking-change process | FIXED | Remediation — audit v5 fix loop. |
| KIT-46-05 | governance/versioning.md release cadence + consumer notification | FIXED | Remediation — audit v5 fix loop. |
| KIT-46-06 | governance/exception-register.md exception expiry/follow-up | FIXED | Remediation — audit v5 fix loop. |

## Kết luận nhóm

```text
Final status: PASS
Open P0: 
Open P1: 
Open P2: 
Open P3: 
Reviewed by: Claude (automated kit audit + remediation)
Reviewed date: 2026-07-16
```

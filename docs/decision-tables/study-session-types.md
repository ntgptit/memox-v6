# ST-SESSION-TYPE-v1 — Study Session type

| ID | Given | When | Then |
| --- | --- | --- | --- |
| ST-TYPE-001 | Box 0 Cards đủ eligibility | Start `newLearning` | Snapshot mode plan đúng `Review → Match → Guess → Recall → Fill`; SRS activation enabled |
| ST-TYPE-002 | New-learning request thiếu/bỏ/reorder mode | Validate start | Block; không tự hạ thành Practice |
| ST-TYPE-003 | Practice scope hợp lệ và một mode được chọn | Start `practice` | Snapshot đúng một mode; `scheduleSrs=false`; không Goal/Streak contribution |
| ST-TYPE-004 | Practice chưa chọn mode | Start | Block và giữ selection surface |
| ST-TYPE-005 | Due queue Box 1..7 không rỗng | Start `dueReview` | Snapshot stable due order; terminal grades schedule enabled |
| ST-TYPE-006 | Due queue rỗng | Start `dueReview` | Không tạo empty session; show caught-up |
| ST-TYPE-007 | Finalized session có missed Card set | Start `relearn` | Snapshot missed set; không mutate source session |
| ST-TYPE-008 | Card khác trở thành due khi session active | Refresh | Không append active snapshot; để future Due Review |
| ST-TYPE-009 | Mode tile selected | User chưa bấm Start | Chỉ đổi selection; không tạo session |
| ST-TYPE-010 | Same start request retry/double-submit | Create | Trả cùng session identity, tối đa một active session |
| ST-TYPE-011 | Guess nằm trong mode plan | Validate | Candidate pool có ít nhất 5 distinct normalized meanings; nếu thiếu thì block |
| ST-TYPE-012 | New Learning hoàn tất đủ năm mode, writes committed | Finalize Card activation | Box 0→1 đúng một lần |

Acceptance: mỗi row có test; mọi persisted Session có `sessionType` và versioned mode plan; UI label không được dùng để suy session type.

---
status: approved
kind: resolution
drifts:
  - drift: ipxadqpo
    decision: fix-code
    option: 1
  - drift: bmheuxob
    decision: fix-code
    option: 2
  - drift: jh9we7ze
    decision: fix-code
    option: 1
  - drift: otwtv4pd
    decision: fix-code
    option: 1
  - drift: oos0timz
    decision: fix-code
    option: 3
  - drift: ykdaymen
    decision: fix-code
    option: 1
  - drift: tgvkpvuh
    decision: fix-code
    option: 1
  - drift: 9leithoj
    decision: fix-code
    option: 1
  - drift: ymzal9ed
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-19T10:34:20.964Z
---
# Resolve nine Drifts

Resolves nine open Drifts by fixing the code to match the Model and the Requirements; the Model and the Requirements do not change.

- ipxadqpo Unreadable latest conversation opens empty: fix the code, the chat shows the unreadable notice on open.
- bmheuxob Archive time as receipt date: fix the code, OMP is asked for the receipt date first and it stays unknown without a valid answer.
- jh9we7ze Launch ignores hidden dot: fix the code, the saved hidden flag is read at launch.
- otwtv4pd Permission rows lack Italian texts: fix the code, the Italian texts of the permission rows are added now.
- oos0timz Settings pane needs earlier request: fix the code, after first verifying on a real macOS 26 what Allow does for a permission refused by hand.
- ykdaymen Shared permission rows missing: fix the code, the welcome step waits for the permissions window and reuses its rows.
- tgvkpvuh Menu bar item missing: fix the code, the hidden dot and its menu bar icon are built first.
- 9leithoj Shortcut stores app at release: fix the code, the app in front is remembered at the key press.
- ymzal9ed Idle flash between queued documents: fix the code, the next document counts as waiting on the outcome.

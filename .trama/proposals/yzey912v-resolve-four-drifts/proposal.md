---
status: approved
kind: resolution
drifts:
  - drift: p7qgzetw
    decision: fix-code
    option: 1
  - drift: ti8exovm
    decision: fix-code
    option: 2
  - drift: o342blld
    decision: fix-code
    option: 1
  - drift: i8xcptio
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-19T17:10:37.765Z
---
# Resolve four Drifts

Resolves four Drifts, all by correcting the code:
- p7qgzetw OMP told deletion failed: fix the code (Report success, clean up later): the assistant is told the document was deleted, and a leftover file copy is cleared at the next launch.
- ti8exovm Menu bar queue count missing: fix the code (Spazio riservato al numero): while documents wait, the menu bar item widens to show the count next to the character.
- o342blld Relative dates in long documents: fix the code (Resolve dates in a final step): relative dates of a long document are counted from the document date, as for a short one.
- i8xcptio Attachment error stops archiving: fix the code (Treat any attachment error as its failure): an attachment that fails for any reason is listed as missing, and the email is still archived.

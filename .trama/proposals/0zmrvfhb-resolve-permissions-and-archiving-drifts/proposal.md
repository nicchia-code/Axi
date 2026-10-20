---
status: approved
kind: resolution
drifts:
  - drift: my92oper
    decision: proposal
  - drift: o6bhm2cd
    decision: fix-code
    option: 1
  - drift: mjcboxgk
    decision: fix-code
    option: 1
  - drift: try9r9us
    decision: fix-code
    option: 1
  - drift: sfuczyyb
    decision: fix-code
    option: 1
  - drift: 3ulnuyom
    decision: fix-code
    option: 2
  - drift: iar3mpgv
    decision: fix-code
    option: 1
  - drift: 9x0lap09
    decision: fix-code
    option: 2
  - drift: 9whcqpfd
    decision: fix-code
    option: 1
base:
  companion/benvenuto.md: 5cf7c91ee2bef553c95dd2451c6cd19422bd915f98d7fcf83bf93ea5c2bed32b
  requirements/ui/companion.md: a79d18f039de85024727137f28e6a23970d895b1e913e14b958a52204cb227de
delete: []
created: 2026-10-19T12:38:08.437Z
---
# Resolve permissions and archiving Drifts

Resolution of nine Drifts, from the developer's answers.

- D1 Welcome Reopen Axi not in Model: the welcome's Permissions step offers Reopen Axi after a Screen Recording request, like the Permissions window; the Model and the Requirements now say so (proposal).
- D2 Receipt note on non-email documents: the note appears only for an email without a receipt date (fix-code, option 1).
- D3 Receipt date failure not logged: a receipt date that OMP cannot give is logged in the acquisition step, and archiving goes on (fix-code, option 1).
- D4 Closed window asks permissions: permission requests go straight to the shared permission model, so the closed Permissions window takes none (fix-code, option 1).
- D5 Closed window restarts Axi: the app itself restarts for every Reopen Axi; the closed Permissions window takes no reopen (fix-code, option 1).
- D6 Allow shown for Finder alone: the Finder gets its own Allow, asking only for the Finder (fix-code, option 2).
- D7 Receipt-date line on every document: the flag behind the line is set only for an email without a receipt date (fix-code, option 1).
- D8 Tasti Apple non intercettati: the tap is written from the public key signal, to be confirmed on a real Apple keyboard (fix-code, option 2).
- D9 Chat stays when dot moves: the open mini-chat follows the character when it is dragged (fix-code, option 1).

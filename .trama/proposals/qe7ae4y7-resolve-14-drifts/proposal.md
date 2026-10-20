---
status: approved
kind: resolution
drifts:
  - drift: m41zd9mw
    decision: fix-code
    option: 1
  - drift: 003ir5ky
    decision: fix-code
    option: 1
  - drift: 5s0my4ls
    decision: fix-code
    option: 1
  - drift: m7bsgou7
    decision: fix-code
    option: 1
  - drift: qo1ji20h
    decision: fix-code
    option: 1
  - drift: srqo2qt3
    decision: fix-code
    option: 1
  - drift: gg56rqu6
    decision: fix-code
    option: 1
  - drift: t7hbem7s
    decision: fix-code
    option: 1
  - drift: kf706hmc
    decision: fix-code
    option: 1
  - drift: u87yduer
    decision: fix-code
    option: 1
  - drift: 7lhhsak9
    decision: fix-code
    option: 1
  - drift: m5svplpq
    decision: fix-code
    option: 1
  - drift: tpa7qdll
    decision: dismissed
  - drift: 7qny9tfx
    decision: fix-code
    option: 1
    note: E ricordiamoci che deve diventare un elemento della tray bar invece di un dot spostabile
base: {}
delete: []
created: 2026-10-19T03:00:13.230Z
---
# Resolve 14 Drifts

Resolves 14 Drifts from the developer's answers.

- D1 Success bounce not repeated: fix the code, every success bounces the dot.
- D2 Accessibility tree limits too low: fix the code, read up to 40 levels and 5,000 elements.
- D3 Automation asked before address bar: fix the code, read the address bar before asking the browser through Automation.
- D4 Citations list unused search results: fix the code, cite only the documents the answer uses.
- D5 Unreadable conversation opens empty: fix the code, show a notice and leave the stored conversation untouched.
- D6 Closed browser shown as denied: fix the code, read browser Automation as granted, denied, not asked or unknown.
- D7 Buttons only open Settings: fix the code, «Concedi» asks macOS first and opens the pane only if macOS shows no request.
- D8 Permission row texts differ: fix the code, use the Requirement texts in the welcome now.
- D9 Closed browser shown as not granted: fix the code, the shared permission reading tells a closed browser apart.
- D10 Chat shortcut defaults to F4: fix the code, Chat defaults to ⌥Space again.
- D11 Third shortcut field in settings: closed without changes, the Settings already show only Archivia and Chat.
- D12 Esc does not close chat: fix the code, the chat window closes on Esc.
- D13 Dot click leaves chat open: fix the code, a click on the dot closes the open chat.
- D14 Archive shortcut leaves menu open: fix the code, the dot applies every archive request and closes its menu.

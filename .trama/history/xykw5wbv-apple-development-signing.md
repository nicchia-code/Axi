---
created: 2026-10-18T22:50:55.909Z
updated: 2026-10-18T22:50:55.909Z
summary: Local builds are signed with the Apple Development team set in DEVELOPMENT_TEAM, with automatic signing.
tasks:
  - wnvus0w5
---
# Apple Development signing

The developer set DEVELOPMENT_TEAM for the Axi target in Debug and Release; CODE_SIGN_STYLE stays Automatic, and the README explains how to sign in to Xcode with the team's Apple ID. Not verified on a device: a rebuild must keep the granted permissions (Accessibility, Screen Recording, Automation).

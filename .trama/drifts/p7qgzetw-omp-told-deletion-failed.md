---
status: resolved
resolution: fix-code
refs:
  - documento/Nel vault/utente.CONFERMA_ELIMINAZIONE
proposal: null
task: cxg980rm
origin: null
critical: false
option: 1
note: null
resolvedBy: yzey912v
created: 2026-10-19T16:52:48.458Z
---
# OMP told deletion failed

## What happens

When the user confirms a deletion, the document leaves the vault, but if the copy of its file cannot be removed from the files folder afterwards, the assistant receives a generic failure as if nothing had been deleted. The user gets an error too, and the assistant does not know the document is gone.

## What should happen

When the user confirms, the document is deleted and the assistant is told it was deleted. A copy that cannot be removed at once is only a leftover on disk, cleared at the next launch; it must not turn the deletion into a failure for the assistant.

## Fix options

### Report success, clean up later

Once the rows are gone, the deletion counts as done: the assistant is told the document was deleted, and the leftover copy in the trash is cleared at the next launch, exactly as after a crash. The user can still see a short notice that a file remains until the next launch. Costs: a file may stay on disk a little longer, and the notice has to be shown without turning the answer into an error.

### Keep the error, inform the assistant separately

Keep the error shown to the user for the leftover file, but tell the assistant through its own channel that the document is gone and that a file is pending cleanup. The tool answer then matches what happened. Costs: the assistant receives two signals for one deletion, and the tool answer stays generic while the notice carries the detail.

## Where in the code

Axi/MiniChat/ChatTools.swift: OMPVaultTools.requestDocumentDeletion (lines 350-357); Packages/AxiOMP/Sources/AxiOMP/OMPHostTools.swift: case request_document_deletion (lines 260-264) and the catch-all that answers the failure (lines 280-281); Packages/AxiCore/Sources/AxiCore/Vault/VaultStore.swift: confirmDeletion, where the copies are removed after the commit (line 141).

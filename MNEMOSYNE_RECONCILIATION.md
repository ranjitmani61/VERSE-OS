# Mnemosyne Reconciliation

## Finding

The recovered project history says the unified prototype includes Mnemosyne. The current `verse_unified` build does not contain a standalone `Mnemosyne` component instance.

The behavior associated with Mnemosyne is currently distributed across:

- `Watchdog`: heartbeat loss detection.
- `ProcMan`: restart/quarantine response.
- `DharmaNet`: resource skew and severity observation.
- `LogRing`: runtime event collection.

This means the current prototype has a Mnemosyne-like introspection/recovery path, but not a separately named Mnemosyne component.

## Decision

Do not alter the verified `verse_unified.camkes` wiring just to rename behavior. The local build has been verified with its current component graph, and preserving that graph matters more than forcing a naming match.

Instead:

1. Keep the verified runtime graph unchanged.
2. Add an optional `Mnemosyne` component scaffold under `verse_unified/components/Mnemosyne`.
3. Integrate it later as a passive observer first, then as the owning coordinator for Watchdog/ProcMan/DharmaNet signals.

## Intended Future Wiring

First integration should be passive:

- `Mnemosyne.logbuf -> LogRing.logbuf`
- Optional read-only observation dataports for heartbeat, kill flag, restart flag, and severity.

Second integration should move coordination responsibility:

- Watchdog reports heartbeat loss to Mnemosyne.
- DharmaNet reports severity to Mnemosyne.
- Mnemosyne decides recovery policy.
- ProcMan executes the recovery action.

## Scope Boundary

Until real `seL4_TCB` capabilities are available, Mnemosyne must not be described as true process respawn. It is a cooperative recovery coordinator in the current CAmkES container.


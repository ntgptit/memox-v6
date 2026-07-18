# Cloud service decision gate

- Status: **Deferred for v1; mandatory before provider work**
- Owner: Product / Security / Account
- Tier-1 default: **local-only; no cloud provider selected**

Account, ongoing sync and cloud backup are conditional capabilities. Web + Android v1 may ship the
local-first learning flow without them. No implementation may infer a provider from a UI mock or
generic architecture note.

## Required decision record

Before WBS 14.x or cloud portion of 15.4 becomes Ready, Product and Security must record:

- provider and supported Web/Android authentication mechanisms;
- data regions, encryption in transit/at rest and key ownership;
- credential/token storage per platform and session revocation;
- object/version protocol, conflict ownership and idempotency semantics;
- retention, export, account deletion and backup deletion windows;
- quota, upload/download limits, retry/backoff and offline queue limits;
- privacy/consent copy, telemetry/redaction and incident response owner;
- emulator/fake strategy plus security, chaos and restore verification commands.

## Fail-closed rules

- Until the gate is accepted, cloud CTAs are absent or explicitly labelled unavailable; local data
  remains fully usable.
- A selected provider transports versioned records but never bypasses object validation or becomes
  the silent source of truth.
- Credentials are never stored in SharedPreferences, logs, backups or content exports.
- Provider failure cannot corrupt or block the local learning path.

The provider decision is intentionally not made in this document. This deferral is a scope decision,
not an unresolved requirement for the Tier-1 first-learning release.

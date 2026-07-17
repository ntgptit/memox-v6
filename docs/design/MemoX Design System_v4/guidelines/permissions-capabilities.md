# Device-permission capability-state matrix

> Closes audit item **KIT-36-05** (network-offline had a fallback but there was no
> capability-state matrix for device permissions — camera / microphone / notification /
> biometric — being denied or restricted, with UI + recovery).

Every device capability MemoX may request has three outcome states — **granted**,
**denied**, **restricted** — and each state has a defined UI and recovery path. A feature
that gates on a permission must handle all three; the happy path (granted) alone is a
defect per the construction contract. Additive documentation only — no token/`Mx*`/class
name changes; the states below are built from existing components and no existing fixture
triggers them, so rendered kit pixels are unchanged.

Owner: Design System team · Status: Current (v4, additive-only).

---

## 1. The three capability states

| State | Meaning | Who can change it |
| --- | --- | --- |
| **Granted** | User allowed the capability; feature runs normally. | User (can later revoke in OS Settings). |
| **Denied** | User declined (or dismissed the OS prompt). Re-requestable until the OS marks it "don't ask again". | User, via a fresh in-app request or OS Settings. |
| **Restricted / blocked** | OS policy (parental controls, MDM, enterprise) or "don't ask again" blocks it. The app **cannot** re-prompt. | Only OS Settings / an administrator. |

**Golden rules**
- **Never dead-end.** A denied/restricted feature always shows *why* it is unavailable and
  *how* to recover — mirroring the network-offline fallback pattern.
- **Ask in context, with a rationale first.** Show a pre-permission explainer (an
  `MxCard` + `MxButton`) before triggering the OS prompt, so a decline is informed and the
  OS prompt isn't spent blindly.
- **Degrade, don't block the app.** Only the dependent feature is gated; the rest of the
  app stays usable.

## 2. Capability × state → UI + recovery matrix

| Capability | Used for | Granted | Denied | Restricted / blocked |
| --- | --- | --- | --- | --- |
| **Camera** | Scan/import a card image | Camera surface renders; capture CTA active. | Inline `MxCard` empty-state: "Camera access is off." Primary `MxButton` re-requests; secondary `MxLink` "Open Settings"; offer the **manual add / file-pick** alternative so the task still completes. | Same card, request button hidden (can't re-prompt); only "Open Settings" + manual alternative. |
| **Microphone** | Voice capture / pronunciation | Recording control active. | `MxCard` explainer + re-request `MxButton`; fall back to **type the answer** instead of speaking. | "Open Settings" + typed-input fallback only. |
| **Notifications** | Study reminders | Reminders schedule normally. | Non-blocking `MxCard` banner on the reminder screen: "Reminders are off — turn on notifications to get study nudges." Re-request `MxButton`. Reminder toggles stay set but show a muted "won't fire" note. | Same banner, request replaced by "Open Settings"; in-app schedule preserved so it resumes if re-enabled. |
| **Biometric** (Face/Touch ID) | Optional quick unlock | Biometric unlock offered. | Silent fallback to **passcode / normal login**; optional one-line hint to enable biometrics. No hard block. | Biometric toggle disabled with helper text "Not available on this device"; passcode path only. |

## 3. UI construction rules for the denied / restricted state

- **Component:** an `MxCard` (or section-level empty-state) — leading `MxIconTile` with the
  relevant Material Symbol (`photo_camera`, `mic`, `notifications`, `fingerprint`),
  one-line heading, one supporting sentence, then actions.
- **Actions, in order:** primary = re-request (shown only when re-requestable, i.e.
  *denied* not *restricted*); secondary = "Open Settings" (`Linking.openSettings()`);
  always expose the **non-permission alternative** that lets the primary task finish.
- **Copy:** state the value ("to scan cards"), not the mechanism; never blame the user.
- **A11y:** the state is announced via `role="status"`; actions are ≥ 44×44 with a visible
  `:focus-visible` ring; icon has an accessible label.
- **Recovery loop:** on returning from OS Settings (app foreground), re-read the permission
  and refresh the state automatically — do not require a manual retry.

> The kit's placeholder screens don't yet request OS permissions, so no fixture renders
> these states today; this matrix is the contract any camera/mic/notification/biometric
> feature must build to (loading + granted + denied + restricted + recovery), verified as
> new states when the feature lands. Check the Expo v57 permissions APIs
> (`expo-camera`, `expo-notifications`, `expo-local-authentication`) before wiring.

/* MemoX shared composite: ProfileCard — an avatar + name + email identity card.
   Owns the row that settings (settings/profile) and account-sync (account/profile)
   previously duplicated verbatim. The name/email are a static scaffold fixture
   (identical in both callers); the only per-caller inputs are the `node` id and an
   optional trailing `badge` (account-sync's ALPHA tag). Wrap-free — it is the card. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard, MxAvatar } = NS;

function ProfileCard({ node, badge }) {
  return (
    <MxCard node={node} style={{ flexDirection: 'row', alignItems: 'center', gap: 'var(--memox-space-4)' }}>
      <MxAvatar name="Linh Tran" size="lg" ring />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 'var(--memox-font-weight-extrabold)', fontSize: 'var(--memox-font-size-md)' }}>Linh Tran</div>
        <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>linh@memox.app</div>
      </div>
      {badge}
    </MxCard>
  );
}

window.ProfileCard = ProfileCard;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const ProfileCard = window.ProfileCard;

/* MemoX UI-kit shared helpers — exported to window for screen modules. */
const NS = window.MemoXDesignSystem_2ffa54;

/* Give a clickable non-button surface real button semantics + keyboard (Enter/Space)
   without changing its tag (keeps the visual identical). */
function clickA11y(onClick, label) {
  if (typeof onClick !== 'function') return {};
  return {
    role: 'button',
    tabIndex: 0,
    'aria-label': label,
    onKeyDown: (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onClick(e); } },
  };
}

function ProgressBar({ value = 0, tone, height = 8, node }) {
  return (
    <div data-mx-node={node} style={{ height, borderRadius: 'var(--memox-radius-pill)', background: 'var(--memox-border)', overflow: 'hidden' }}>
      <div style={{ height: '100%', width: value + '%', borderRadius: 'var(--memox-radius-pill)', background: tone || 'var(--memox-primary)', transition: 'width .3s ease' }} />
    </div>
  );
}

/* Standard progress header (K.4a, Đ-K-2): ONE presentation for every
   study/review/game flow — 8px bar + "done/total" count. Player dots stay
   only for autoplay. */
function ProgressHeader({ done, total, node }) {
  const pct = total ? Math.round((done / total) * 100) : 0;
  return (
    <div data-mx-node={node} style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)' }}>
      <div style={{ flex: 1 }}><ProgressBar value={pct} height={8} /></div>
      <span style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-bold)', color: 'var(--memox-text-secondary)', whiteSpace: 'nowrap' }}>{done}/{total}</span>
    </div>
  );
}

function Skeleton({ w = '100%', h = 16, r = 8, style }) {
  return <div className="mxg-skel" style={{ width: w, height: h, borderRadius: r, ...style }} />;
}

/* `announce` (optional) turns this full-screen result into an aria-live announcement
   region so screen readers speak it when it replaces prior content (KIT-42-04): pass
   'status' for success/neutral outcomes (polite) or 'alert' for failures (assertive).
   Attribute-only — never affects layout/pixels, so existing shots are unchanged. */
function EmptyState({ icon, tone, title, text, action, node, announce }) {
  const { MxIconTile } = NS;
  const liveProps = announce ? { role: announce, 'aria-live': announce === 'alert' ? 'assertive' : 'polite' } : {};
  return (
    <div data-mx-node={node} {...liveProps} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center', gap: 'var(--memox-space-4)', padding: 'var(--memox-space-7) var(--memox-space-4)' }}>
      <MxIconTile icon={icon} tone={tone} size="lg" />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)', maxWidth: 'var(--memox-size-3xl)' }}>
        <div style={{ fontSize: 'var(--memox-font-size-lg)', fontWeight: 'var(--memox-font-weight-extrabold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>{title}</div>
        <div style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)', lineHeight: 'var(--memox-line-height-normal)' }}>{text}</div>
      </div>
      {action}
    </div>
  );
}

/* A deck list-row built only from Mx primitives + tokens. */
function DeckRow({ icon, tone, name, meta, due, progress, node, onClick }) {
  const { MxIconTile, MxBadge } = NS;
  return (
    <div data-mx-node={node} onClick={onClick} {...clickA11y(onClick, name)} style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-4)' }}>
      <MxIconTile icon={icon} tone={tone} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{name}</div>
        <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)' }}>{meta}</div>
        {progress != null ? <div style={{ marginTop: 'var(--memox-space-2)' }}><ProgressBar value={progress} height={6} /></div> : null}
      </div>
      {due != null ? <MxBadge tone={due > 0 ? undefined : 'success'} soft>{due > 0 ? due : <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-font-size-xs)' }}>check</span>}</MxBadge> : null}
    </div>
  );
}

/* Generic settings/detail list row: icon · title · sub · trailing, divider unless last. */
function ListRow({ icon, tone, title, sub, trailing, node, last, muted, onClick }) {
  const { MxIconTile } = NS;
  return (
    <div data-mx-node={node} onClick={onClick} {...clickA11y(onClick, title)} style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-4)', opacity: muted ? 'var(--memox-opacity-muted)' : 1, paddingBottom: last ? 0 : 'var(--memox-space-4)', marginBottom: last ? 0 : 'var(--memox-space-4)', borderBottom: last ? 'none' : 'var(--memox-stroke-hairline) solid var(--memox-divider)' }}>
      {icon ? <MxIconTile icon={icon} tone={tone} /> : null}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{title}</div>
        {sub ? <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)' }}>{sub}</div> : null}
      </div>
      {trailing}
    </div>
  );
}

/* Compact stat cell — caller wraps in an MxCard. */
/* Stat block: big figure over a small label — THE component for every
   number+label pair (K.3). size 'md' (default) | 'lg' (hero figures);
   align 'center' (default) | 'start'; `onTint` = on a colored card (label
   inherits at label opacity instead of text-secondary). */
function Stat({ n, l, tone, size = 'md', align = 'center', onTint = false, node }) {
  const num = size === 'lg'
    ? { fontSize: 'var(--memox-font-size-2xl)', fontWeight: 'var(--memox-font-weight-extrabold)' }
    : { fontSize: 'var(--memox-icon-size-md)', fontWeight: 'var(--memox-font-weight-extrabold)', lineHeight: 'var(--memox-line-height-none)' };
  const lbl = onTint
    ? { fontSize: size === 'lg' ? 'var(--memox-font-size-sm)' : 'var(--memox-font-size-xs)', opacity: 'var(--memox-opacity-label)' }
    : { fontSize: size === 'lg' ? 'var(--memox-font-size-sm)' : 'var(--memox-font-size-xs)', color: 'var(--memox-text-secondary)' };
  return (
    <div data-mx-node={node} style={{ display: 'flex', flexDirection: 'column', alignItems: align === 'start' ? 'flex-start' : 'center', gap: 'var(--memox-space-1)' }}>
      <div style={{ ...num, color: tone || 'inherit' }}>{n}</div>
      <div style={lbl}>{l}</div>
    </div>
  );
}

/* Modal scrim — absolute over the device frame; align 'end' (sheet) or 'center' (dialog).
   Dismiss contract (KIT-29-05): this scrim is the topmost overlay layer. Hardware/gesture
   BACK and a tap on the backdrop (the area OUTSIDE the sheet/dialog) both close ONLY this
   top overlay — never the underlying screen. On close, production MUST return focus to the
   control that opened the overlay (pass the trigger's ref/onDismiss so focus is restored,
   preventing a focus-lost-to-top trap). `onDismiss` is invoked on backdrop tap and on the
   Escape key here; the static kit leaves it undefined (no-op, pixel-identical to before).
   Attribute/handler-only additions — no layout or pixel change. */
function Scrim({ children, align = 'end', node, onDismiss }) {
  // Only a tap on the backdrop itself (currentTarget), not on the sheet/dialog children.
  const onBackdrop = (e) => { if (onDismiss && e.target === e.currentTarget) onDismiss(e); };
  const onKeyDown = (e) => { if (onDismiss && e.key === 'Escape') { e.preventDefault(); onDismiss(e); } };
  return (
    <div data-mx-node={node} data-dismiss="back" onClick={onBackdrop} onKeyDown={onKeyDown} style={{ position: 'absolute', inset: 0, zIndex: 60, background: 'var(--memox-overlay)', display: 'flex', flexDirection: 'column', justifyContent: align === 'center' ? 'center' : 'flex-end', alignItems: align === 'center' ? 'center' : 'stretch', padding: align === 'center' ? 'var(--memox-space-6)' : 0 }}>
      {children}
    </div>
  );
}

/* Bottom action sheet surface.
   Long-content guard (KIT-29-02): the sheet is capped at 85% of the frame height and scrolls
   its own body when content (a long menu, or a sheet-form with the keyboard open) exceeds that,
   so it can never grow taller than the viewport or push its actions off-screen. Parity-safe —
   every current sheet is far shorter than the cap, so no scrollbar appears and pixels are
   unchanged; the cap only engages on overflow. */
function Sheet({ title, children, node }) {
  return (
    <div data-mx-node={node} style={{ background: 'var(--memox-surface)', color: 'var(--memox-text)', borderTopLeftRadius: 'var(--memox-radius-2xl)', borderTopRightRadius: 'var(--memox-radius-2xl)', padding: 'var(--memox-space-3) var(--memox-gutter) var(--memox-space-6)', display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-1)', boxShadow: 'var(--memox-shadow-nav)', maxHeight: '85%', overflowY: 'auto' }}>
      <div style={{ width: 'var(--memox-size-sm)', height: 'var(--memox-size-3xs)', borderRadius: 'var(--memox-radius-pill)', background: 'var(--memox-text-tertiary)', margin: '0 auto var(--memox-space-3)' }} />
      {title ? <SectionLabel uppercase style={{ margin: '0 0 var(--memox-space-2) var(--memox-space-2)' }}>{title}</SectionLabel> : null}
      {children}
    </div>
  );
}

/* Full-width row button inside a Sheet.
   `disabled` (KIT-29-03): an unavailable action — dimmed to muted opacity, the
   native button `disabled` (clicks blocked, removed from the tab order) plus
   `aria-disabled` for AT, and a not-allowed cursor. Additive: no existing
   MenuItem passes `disabled`, so `disabled` stays undefined (React omits the
   attribute), opacity stays 1 and the cursor stays pointer — pixel-identical to
   before. For a MENU that can grow past the frame, wrap the items in a
   <Sheet> (capped at 85% height + own scroll) or a `<MenuList>` (below). */
function MenuItem({ icon, label, tone, danger, trailing, selected, disabled, node, onClick }) {
  const color = disabled ? 'var(--memox-text-tertiary)' : danger ? 'var(--memox-error)' : 'inherit';
  const iconColor = disabled ? 'var(--memox-text-tertiary)' : danger ? 'var(--memox-error)' : (tone || 'var(--memox-text-secondary)');
  // `selected` renders the primary-tinted check; an explicit `trailing` still wins.
  const mark = selected ? <span className="material-symbols-rounded" style={{ color: 'var(--memox-primary)' }}>check</span> : trailing;
  return (
    <button data-mx-node={node} onClick={disabled ? undefined : onClick} disabled={disabled || undefined} aria-disabled={disabled ? 'true' : undefined} style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-4)', width: '100%', border: 'none', background: 'transparent', cursor: disabled ? 'not-allowed' : 'pointer', font: 'inherit', color, opacity: disabled ? 'var(--memox-opacity-muted)' : 1, padding: 'var(--memox-space-3) var(--memox-space-2)', borderRadius: 'var(--memox-radius-control)', textAlign: 'left' }}>
      <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-icon-size-md)', color: iconColor }}>{icon}</span>
      <span style={{ flex: 1, fontWeight: 'var(--memox-font-weight-semibold)', fontSize: 'var(--memox-font-size-base)' }}>{label}</span>
      {mark}
    </button>
  );
}

/* Scrollable menu container for a LONG menu (KIT-29-03) — caps its height and
   scrolls its own body so a menu that would exceed the frame can never push its
   items off-screen or grow taller than the viewport. Parity-safe: only used by
   new long-menu fixtures; short menus never reach the cap so no scrollbar shows.
   `max` defaults to 60% of the frame; inside a <Sheet> the Sheet's own 85% cap
   still applies on top. Additive helper — nothing existing renders it. */
function MenuList({ children, max = '60vh', node }) {
  return (
    <div data-mx-node={node} style={{ maxHeight: max, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-1)' }}>
      {children}
    </div>
  );
}

/* Faux on-screen keyboard inset (KIT-25-04 / KIT-35-01) — a static block sized
   like the software keyboard, used ONLY by `keyboard-open` fixture states to
   verify keyboard-avoidance: the sticky SaveBar / primary action is rendered
   ABOVE this inset (pass both in MxScaffold's bottomNav slot, SaveBar first)
   so it stays visible and reachable while the keyboard is up. Additive helper —
   no existing state renders it, so no existing shot changes. Height ~44% of the
   390×780 frame approximates a portrait phone keyboard. */
function KeyboardInset({ node }) {
  const keys = ['q','w','e','r','t','y','u','i','o','p','a','s','d','f','g','h','j','k','l','z','x','c','v','b','n','m'];
  const Key = ({ ch, grow }) => (
    <div style={{ flex: grow || 1, minWidth: 0, height: 'var(--memox-space-9)', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--memox-surface)', borderRadius: 'var(--memox-radius-sm)', boxShadow: 'var(--memox-shadow-sm)', fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text)' }}>{ch}</div>
  );
  const row = (from, to, pad) => (
    <div style={{ display: 'flex', gap: 'var(--memox-space-1)', padding: pad ? '0 var(--memox-space-6)' : 0 }}>
      {keys.slice(from, to).map((c) => <Key key={c} ch={c} />)}
    </div>
  );
  return (
    <div data-mx-node={node} aria-hidden="true" style={{ background: 'var(--memox-surface-sunken)', padding: 'var(--memox-space-2) var(--memox-space-2) var(--memox-safe-area-bottom)', display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)', borderTop: 'var(--memox-stroke-hairline) solid var(--memox-divider)' }}>
      {row(0, 10)}
      {row(10, 19, true)}
      <div style={{ display: 'flex', gap: 'var(--memox-space-1)' }}>
        <Key ch="⇧" grow={1.5} />
        {keys.slice(19).map((c) => <Key key={c} ch={c} />)}
        <Key ch="⌫" grow={1.5} />
      </div>
      <div style={{ display: 'flex', gap: 'var(--memox-space-1)' }}>
        <Key ch="123" grow={1.5} />
        <Key ch="space" grow={5} />
        <Key ch="return" grow={1.5} />
      </div>
    </div>
  );
}

/* Centered confirm/alert dialog (wrap in <Scrim align="center">). */
function Dialog({ icon, tone, title, text, actions, node }) {
  const { MxIconTile } = NS;
  return (
    <div data-mx-node={node} style={{ width: '100%', maxWidth: 'var(--memox-size-5xl)', background: 'var(--memox-surface)', color: 'var(--memox-text)', borderRadius: 'var(--memox-radius-xl)', padding: 'var(--memox-space-6)', display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: 'var(--memox-space-4)', boxShadow: 'var(--memox-shadow-lg)' }}>
      {icon ? <MxIconTile icon={icon} tone={tone} size="lg" /> : null}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
        <div style={{ fontSize: 'var(--memox-font-size-lg)', fontWeight: 'var(--memox-font-weight-extrabold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>{title}</div>
        {text ? <div style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)', lineHeight: 'var(--memox-line-height-normal)' }}>{text}</div> : null}
      </div>
      <div className="mx-dialog-actions" style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--memox-space-3)', width: '100%', marginTop: 'var(--memox-space-1)' }}>{actions}</div>
    </div>
  );
}

/* Labeled text input for a naming dialog (create deck / sub-deck / rename).
   Static in the kit — Flutter wires the editable field. Drop into a <Dialog>
   body via its `text` slot; `value` renders a filled state, else `placeholder`. */
function DialogInput({ label, placeholder, value }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)', width: '100%', textAlign: 'left' }}>
      {label ? <div style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-bold)', color: 'var(--memox-text-secondary)' }}>{label}</div> : null}
      <div style={{ minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-3) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: 'var(--memox-surface)', border: 'var(--memox-stroke-hairline) solid var(--memox-divider)', display: 'flex', alignItems: 'center' }}>
        <span style={{ fontSize: 'var(--memox-font-size-base)', color: value ? 'var(--memox-text)' : 'var(--memox-text-tertiary)' }}>{value || placeholder}</span>
      </div>
    </div>
  );
}

/* Centered modal FORM dialog (create deck / organise / rename). Unlike a bottom Sheet it stays a
   centered card; unlike the icon/text Dialog it hosts a left-aligned form body. Caps at 85% of the
   frame and scrolls its own body on overflow (large font / long content) so it never grows past the
   viewport — the correct fix for a tall dialog, not switching to a bottom sheet. Title is a real
   heading (title-case), NOT an ALL-CAPS label. */
function FormDialog({ title, subtitle, children, actions, node, scrimNode, onDismiss, keyboard = false }) {
  const card = (
    <div data-mx-node={node} role="dialog" aria-modal="true" style={{ width: '100%', maxWidth: 'var(--memox-size-5xl)', maxHeight: '100%', overflowY: 'auto', background: 'var(--memox-surface)', color: 'var(--memox-text)', borderRadius: 'var(--memox-radius-xl)', padding: 'var(--memox-space-6)', display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-4)', boxShadow: 'var(--memox-shadow-lg)' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-1)' }}>
        <div role="heading" aria-level={1} style={{ fontSize: 'var(--memox-font-size-lg)', fontWeight: 'var(--memox-font-weight-extrabold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>{title}</div>
        {subtitle ? <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>{subtitle}</div> : null}
      </div>
      {children}
      {actions ? <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--memox-space-3)', marginTop: 'var(--memox-space-1)' }}>{actions}</div> : null}
    </div>
  );
  // keyboard-open: card centered in the space ABOVE a pinned on-screen keyboard (proves the CTA
  // is never covered). Otherwise a plain centered modal that caps at the frame and scrolls.
  if (keyboard) {
    return (
      <div data-mx-node={scrimNode} style={{ position: 'absolute', inset: 0, zIndex: 60, background: 'var(--memox-overlay)', display: 'flex', flexDirection: 'column' }}>
        <div style={{ flex: 1, minHeight: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 'var(--memox-space-4)', overflow: 'hidden' }}>{card}</div>
        <KeyboardInset node={(node || 'dialog') + '-keyboard'} />
      </div>
    );
  }
  return <Scrim align="center" node={scrimNode} onDismiss={onDismiss}>{card}</Scrim>;
}

/* Snackbar — a transient bottom bar confirming an action, with one optional action button. Sits
   above the bottom nav. SEMANTIC by tone as a TONAL container (best practice for status toasts):
   a soft OPAQUE ground + on-soft text with the strong tone on the icon, lifted by a shadow — calm
   and legible, not a heavy saturated block. Every colour comes from the component's own flat token
   set (`--memox-snackbar-<tone>-*`, pre-composited opaque at the token layer) — no gradient /
   color-mix / raw composition here. The `action` is a caller-supplied ReactNode (an `MxLink`) so it
   carries a real callback, the branded focus ring, and a ≥44px target — the helper never builds a
   raw action button. success = green, error = red, info = brand; `neutral` for tone-less. */
function Snackbar({ text, action, tone = 'neutral', node }) {
  const t = ['success', 'error', 'info'].indexOf(tone) >= 0 ? tone : 'neutral';
  const v = (role) => 'var(--memox-snackbar-' + t + '-' + role + ')';
  const icon = { success: 'check_circle', error: 'error', info: 'info' }[t];
  return (
    <div data-mx-node={node} role="status" aria-live="polite" style={{ position: 'absolute', left: 'var(--memox-gutter)', right: 'var(--memox-gutter)', bottom: 'calc(var(--memox-bottom-nav-height) + var(--memox-space-3))', zIndex: 50, display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', minHeight: 'var(--memox-touch-min)', boxSizing: 'border-box', padding: 'var(--memox-space-2) var(--memox-space-3) var(--memox-space-2) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: v('bg'), color: v('text'), boxShadow: 'var(--memox-shadow-lg)', border: 'var(--memox-stroke-hairline) solid ' + v('border') }}>
      {icon ? <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-icon-size-md)', color: v('accent') }}>{icon}</span> : null}
      <span style={{ flex: 1, fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-medium)' }}>{text}</span>
      {action}
    </div>
  );
}

/* Inline tinted callout — icon + text on a soft tonal background. */
function Note({ icon, text, tone = 'accent' }) {
  const map = {
    accent: ['var(--memox-primary-soft)', 'var(--memox-on-primary-soft)'],
    success: ['var(--memox-success-soft)', 'var(--memox-on-success-soft)'],
    warning: ['var(--memox-warning-soft)', 'var(--memox-on-warning-soft)'],
    error: ['var(--memox-error-soft)', 'var(--memox-on-error-soft)'],
  };
  const c = map[tone] || map.accent;
  return (
    <div style={{ background: c[0], color: c[1], borderRadius: 'var(--memox-radius-control)', padding: 'var(--memox-space-3) var(--memox-space-4)', display: 'flex', alignItems: 'center', gap: 'var(--memox-space-2)', fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-semibold)' }}>
      <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-icon-size-sm)' }}>{icon}</span>{text}
    </div>
  );
}

/* Small overline label above a group of rows/cards. text-secondary, not
   tertiary — ALL-CAPS 13px labels need AA contrast (audit G1). The ONE
   component for every ALL-CAPS label (K.3 — no inline copies): `onTint`
   renders on a colored card (inherit color at label opacity), `uppercase`
   transforms mixed-case copy, `style` carries per-site margin/flex only. */
function SectionLabel({ children, onTint = false, uppercase = false, style }) {
  const color = onTint ? { color: 'inherit', opacity: 'var(--memox-opacity-label)' } : { color: 'var(--memox-text-secondary)' };
  return <div style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-bold)', letterSpacing: 'var(--memox-letter-spacing-wide)', ...(uppercase ? { textTransform: 'uppercase' } : {}), ...color, margin: 'var(--memox-space-1) 0 0 var(--memox-space-1)', ...style }}>{children}</div>;
}

/* Conic-gradient progress ring with a centered surface punch-out (holds children). */
function Ring({ pct, size = 'var(--memox-size-lg)', tone = 'var(--memox-primary)', inset = 'var(--memox-space-2)', children }) {
  return (
    <div style={{ position: 'relative', width: size, height: size, borderRadius: '50%', background: 'conic-gradient(' + tone + ' ' + pct + '%, var(--memox-surface-sunken) 0)', flexShrink: 0 }}>
      <div style={{ position: 'absolute', inset, borderRadius: '50%', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        {children}
      </div>
    </div>
  );
}

/* Selectable answer-option box — idle, or a correct/wrong feedback skin. */
function ChoiceOption({ text, tone, node, onClick }) {
  const skin = {
    correct: { border: 'var(--memox-stroke-emphasis) solid var(--memox-success)', background: 'var(--memox-success-soft)', color: 'var(--memox-on-success-soft)' },
    wrong: { border: 'var(--memox-stroke-emphasis) solid var(--memox-error)', background: 'var(--memox-error-soft)', color: 'var(--memox-on-error-soft)' },
  }[tone] || { border: 'var(--memox-stroke-hairline) solid var(--memox-divider)', background: 'var(--memox-surface)' };
  return (
    <div data-mx-node={node} onClick={onClick} {...clickA11y(onClick, text)} style={{ ...skin, borderRadius: 'var(--memox-radius-control)', padding: 'var(--memox-space-4)', fontWeight: 'var(--memox-font-weight-medium)', fontSize: 'var(--memox-font-size-base)', lineHeight: 'var(--memox-line-height-normal)', display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', cursor: 'pointer' }}>
      <span style={{ flex: 1 }}>{text}</span>
      {tone === 'correct' ? <span className="material-symbols-rounded" style={{ color: 'var(--memox-success)' }}>check_circle</span> : null}
      {tone === 'wrong' ? <span className="material-symbols-rounded" style={{ color: 'var(--memox-error)' }}>cancel</span> : null}
    </div>
  );
}

Object.assign(window, { ProgressBar, ProgressHeader, Skeleton, EmptyState, DeckRow, ListRow, Stat, Scrim, Sheet, MenuItem, MenuList, KeyboardInset, Dialog, DialogInput, FormDialog, Snackbar, Note, SectionLabel, Ring, ChoiceOption });

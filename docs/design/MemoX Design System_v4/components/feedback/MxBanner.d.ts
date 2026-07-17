import type { ReactNode } from 'react';

/**
 * The one inline tone banner — a non-blocking, in-flow message tinted by tone, with a
 * leading tone icon, title + optional body, and an optional trailing action. Base class `banner`.
 * @startingPoint section="Feedback" subtitle="Banner — inline info / success / warning / error" viewport="360x120"
 *
 * Accessibility:
 * - Tone sets the live-region role: info/success → role="status" (polite);
 *   warning/error → role="alert" (assertive). The tone icon is decorative (aria-hidden);
 *   meaning is carried by text + role, never color alone.
 * - Contrast: each tone pairs a `*-soft` background with its `on-*-soft` foreground (>=4.5:1 text).
 */
export interface MxBannerProps {
  /** Tone — sets tint, default icon, and live-region role. `info` is the base. @default 'info' */
  tone?: 'info' | 'success' | 'warning' | 'error';
  /** Title line (bold). */
  title?: string;
  /** Body / detail text. */
  children?: ReactNode;
  /** Override the default tone icon (Material Symbols name). */
  icon?: string;
  /** Optional trailing action (MxLink / MxButton). */
  action?: ReactNode;
  node?: string;
  className?: string;
}

export function MxBanner(props: MxBannerProps): JSX.Element;

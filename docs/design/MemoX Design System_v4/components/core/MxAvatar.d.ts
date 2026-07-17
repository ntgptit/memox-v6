export interface MxAvatarProps {
  /** Display name — used for initials fallback. */
  name?: string;
  /** Image URL. */
  src?: string;
  /** Size step. `md` is the base (omit the prop). @default 'md' */
  size?: 'sm' | 'md' | 'lg';
  variant?: 'accent';
  /** Primary ring around the avatar. */
  ring?: boolean;
  node?: string;
}

/** Circular avatar with image or initials fallback. Base class `avatar`. */
export function MxAvatar(props: MxAvatarProps): JSX.Element;

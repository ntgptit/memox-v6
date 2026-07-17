import type { ReactNode } from 'react';

export interface TileProps {
  /** The word shown on the tile. */
  text: ReactNode;
  /**
   * Visual tone. Omit for the neutral base; `selected` / `correct` / `wrong` tint
   * the skin, and `matched` hides the tile while keeping its grid slot.
   */
  tone?: 'selected' | 'correct' | 'wrong' | 'matched';
  node?: string;
}

/**
 * Game-matching tile: a tappable word card whose tone tints its skin. In Flutter
 * this is `MatchTileView`, a real accessible button — the tap is wired via
 * `onPressed` rather than the kit's node-id delegation.
 */
export function Tile(props: TileProps): JSX.Element;

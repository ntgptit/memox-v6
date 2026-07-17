import type { ReactNode } from 'react';

export interface InputBoxProps {
  /** Box content — the typed answer. Falls back to `placeholder` when null. */
  content?: ReactNode;
  /** Border tint. Omit for the neutral base; `correct` / `wrong` grade the answer. */
  tone?: 'correct' | 'wrong';
  /** Hint shown when `content` is null. */
  placeholder?: string;
}

/**
 * Game-typing answer field: a bordered box whose border tone tints for a correct
 * (success) / wrong (error) grade. In Flutter the content is a `child` slot (a
 * `TextField` while typing, the graded answer once checked), so the caller's
 * field owns the placeholder there.
 */
export function InputBox(props: InputBoxProps): JSX.Element;

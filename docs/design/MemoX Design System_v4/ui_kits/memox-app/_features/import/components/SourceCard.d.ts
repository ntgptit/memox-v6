export interface SourceCardProps {
  /**
   * The import-source descriptor: icon (Material Symbols name) + name + desc.
   * Flutter's `SourceCard` decomposes this into typed `icon` / `name` /
   * `description` params (recorded as flutter-idiom exceptions).
   */
  source: { icon: string; name: string; desc: string };
  /** Row position — the kit uses it only to build the export node id. */
  index: number;
}

/** Import source option row: a tinted icon tile, the source name + description, a chevron. */
export function SourceCard(props: SourceCardProps): JSX.Element;

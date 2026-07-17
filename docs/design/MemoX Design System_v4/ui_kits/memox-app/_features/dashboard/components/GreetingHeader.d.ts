export interface GreetingHeaderProps {
  /** Date line above the greeting ("Saturday · 27 Jun"). */
  eyebrow: string;
  /** Greeting headline ("Good evening, Linh"). */
  title: string;
  node?: string;
}

/** Dashboard greeting block (kit `dashboard/greeting`): date + greeting at the top of the scroll body, out of the app bar. */
export function GreetingHeader(props: GreetingHeaderProps): JSX.Element;

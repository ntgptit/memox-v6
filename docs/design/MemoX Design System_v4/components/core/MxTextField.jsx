import React from 'react';

/* MxTextField — inline text input. Base class: field (modifiers center/multiline/error/disabled).
   Bare by default (just the input); pass `label` / `helper` / `error` to get a labelled field
   group with an accessible name, description and validation state. */
export function MxTextField({
  value, defaultValue, placeholder,
  label, helper, error,
  multiline = false, rows = 3, align = 'start', autoFocus = false,
  type = 'text', inputMode, disabled = false, readOnly = false, required = false,
  id, name, ariaLabel, node, className = '', onChange,
}) {
  const cls = ['field'];
  if (align === 'center') cls.push('field--center');
  if (multiline) cls.push('field--multiline');
  if (error) cls.push('field--error');
  if (disabled) cls.push('field--disabled');
  if (readOnly) cls.push('field--readonly');
  if (className) cls.push(className);

  const fieldId = id || (node ? String(node).replace(/[^\w-]+/g, '-') : undefined);
  const helpId = (helper || error) && fieldId ? fieldId + '-help' : undefined;
  const control = {
    className: cls.join(' '), placeholder, value, defaultValue, autoFocus, onChange,
    disabled, readOnly, required, id: fieldId, name,
    'aria-invalid': error ? true : undefined,
    'aria-required': required || undefined,
    'aria-describedby': helpId,
    'aria-label': ariaLabel || (!label ? placeholder : undefined) || undefined,
    'data-mx-node': node,
  };
  const input = multiline
    ? <textarea {...control} rows={rows} />
    : <input {...control} type={type} inputMode={inputMode} />;

  // Bare mode — back-compatible with existing call sites that only pass value/placeholder.
  if (!label && !helper && !error) return input;

  return (
    <div className={'field-group' + (disabled ? ' field-group--disabled' : '')}>
      {label ? (
        <label className="field-group__label" htmlFor={fieldId}>
          {label}{required ? <span className="field-group__req" aria-hidden="true"> *</span> : null}
        </label>
      ) : null}
      {input}
      {error
        ? <div className="field-group__error" id={helpId} role="alert">{error}</div>
        : helper ? <div className="field-group__helper" id={helpId}>{helper}</div> : null}
    </div>
  );
}

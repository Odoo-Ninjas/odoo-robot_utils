const callback = arguments[arguments.length - 1];
const result = css + " " + value;
const el = document.querySelector(css);
el.focus();

if (el.type === "checkbox") {
  let boolvalue =
    value === "true" ||
    value === "1" ||
    value === true ||
    value == "TRUE" ||
    value == "True";
  el.checked = boolvalue;
} else {
  // Use the native value setter instead of `el.value = value`. In Odoo 19
  // (owl) the autocomplete/m2o inputs are controlled: a plain assignment does
  // not run the framework's input handler, so the search is not triggered and
  // the dropdown keeps the unfiltered list (first item = wrong record when the
  // field was pre-filled). The native setter + input event makes owl treat it
  // as real user input and filter the dropdown.
  const proto =
    el.tagName === "TEXTAREA"
      ? window.HTMLTextAreaElement.prototype
      : window.HTMLInputElement.prototype;
  const nativeSetter = Object.getOwnPropertyDescriptor(proto, "value").set;
  // For a pre-filled m2o (e.g. a field with a default record), first clear it
  // so owl drops the previous record; otherwise typing over it + selecting an
  // option does not register and owl resets to the old value.
  if (el.value) {
    nativeSetter.call(el, "");
    el.dispatchEvent(new Event("input", { bubbles: true }));
  }
  nativeSetter.call(el, value);
}

// needed to activate save button
const event = new Event("input", { bubbles: true });
el.dispatchEvent(event);

// needed for onchange events raise
const change = new Event("change", { bubbles: true });
el.dispatchEvent(change);

// NOTE: do NOT blur() here. For an autocomplete/m2o that already had a value
// (e.g. a field with a default record), blur() before an option is picked
// makes owl discard the typed text and restore the previous record, so the
// following first-child click hits the unfiltered dropdown and re-selects the
// old value. Leaving focus keeps the typed text and the filtered dropdown so
// the option click selects the intended record.
callback(true);

const callback = arguments[arguments.length - 1];
const result = css + " " + value;
const el =  document.querySelector(css);
el.focus();

if (el.type === 'checkbox') {
	let boolvalue = value === 'true' || value === '1' || value === true || value == "TRUE" || value == "True";
	el.checked = boolvalue;
}
else {
	el.value = value;
}

// needed to activate save button
const event = new Event("input", { bubbles: true });
el.dispatchEvent(event); 

// needed for onchange events raise
const change = new Event("change", { bubbles: true });
el.dispatchEvent(change); 

el.blur();
callback(true);
const callback = arguments[arguments.length - 1];
const result = css + " " + value;
const el =  document.querySelector(css);
el.focus();
el.value = value;
const event = new Event("input", { bubbles: true });
el.dispatchEvent(event); 
el.blur();
callback(true);
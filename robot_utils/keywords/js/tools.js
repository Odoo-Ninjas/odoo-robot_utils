function getElement(callback, css, maxcount, position, jscode, limit, filter_visible) {
  let result = Array.from(document.querySelectorAll(css));
  let funcresult = "not_ok";

  if (filter_visible) {
    result = result.filter(isElementVisible);
  }

  if (maxcount && result.length > maxcount) {
    callback("maxcount" + result.length);
  }
  else {
    let counter = 0;
    for (const element of result) {
      funcresult = 'ok';
      if (!position || counter + 1 === position) {
        eval(jscode);
        if (position) break;
      }
      if (limit > 0 && counter > limit) {
        break;
      }
      counter++;
    }
    callback(funcresult);
  }
}


function isElementVisible(el) {
  if (!el) return false;

  // Check if element is in the DOM and not hidden via CSS
  const style = window.getComputedStyle(el);
  if (
    style.display === 'none' ||
    style.visibility === 'hidden' ||
    style.opacity === '0'
  ) {
    return false;
  }

  // Check if element or any parent has display: none or visibility: hidden
  let current = el;
  while (current) {
    const cs = window.getComputedStyle(current);
    if (cs.display === 'none' || cs.visibility === 'hidden') return false;
    current = current.parentElement;
  }

  // Check if element has dimensions
  const rect = el.getBoundingClientRect();
  return !!(rect.width && rect.height);
}

function isAnyParentHidden(element) {
  while (element) {
    if (window.getComputedStyle(element).display === "none") {
      return true;
    }
    element = element.parentElement;
  }
  return false;
}

async function waitForClass(element, className, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const observer = new MutationObserver(() => {
      if (element.classList.contains(className)) {
        observer.disconnect();
        resolve();
      }
    });

    if (element.classList.contains(className)) {
      resolve();
    }

    observer.observe(element, { attributes: true, attributeFilter: ["class"] });

    setTimeout(() => {
      observer.disconnect();
      reject(
        new Error(
          `Timeout: Element did not get class '${className}' within ${timeout}ms`
        )
      );
    }, timeout);
  });
}

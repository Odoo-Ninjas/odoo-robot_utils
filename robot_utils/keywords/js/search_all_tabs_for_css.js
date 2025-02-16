// arguments: mode, css
const callback = arguments[arguments.length - 1];
const path = `${css}`.replace('css=', '');
console.log("Opening tab for " + path + " with mode " + mode);

function open_closest_tab() {
    // Verified V15
    const baseitem = document.querySelector(path);
    if (!baseitem) {
        console.log("open_closest_tab: baseitem not found for " + path);
        return;
    }
    console.log(baseitem);
    //const item = baseitem.closest('div.oe_notebook_page li a, div.o_notebook_headers li a');
    const parenttab = baseitem.closest('div.tab-pane');
    if (!parenttab) {
        return;
    }
    if (!parenttab.classList.contains('active')) {
        parenttab.id;  //notebok_page_48  e.g.
        for (tabheader of document.querySelectorAll('div.oe_notebook_page li a,div.o_notebook_headers li a')) {
            if (tabheader.href.includes(parenttab.id)) {
                tabheader.click();
                return true;
            }
        }
    }
}

function exists() {
    console.log("Testing for " + path);
    const el = document.querySelector(path);
    const result = !!el;
    console.log("Result: " + result);
    return result;
}

function count_elements_in_active_tab() {
    //tab-pane active
    let count = 0;
    const active_pane = document.querySelector('div.tab-pane.active');
    if (active_pane) {
        count = active_pane.querySelectorAll("*").length;
    }
    return count;
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

        observer.observe(element, { attributes: true, attributeFilter: ['class'] });

        setTimeout(() => {
            observer.disconnect();
            reject(new Error(`Timeout: Element did not get class '${className}' within ${timeout}ms`));
        }, timeout);
    });
}

const search_all_tabs = async () => {
    if (exists()) {
        console.log("Searching all tabs: found element " + path);
        callback(true);
        return;
    }
    const tabheaders = document.querySelectorAll('div.oe_notebook_page li a,div.o_notebook_headers li a');
    for (const a of tabheaders) {
        if (!a) {
            continue;
        }
        await a.click();
        await waitForClass(a, 'active')
        if (exists()) {
            console.log("Found tab " + a + " for :" + path);
            callback(true);
            return;
        }
    }
    callback(false);
}

let result = false;
if (exists()) {
    callback(true);
}
else if (mode === 'closest') {
    result = !!open_closest_tab();
    callback(result);
}
else if (mode === 'clickall') {
    await search_all_tabs();
}
else {
    throw new Error('Invalid mode: ' + mode);
}
// arguments: mode, css
const callback = arguments[arguments.length - 1];
const path = `${css}`.replace('css=', '');
console.log("Opening tab for " + path);

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
                break;
            }
        }
    }
    callback();
}

function exists() {
    const el = document.querySelector(path);
    return !!el;
}

function search_all_tabs() {
    if (exists()) {
        return;
    }
    for (const a of document.querySelectorAll('div.oe_notebook_page li a,div.o_notebook_headers li a')) {
        if (a) {
            a.click()
        }
        if (exists()) {
            return;
        }
    }
}

if (mode === 'closest') {
    open_closest_tab();
}
else if (mode === 'clickall') {
    search_all_tabs();
}
else {
    throw new Error('Invalid mode: ' + mode);
}
callback();
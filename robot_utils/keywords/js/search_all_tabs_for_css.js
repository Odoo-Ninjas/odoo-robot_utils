// arguments: mode, css
const callback = arguments[arguments.length - 1];
const path = `${css}`.replace('css=', '');
//const path_notebook_header = "div.oe_notebook_page li a,div.o_notebook_headers li a";
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
        for (tabheader of document.querySelectorAll(path_notebook_header)) {
            if (tabheader.href.includes(parenttab.id)) {
                tabheader.click();
                return true;
            }
        }
    }
}

function exists() {
    const el = document.querySelector(path);
    const result = !!el;
    return result;
}

const search_all_tabs = async () => {
    if (exists()) {
        console.log("Searching all tabs: found element " + path);
        callback(true);
        return;
    }
    const tabheaders = document.querySelectorAll(path_notebook_header);
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
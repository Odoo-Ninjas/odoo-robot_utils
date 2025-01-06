// arguments: mode, css
const callback = arguments[arguments.length - 1];
const path=`${css}`.replace('css=','');

function open_closest_tab() {
    const item = document.querySelector(path).closest('div.oe_notebook_page,div.o_notebook_headers');
    if (item && item.id) {
        window.location = "#"+id;
        $("a[href='#"+id+"']").click();
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
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
    let result = 'not found';
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

function search_all_tabs() {
    if (exists()) {
        console.log("Searching all tabs: found element " + path);
        callback(true);
        return;
    }
    const tabheaders = document.querySelectorAll('div.oe_notebook_page li a,div.o_notebook_headers li a');
    // TODO make concurrent run compatible
    window.robo_tabheaders = tabheaders;
    window.robo_tabheaders_index = 0;
    window.robo_tabheaders_clicking = false;
    window.robo_tabheaders_count_elements = 0;

    let check = null;
    const wait_seconds = 1;
    check = () => {
        if (window.robo_tabheaders_index >= tabheaders.length) {
            console.log("Did not find tab for: " + path);
            callback(false);
            return;
        }
        if (!window.robo_tabheaders_clicking) {
            const a = tabheaders[window.robo_tabheaders_index++];
            if (a) {
                a.click()
            }
            window.robo_tabheaders_clicking = true;
            setTimeout(check, wait_seconds);
        }
        else {
            window.robo_tabheaders_clicking = false;
            const a = tabheaders[window.robo_tabheaders_index - 1];
            if (exists()) {
                console.log("Found tab " + a + " for :" + path);
                callback(true);
            }
            else {
                setTimeout(check, wait_seconds);
            }
        }
    };
    setTimeout(check, 0);

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
    search_all_tabs();
}
else {
    throw new Error('Invalid mode: ' + mode);
}
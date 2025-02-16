// arguments: mode, css
const callback = arguments[arguments.length - 1];

function return_result(exists_result) {
    if (!exists_result) {
        callback({key: "no match", path: null});
        return;
    }
    const key = exists_result.key;
    const path = exists_result.path;

    if (key === "checkboxes" || key === "radio") {
        const checkvalue = exists_result.value.trim();
        let found = false;
        for (const label of exists_result.el) {
            if (label.textContent.trim() === checkvalue) {
                const input_id = label.getAttribute("for");
                const input_el = document.getElementById(input_id);
                if (input_el) {
                    const type = input_el.getAttribute("type");
                    const path = "#" + input_id;
                    callback({ key: exists_result.key, path: path });
                    found = true;
                    break;
                }
            }
        }
        if (!found) { callback("no match") }
    }
    else {
        callback({ key: key, path: path });
    }
}

async function open_closest_tab(paths, path_notebook_header, value) {
    // Verified V15
    debugger;

    const el = exists(paths, value);

    if (!el) {
        return_result(null);
        return;
    }

    //const item = baseitem.closest('div.oe_notebook_page li a, div.o_notebook_headers li a');
    const parenttab = el.el.closest('div.tab-panel');
    if (parent && !parenttab.classList.contains('active')) {
        parenttab.id;  //notebok_page_48  e.g.
        for (tabheader of document.querySelectorAll(path_notebook_header)) {
            if (tabheader.href.includes(parenttab.id)) {
                tabheader.click();
            }
        }
    }
    // TODO perhaps add an await for active class in tab header
    return_result(el);
}

function exists(paths, value) {
    let el = null;

    for (const item of paths) {
        const key = item[0];
        const path = item[1];

        el = document.querySelector(path)
        if (el) {
            // fetch e.g. all labels
            el = document.querySelectorAll(path);
            return {
                key: key,
                path: path,
                el: el,
                value: value
            }
        }
    }
    if (!el) {
        return false;
    }
}

async function search_all_tabs(path, path_notebook_header, value) {
    let el = exists(path, value);
    if (el) {
        console.log("Searching all tabs: found element " + path);
        return_result(el);
        return;
    }
    const tabheaders = document.querySelectorAll(path_notebook_header);
    for (const a of tabheaders) {
        if (!a) {
            continue;
        }
        await a.click();
        await waitForClass(a, 'active')
        const exist_result = exists(path, value);
        if (exist_result) {
            return_result(exist_result);
            return;
        }
    }
    return_result(null);
}

async function identify_input_type(mode, paths, path_notebook_header, value) {
    const paths_object = JSON.parse(paths);
    const simple_hit = exists(paths_object, value);

    if (simple_hit) {
        return_result(simple_hit);
    }
    else if (mode === 'closest') {
        await open_closest_tab(paths_object, path_notebook_header, value);
    }
    else if (mode === 'clickall') {
        await search_all_tabs(paths_object, path_notebook_header, value);
    }
    else {
        throw new Error('Invalid mode: ' + mode);
    }
}
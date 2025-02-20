*** Settings ***
Documentation       Odoo backend keywords.

Library             DateTime
Library             ../library/browser.py
Library             SeleniumLibrary
Resource            odoo_client.robot
Resource            tools.robot
Library             ../library/tools.py
Resource            styling.robot
Resource            highlighting.robot
Library             String    # example Random String


*** Keywords ***
_prepend_parent    [Arguments]    ${path}    ${parent}    ${css_parent}=${NONE}
    ${res}=    _prepend_parent_in_tools    path=${path}    parent=${parent}    css_parent=${css_parent}
    RETURN    ${res}

_LocatorACE    [Arguments]    ${fieldname}    ${parent}    ${css_parent}=${NONE}
    ${result}=    Set Variable    div.o_field_ace[name='${fieldname}'] div.ace_editor
    RETURN    ${result}

_LocatorSelect    [Arguments]    ${fieldname}    ${parent}    ${css_parent}=""
    ${result}=    Set Variable    div.o_field_selection[name='${fieldname}'] select
    RETURN    ${result}

_LocatorCheckboxes    [Arguments]    ${fieldname}    ${value}    ${parent}    ${css_parent}=${NONE}

    # V17 approved
    ${css}=    Set Variable
    ...    div[name='${fieldname}'] div.o-checkbox label
    RETURN    ${css}

_LocatorRadio    [Arguments]    ${fieldname}    ${value}    ${parent}    ${css_parent}=${NONE}

    # V17 approved
    ${css}=    Set Variable
    ...    div[name='${fieldname}'] div.o_radio_item label
    RETURN    ${css}

_LocatorBoolean    [Arguments]    ${fieldname}    ${parent}    ${css_parent}=
    ${css}=    Set Variable
    ...    div.o_field_boolean[name='${fieldname}'] input[type='checkbox']
    RETURN    ${css}

_LocatorInputAndM2O    [Arguments]    ${fieldname}    ${parent}    ${css_parent}=
    ${csss}=    Create List
    ...    div[name='${fieldname}'] input
    ...    div[name='${fieldname}'] textarea
    ...    input[id='${fieldname}']
    ...    input[id='${fieldname}_0']
    ...    input[name='${fieldname}']
    ...    textarea[id='${fieldname}']
    ...    textarea[id='${fieldname}_0']
    ...    textarea[name='${fieldname}']
    RETURN    ${csss}

Collect all css for inputs    [Arguments]    ${fieldname}    ${value}    ${parent}    ${css_parent}
    ${locator_ace}=    _LocatorACE    ${fieldname}    ${parent}    ${css_parent}
    ${locator_select}=    _LocatorSelect    ${fieldname}    ${parent}    ${css_parent}
    ${locator_checkboxes}=    _LocatorCheckboxes    ${fieldname}    ${value}    ${parent}    ${css_parent}
    ${locator_radio}=    _LocatorRadio    ${fieldname}    ${value}    ${parent}    ${css_parent}
    ${locator_boolean}=    _LocatorBoolean    ${fieldname}    ${parent}    ${css_parent}
    ${locator_input_and_m2o}=    _LocatorInputAndM2O    ${fieldname}    ${parent}    ${css_parent}

    ${locator_ace}=    _prepend_parent    ${locator_ace}    ${parent}    css_parent=${css_parent}
    ${locator_select}=    _prepend_parent    ${locator_select}    ${parent}    css_parent=${css_parent}
    ${locator_checkboxes}=    _prepend_parent    ${locator_checkboxes}    ${parent}    css_parent=${css_parent}
    ${locator_radio}=    _prepend_parent    ${locator_radio}    ${parent}    css_parent=${css_parent}
    ${locator_boolean}=    _prepend_parent    ${locator_boolean}    ${parent}    css_parent=${css_parent}
    ${locator_input_and_m2o}=    _prepend_parent    ${locator_input_and_m2o}    ${parent}    css_parent=${css_parent}

    ${locator_input_and_m2o}=    Eval    ",".join(v)    v=${locator_input_and_m2o}

    ${result}=    Create List
    ...    ${{ "boolean", "${locator_boolean}" }}
    ...    ${{ "many2many_checkboxes", "${locator_checkboxes}" }}
    ...    ${{ "select", "${locator_select}" }}
    ...    ${{ "radio", "${locator_radio}" }}
    ...    ${{ "ace", "${locator_ace}" }}
    ...    ${{ "input", "${locator_input_and_m2o}" }}
    RETURN    ${result}

Identify Input Type    [Arguments]    ${fieldname}    ${value}    ${parent}    ${css_parent}
    ${all_css_list}=    Collect all css for inputs    ${fieldname}    ${value}    ${parent}    ${css_parent}

    ${found}=    Search All Tabs For CSS    ${all_css_list}    ${css_parent}    ${value}
    ${found_key}=    Get From Dictionary    ${found}    key
    IF    "${found_key}" == "no match"
        FAIL    could not determine input for ${css_parent} ${parent} ${fieldname}
    END

    RETURN    ${found}

_ToggleRadio    [Arguments]    ${locator}
    Click Element    css=${locator}

_ToggleCheckbox    [Documentation]    If not force value is set, then value is toggled.
    [Arguments]    ${locator_checkbox_value}    ${force_value}=${NONE}

    ${doselect}=    Evaluate    True
    ${forcevalue_is_none}=    Eval    v is None    v=${force_value}
    ${forcevalue_as_bool}=    Eval Bool    ${force_value}
    ${forcevalue_is_false}=    Eval    not v    v=${forcevalue_as_bool}
    IF    ${forcevalue_is_none}
        ${status}=    Get Element Attribute    css=${locator_checkbox_value}    checked
        IF    '${status}' == 'true'
            ${doselect}=    Evaluate    False
        END
    ELSE IF    ${force_value_is_false}
        ${doselect}=    Evaluate    False
    END

    IF    ${doselect}
        Select Checkbox    css=${locator_checkbox_value}
    ELSE
        Unselect Checkbox    css=${locator_checkbox_value}
    END

_WriteSelect    [Arguments]    ${css}    ${fieldname}    ${value}    ${parent}    ${css_parent}=${NONE}    ${tooltip}=${NONE}

    Screenshot
    ${locator}=    _LocatorSelect    ${fieldname}    ${parent}    css_parent=${css_parent}
    IF    ${tooltip}
        ShowTooltip By Locator    ${locator}    tooltip=${tooltip}
    END
    Log    The select locator is ${locator}
    Select From List By Label    css=${locator}    ${value}
    Remove Tooltips

_WriteACEEditor    [Arguments]    ${locator}    ${value}    ${tooltip}

    # V17
    # <div name="field1" class="o_field_widget o_field_ace"
    ${js}=    Catenate    SEPARATOR=\n
    ...    let editor = ace.edit(document.querySelector(`${locator}`));
    ...    editor.focus();
    ...    editor.setValue(`${value}`, 1);
    ...    document.activeElement.blur();
    Execute Javascript    ${js}

_Write To Element    [Arguments]    ${css}    ${value}    ${ignore_auto_complete}=${NONE}

    ${element}=    Get WebElement    css=${css}
    ${tempid}=    Do Get Guid
    ${tempid}=    Set Variable    id${tempid}
    ${oldid}=    Get Element Attribute    ${element}    id
    IF    "${oldid}"
        Execute Javascript    document.querySelector('#' + CSS.escape('${oldid}')).setAttribute('id', '${tempid}');
    ELSE
        Set Element Attribute    ${css}    id    ${tempid}
    END
    ${oldcss}=    Set Variable    ${css}
    ${css}=    Set Variable    \#${tempid}
    ${testwebel}=    Get WebElement    css=${css}

    Highlight Element    ${css}    ${TRUE}
    IF    not ${ROBO_NO_UI_HIGHLIGHTING}    JS Scroll Into View    ${css}
    IF    not ${ROBO_NO_UI_HIGHLIGHTING}    Mouse Over    ${testwebel}

    ${elementid}=    Get Element Attribute    ${element}    id
    ${css}=    Set Variable    \#${elementid}

    ${libdir}=    library Directory

    ${klass}=    Get Element Attribute    ${element}    class
    ${is_autocomplete}=    Evaluate    "autocomplete" in "${klass}"    # works for V15 and V16 and V17

    # ${status}    ${error}=    Run Keyword And Ignore Error    Input Text    css=${css}    ${value}
    ${libdir}=    library Directory
    ${inputelement_js}=    Get File    ${libdir}/../keywords/js/inputelement.js
    ${inputelement_js}=    Catenate    SEPARATOR=\n
    ...    const css =`${css}`;
    ...    const value =`${value}`;
    ...    ${inputelement_js}
    ${status}=    Execute Async Javascript    ${inputelement_js}
    IF    not '${status}'
        FAIL    Could not write value to ${css}
        JS Scroll Into View    ${css}
    END
    IF    ${is_autocomplete} and not ${ignore_auto_complete}
        IF    ${ODOO_VERSION} <= 15.0
            ${arrow_down_event}=    Get File    ${libdir}/../keywords/js/events.js

            # Set value in combobox and press down cursor to select
            ${js}=    Catenate    SEPARATOR=;
            ...    ${arrow_down_event};
            ...    element.value = "${value}";
            ...    element.dispatchEvent(downArrowEvent);
            JS On Element    ${css}    ${js}
            # Wait until options appear
            Wait Until Page Contains Element
            ...    xpath=//ul[contains(@class, 'ui-autocomplete')][not(contains(@style, 'display: none;'))][not(//*[contains(@class, 'fa-spin')])]
            ${js}=    Catenate    SEPARATOR=;
            ...    ${arrow_down_event};
            ...    element.dispatchEvent(enterEvent);
            JS On Element    ${css}    ${js}
            Sleep    500ms    # required; needed to set element value
        ELSE
            _Write To CSS AutoComplete
        END
    END
    Highlight Element    ${css}    ${FALSE}

    # if element is part of editable tree, then it is recreated and not found;
    Run Keyword And Ignore Error    Set Element Attribute    ${css}    id    ${oldid}
    ${css}=    Set Variable    ${oldcss}

_blur_active_element    ${js}=    Catenate    SEPARATOR=\n
    ...    const callback = arguments[arguments.length-1]
    ...    document.activeElement ? document.activeElement.blur() : null
    ...    callback()
    Execute Async Javascript    ${js}

_Write To CSS AutoComplete
    Wait Blocking
    IF    ${odoo_version} == 16.0
        ${css}=    Catenate
        ...    ul.o-autocomplete--dropdown-menu.dropdown-menu:not(:has(.fa-spin)) li:first-child
        Wait To Click    css=${css}
    ELSE IF    ${odoo_version} == 17.0
        ${css}=    Catenate
        ...    ul.o-autocomplete--dropdown-menu[role="menu"]:not(:has(.fa-spin)) li:first-child a
        Wait To Click    css=${css}
    ELSE
        FAIL    needs implementation for ${odoo_version}
    END
    Wait Blocking

Wait Blocking
    ${start}=    tools.Get Current Time Ms
    # TODO something not ok here - if --timeout is 30 then this function
    # executes 20 times slower then with robot --timeout 10

    # o_loading in V14
    # o_loading_indicator since ??

    ${css}=    Set Variable    div.o_loading, span.o_loading_indicator, div.o_blockUI

    Wait Ajax Requests Done

    # Repeat Keyword
    # ...    2 times
    # ...    Run Keyword And Ignore Error
    # ...    Wait Until Element Is Not Visible    xpath=${xpath}    timeout=10ms

    # ${state}    ${result}=    Run Keyword And Ignore Error
    # ...    Wait Until Element Is Visible
    # ...    xpath=${xpath}    timeout=10ms

    ${state}    ${result}=    Run Keyword And Ignore Error
    ...    Wait Until Element Is Not Visible
    ...    css=${css}    timeout=10ms

    IF    ${odoo_version} < 17.0
        ${state}    ${result}=    Run Keyword And Ignore Error
        ...    Wait Until Element Is Not Visible
        ...    css=body.o_ewait    timeout=10ms
        IF    '${state}' == 'FAIL'    Log To Console    o_ewait still visible
    ELSE
        Wait Until Element Is Not Visible  css=${css}
    END
    ${elapsed}=    tools.Get Elapsed Time Ms    ${start}
    Log To Console    Wait Blocking Done in ${elapsed}ms

ElementPostCheck
    [Documentation]
    ...    Run Keyword And Expect Error    *invalid syntax*    Wait To Click    css=${css}
    Wait Blocking
    Eval JS Error Dialog
    Eval Validation User Error Dialog

Eval Validation User Error Dialog
    # TODO evaluate Validation Error and User Error again; best return text error immediatley
    ${js}=    Catenate    SEPARATOR=\n
    ...    let textcontent = element.textContent;
    ...    if (textcontent.includes("User Error") || textcontent.includes("Validation Error")) {
    ...    funcresult = "has_error_dialog";
    ...    }
    ${has_error_dialog}=    JS On Element    div.modal[role='dialog'] header    ${js}    return_callback=${TRUE}
    ${is_error_dialog}=    Evaluate    '${has_error_dialog}' == 'has_error_dialog'

    IF    ${is_error_dialog}
        ${js}=    Catenate    SEPARATOR=\n    funcresult = element.textContent;
        ${content}=    JS On Element    div.modal[role='dialog'] main.modal-body    ${js}    return_callback=${TRUE}
        FAIL    Popup-Window: ${content}
    END

Eval JS Error Dialog
    ${js}=    Catenate    SEPARATOR=\n
    ...    funcresult = "no_error_dialog";
    ...    if (element.textContent.includes("See details")) {
    ...    funcresult = "has_error_dialog";
    ...    }
    ...    callback(funcresult);
    ${has_error_dialog}=    JS On Element
    ...    div[role='alert'] button
    ...    ${js}
    ...    return_callback=${TRUE}

    IF    '${has_error_dialog}' == 'has_error_dialog'
        Click Element    xpath=//button[text() = 'See details']
        ${locator}=    Set Variable    div.o_error_detail pre
        ${code_content}=    Get Text    css=${locator}

        Log    ${code_content}
        Log To Console    Error dialog was shown
        JS On Element    ${locator}    element.scrollTop = element.scrollHeight;
        Screenshot

        FAIL    error dialog was shown - please check ${code_content}
    END

Search All Tabs For CSS    [Documentation]
    ...    returns bool true if found a parent tab;
    ...    The css variable must contain already the css parent and is a dict:
    ...    type: css    like {'input': '..input', 'ace': textarea[...]}; the
    ...    css parent itself is used to filter the notebook tabs of a modal dialog.
    [Arguments]    ${css}    ${css_parent}    ${value}
    IF    ${ODOO_VERSION} < 16.0
        ${mode}=    Set Variable    closest
    ELSE
        ${mode}=    Set Variable    clickall
    END
    ${path_notebook_header}=    Set Variable    div.oe_notebook_page li a,div.o_notebook_headers li a
    ${path_notebook_header}=    _prepend_parent
    ...    ${path_notebook_header}
    ...    parent=${NONE}
    ...    css_parent=${css_parent}

    ${css_json}=    tools.json_dumps    ${css}
    ${js}=    Get JS    search_all_tabs_for_css.js
    ...    append_js=identify_input_type("${mode}", `${css_json}`, `${path_notebook_header}`, `${value}`);

    # TODO undo next line
    # Set Selenium Timeout    300s
    ${result}=    Execute Async Javascript    ${js}
    RETURN    ${result}

_has_module_installed    [Arguments]    ${modulename}

    Log To Console    Checking ${modulename} installed
    ${modules}=    Odoo Search Records    ir.module.module    [('name', '=', "${modulename}")]
    ${length}=    Get Length    ${modules}
    IF    not ${length}
        Log To Console    Checking ${modulename} installed: False
        RETURN    ${False}
    END

    ${state}=    Eval    modules[0].state    modules=${modules}

    IF    '${state}' == 'installed'
        Log To Console    Checking ${modulename} installed: True
        RETURN    ${True}
    END

    Log To Console    Checking ${modulename} installed: False
    RETURN    ${False}

_While Element Attribute Value    [Arguments]    ${css}    ${attribute}    ${operator}    ${param_value}    ${conversion}=${None}

    Log To Console    While Element Attribute Value ${css} ${attribute} ${operator} ${param_value} ${conversion}

    IF    '${conversion}' == 'as_bool'
        ${param_value}=    Convert To Boolean    ${param_value}
    END
    ${started}=    Get Time    epoch

    ${timeout}=    Get Selenium Timeout

    WHILE    ${TRUE}
        ${end_time}=    Get Time    epoch
        ${elapsed_seconds}=    Evaluate    ${end_time} - ${started}
        IF    ${elapsed_seconds} > ${timeout}
            FAIL    Timeout ${timeout} waiting for button to become clickable hit.
        END
        ${status}    ${value}=    Run Keyword And Ignore Error
        ...    Get Element Attribute
        ...    css=${css}
        ...    ${attribute}
        IF    '${status}' == 'FAIL'
            # in V17 a newbutton is quickly gone and checking is not possible
            # decision to return False
            RETURN
        END
        # Log To Console    Waiting for ${xpath} ${attribute} ${operator} ${param_value} - got ${value}
        IF    '${conversion}' == 'as_bool'
            ${status}    ${integer_number}=    Run Keyword And Ignore Error    Convert To Integer    ${value}
            IF    '${status}' != 'FAIL'
                ${value}=    Set Variable    ${integer_number}
            END
            ${value}=    Convert To Boolean    ${value}
        END
        ${testcondition}=    Set Variable    '${value}' ${operator} '${param_value}'
        # Log To Console    ${testcondition}
        ${condition}=    Evaluate    ${testcondition}
        # Log To Console    ${condition}
        IF    ${condition}
            Sleep    0.2s
        ELSE
            Log To Console    Returning from While Element Attribute value
            RETURN
        END
    END
    Log To Console
    ...    Done: While Element Attribute Value ${css} ${attribute} ${operator} ${param_value} ${conversion}

_Wait Until Element Is Not Disabled    [Arguments]    ${css}

    _While Element Attribute Value    ${css}    disabled    ==    true    as_bool

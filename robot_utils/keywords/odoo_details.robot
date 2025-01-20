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

    ${result}=    Set Variable
    ...    div.o_field_ace[name='${fieldname}'] div.ace_editor
    ${result}=    _prepend_parent    ${result}    ${parent}    css_parent=${css_parent}
    RETURN    ${result}

_LocatorSelect    [Arguments]    ${fieldname}    ${parent}    ${css_parent}=""

    ${result}=    Set Variable
    ...    div.o_field_selection[name='${fieldname}'] select
    ${result}=    _prepend_parent    ${result}    ${parent}    css_parent=${css_parent}
    RETURN    ${result}

_WriteSelect    [Arguments]    ${fieldname}    ${value}    ${parent}    ${css_parent}=${NONE}    ${tooltip}=${NONE}

    Screenshot
    ${locator}=    _LocatorSelect    ${fieldname}    ${parent}    css_parent=${css_parent}
    IF    ${tooltip}
        ShowTooltip By Locator    ${locator}    tooltip=${tooltip}
    END
    Log    The select locator is ${locator}
    Select From List By Label    css=${locator}    ${value}
    Remove Tooltips

_WriteACEEditor    [Arguments]    ${fieldname}    ${value}    ${parent}    ${css_parent}    ${tooltip}

    # V17
    # <div name="field1" class="o_field_widget o_field_ace"
    ${locator}=    _LocatorACE    ${fieldname}    ${parent}    ${css_parent}
    ${origId}=    Get Element Attribute    css=${locator}    id
    ${tempId}=    Generate Random String    8

    IF    ${tooltip}
        ShowTooltip By Locator    ${locator}    tooltip=${tooltip}
    END

    Assign Id To Element    css=${locator}    id=${tempId}
    ${js}=    Catenate
    ...    const callback = arguments[arguments.length - 1];
    ...    var editor = ace.edit(document.getElementById("${tempId}"));
    ...    editor.focus();
    ...    editor.setValue(`${value}`, 1);
    ...    document.activeElement.blur();
    ...    callback();
    Screenshot
    Execute Async Javascript    ${js}
    Assign Id To Element    css=${locator}    id=${origId}
    Remove Tooltips
    Screenshot

_Write To Element    [Arguments]    ${element}    ${value}    ${ignore_auto_complete}=False
    ${start}=    tools.Get Current Time Ms

    ${elementid}=    Get Element Attribute    ${element}    id
    ${css}=    Set Variable    \#${elementid}

    ${libdir}=    library Directory

    ${elapsed}=    tools.Get Elapsed Time Ms    ${start}
    Log To Console    _Write To Element A ${elapsed}ms

    ${elapsed}=    tools.Get Elapsed Time Ms    ${start}
    Log To Console    _Write To Element C ${elapsed}ms

    ${klass}=    Get Element Attribute    ${element}    class
    ${is_autocomplete}=    Evaluate    "autocomplete" in "${klass}"    # works for V15 and V16 and V17
    ${elapsed}=    tools.Get Elapsed Time Ms    ${start}
    Log To Console    _Write To Element C.1 ${elapsed}ms

    # ${status}    ${error}=    Run Keyword And Ignore Error    Input Text    css=${css}    ${value}
    ${libdir}=    library Directory
    ${inputelement_js}=    Get File    ${libdir}/../keywords/js/inputelement.js
    ${inputelement_js}=    Catenate    SEPARATOR=\n
    ...    const css =`${css}`;
    ...    const value =`${value}`;
    ...    ${inputelement_js}
    ${status}=    Execute Async Javascript    ${inputelement_js}
    ${elapsed}=    tools.Get Elapsed Time Ms    ${start}
    Log To Console    _Write To Element D ${elapsed}ms
    IF    not '${status}'
        Log To Console    Could not regularly insert text to ${css} - trying to scroll into view first
        FAIL    Could not write value to ${css} ${value}
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
    ${elapsed}=    tools.Get Elapsed Time Ms    ${start}
    Log To Console    _Write To Element E ${elapsed}ms

    ${elapsed}=    tools.Get Elapsed Time Ms    ${start}
    Log To Console    _Write To Element DONE ${elapsed}ms

_Write To Element 15smaller    [Arguments]
    ...    ${element}
    ...    ${is_autocomplete}
    ...    ${ignore_auto_complete}
    ...    ${arrow_down_event}
    ...    ${js}
    ...    ${css}
    ...    ${value}
    ${libdir}=    library Directory
    IF    ${is_autocomplete} and not ${ignore_auto_complete}
    ELSE
        Set Focus To Element    ${element}
        Input Text    ${css}    ${value}
        _blur_active_element
    END

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

    ${counter_ajax}=  Get Ajax Counter
    WHILE  ${counter_ajax} > 0
        Sleep  0.1s
        ${counter_ajax}=  Get Ajax Counter
    END

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

    # TODO dont know when introduced
    IF    ${odoo_version} < 17.0
        ${state}    ${result}=    Run Keyword And Ignore Error
        ...    Wait Until Element Is Not Visible
        ...    css=body.o_ewait    timeout=10ms
        IF    '${state}' == 'FAIL'    Log To Console    o_ewait still visible
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
    ${is_error_dialog}=  Evaluate  '${has_error_dialog}' == 'has_error_dialog'

    IF    ${is_error_dialog}
        ${js}=    Catenate    SEPARATOR=\n    funcresult = element.textContent;
        ${content}=    JS On Element    div.modal[role='dialog'] main.modal-body    ${js}    return_callback=${TRUE}
        FAIL    Popup-Window: ${content}
    END

Eval JS Error Dialog
    ${js}=    Catenate    SEPARATOR=\n
    ...    if (element.textContent.includes("See details")) {
    ...    funcresult = "has_error_dialog";
    ...    } callback(true);
    ${has_error_dialog}    ${msg}=    Run Keyword And Ignore Error
    ...    JS On Element
    ...    div[role='alert'] button
    ...    ${js}

    IF    '${has_error_dialog}' != 'FAIL'
        Click Element    xpath=//button[text() = 'See details']
        ${locator}=    Set Variable    div.o_error_detail pre
        ${code_content}=    Get Text    css=${locator}

        Log    ${code_content}
        Log To Console    Error dialog was shown
        JS On Element    ${locator}    element.scrollTop = element.scrollHeight;
        Screenshot

        FAIL    error dialog was shown - please check ${code_content}
    END

ElementPreCheck    [Arguments]    ${css}
    ${start}=    tools.Get Current Time Ms
    Wait Blocking
    IF    ${ODOO_VERSION} < 16.0
        ${mode}=    Set Variable    closest
    ELSE
        ${mode}=    Set Variable    clickall
    END

    ${js}=    Get JS    element_precheck.js
    ...    const mode="${mode}"; const css=`${css}`;

    Execute Async Javascript    ${js}
    ${elapsed}=    tools.Get Elapsed Time Ms    ${start}
    Log2    Done: Element Precheck ${css} done in ${elapsed}ms

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

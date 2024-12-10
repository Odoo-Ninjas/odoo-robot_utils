*** Settings ***
Documentation    Odoo backend keywords.

Library     DateTime
Library     ../library/browser.py
Library     SeleniumLibrary
Resource    odoo_client.robot
Resource    tools.robot
Library     ../library/tools.py
Resource    styling.robot
Library     String                   # example Random String


*** Keywords ***
_prepend_parent    [Arguments]          ${path}                ${parent}
    # Check if path is a list
                   ${is_list}=          Is List                ${path}
                   ${is_parent_set}=    Is Not Empty String    ${parent}

    IF    ${is_list}
        ${new_path}=    Create List
        FOR    ${item}    IN    @{path}
            IF    ${is_parent_set}
                ${item}=    Set Variable    ${parent}${item}
            END
            Append To List    ${new_path}    ${item}
        END
        ${path}=    Set Variable    ${new_path}
    ELSE
        IF    ${is_parent_set}
            ${path}=    Set Variable    ${parent}${path}
        END
    END
    RETURN    ${path}

_LocatorACE    [Arguments]    ${fieldname}    ${parent}

    ${result}=    Set Variable
    ...           xpath=//div[@name='${fieldname}' and contains(@class, 'o_field_ace')]//div[contains(@class, 'ace_editor')]
    ${result}=    _prepend_parent                                                                                               ${result}    ${parent}
    RETURN        ${result}

_LocatorSelect    [Arguments]    ${fieldname}    ${parent}

    ${result}=    Set Variable
    ...           xpath=//div[@name='${fieldname}' and contains(@class, 'o_field_selection')]//select
    ${result}=    _prepend_parent                                                                        ${result}    ${parent}
    RETURN        ${result}

_WriteSelect    [Arguments]    ${fieldname}    ${value}    ${parent}

    Screenshot
    ${locator}=                  _LocatorSelect                      ${fieldname}    ${parent}
    Log                          The select locator is ${locator}
    Select From List By Label    ${locator}                          ${value}
    Screenshot

_WriteACEEditor    [Arguments]    ${fieldname}    ${value}    ${parent}

    # V17
    # <div name="field1" class="o_field_widget o_field_ace"
    ${locator}=                 _LocatorACE                                                     ${fieldname}    ${parent}
    ${origId}=                  Get Element Attribute                                           ${locator}      id
    ${tempId}=                  Generate Random String                                          8
    Assign Id To Element        locator=${locator}                                              id=${tempId}
    ${js}=                      Catenate
    ...                         const callback = arguments[arguments.length - 1];
    ...                         var editor = ace.edit(document.getElementById("${tempId}"));
    ...                         editor.focus();
    ...                         editor.setValue(`${value}`, 1);
    ...                         document.activeElement.blur();
    ...                         callback();
    Screenshot
    Execute Async Javascript    ${js}
    Assign Id To Element        locator=${locator}                                              id=${origId}
    Screenshot

_Write To Xpath    [Arguments]    ${xpath}    ${value}    ${ignore_auto_complete}=False

    ${libdir}=                       library Directory
    Log2    _Write To XPath called with ${xpath} ${value} ${ignore_auto_complete}
    ElementPreCheck                  xpath=${xpath}
    Wait Until Element Is Visible    xpath=${xpath}
    ${klass}=                        Get Element Attribute    xpath=${xpath}                  class
    ${is_autocomplete}=              Evaluate                 "autocomplete" in "${klass}"    # works for V15 and V16 and V17
    ${element}=                      Get WebElement           xpath=${xpath}

    Capture Page Screenshot
    JS Scroll Into View  ${xpath}
    IF    ${odoo_version} <= 15.0
        Set Focus To Element       xpath=${xpath}
        Capture Page Screenshot
        IF    ${is_autocomplete} and not ${ignore_auto_complete}
            ${arrow_down_event}=    Get File    ${libdir}/../keywords/js/events.js

            # Set value in combobox and press down cursor to select
            ${js}=                              Catenate                                                                                                                           SEPARATOR=;
            ...                                 ${arrow_down_event};
            ...                                 element.value = "${value}";
            ...                                 element.dispatchEvent(downArrowEvent);
            JS On Element                       ${xpath}                                                                                                                           ${js}
            Capture Page Screenshot
            # Wait until options appear
            Wait Until Page Contains Element
            ...                                 xpath=//ul[contains(@class, 'ui-autocomplete')][not(contains(@style, 'display: none;'))][not(//*[contains(@class, 'fa-spin')])]
            Capture Page Screenshot

            ${js}=                     Catenate                              SEPARATOR=;
            ...                        ${arrow_down_event};
            ...                        element.dispatchEvent(enterEvent);
            JS On Element              ${xpath}                              ${js}
            Sleep                      500ms                                 # required; needed to set element value
            Capture Page Screenshot
        ELSE
            Set Focus To Element    xpath=${xpath}
            Input Text              ${xpath}          ${value}
            _blur_active_element
        END
    ELSE
        ${status}    ${error}=    Run Keyword And Ignore Error    Input Text    ${xpath}    ${value}
        IF    '${status}' == 'FAIL'
            Log To Console    Could not regularly insert text to ${xpath} - trying to scroll into view first
            JS Scroll Into View     ${xpath}
            Set Focus To Element    xpath=${xpath}
            Input Text              xpath=${xpath}    ${value}
        END
        IF    ${is_autocomplete} and not ${ignore_auto_complete}
            _Write To XPath AutoComplete
        END
        # Try to blur to show save button
        _blur_active_element

    END

    Capture Page Screenshot

    ElementPostCheck

_blur_active_element    ${js}=    Catenate    SEPARATOR=;

    ...                         const callback = arguments[arguments.length-1]
    ...                         document.activeElement ? document.activeElement.blur() : null
    ...                         callback()
    Execute Async Javascript    ${js}

_Write To XPath AutoComplete
    Wait Blocking
    IF    ${odoo_version} == 16.0
        ${xpath}=        Catenate
        ...              //ul[contains(@class, 'o-autocomplete--dropdown-menu dropdown-menu')][not(//*[contains(@class, 'fa-spin')])]
        Wait To Click    xpath=${xpath}/li[1]
    ELSE IF    ${odoo_version} == 17.0
        ${xpath}=        Catenate
        ...              //ul[@role='menu' and contains(@class, 'o-autocomplete--dropdown-menu')][not(//*[contains(@class, 'fa-spin')])]
        Wait To Click    xpath=${xpath}/li[1]/a
    ELSE
        FAIL    needs implementation for ${odoo_version}
    END
    Wait Blocking

Wait Blocking
    Log To Console    Wait Blocking
    # TODO something not ok here - if --timeout is 30 then this function
    # executes 20 times slower then with robot --timeout 10

    # o_loading in V14
    # o_loading_indicator since ??

    ${xpath}=    Catenate
    ...          (
    ...          //div[contains(@class, 'o_loading')] |
    ...          //span[contains(@class, 'o_loading_indicator')] |
    ...          //div[contains(@class, 'o_blockUI')]
    ...          )

    Repeat Keyword
    ...               10 times
    ...               Run Keyword And Ignore Error
    ...               Wait Until Element Is Not Visible
    ...               xpath=${xpath}

    ${state}    ${result}=                           Run Keyword And Ignore Error
    ...         Wait Until Element Is Not Visible
    ...         xpath=${xpath}

    IF    '${state}' == 'FAIL'
        Log To Console    Blocker/loading still visible after 10 checks
    END
    ${state}    ${result}=                                   Run Keyword And Ignore Error
    ...         Wait Until Element Is Not Visible
    ...         xpath=//body[contains(@class, 'o_ewait')]
    IF    '${state}' == 'FAIL'
        Log To Console    o_ewait still visible
    END
    Log To Console             Wait Blocking Done
    Capture Page Screenshot

ElementPostCheck
    Wait Blocking
    Screenshot
    Eval JS Error Dialog
    Eval Validation User Error Dialog

Eval Validation User Error Dialog
    ${locator}=    Set Variable    //div[@role='dialog'][contains(@class, 'modal')][//*[contains(text(), 'Validation Error') or contains(text(), 'User Error')]]
    ${visible}=    Is Visible      xpath=${locator}

    IF    ${visible}
        ${content}=    Get Text                    xpath=${locator}//*[contains(@class, 'modal-body')]
        FAIL           Popup-Window: ${content}
    END

Eval JS Error Dialog
    ${locator}=    Set Variable                     //div[@role='alert'][//button[text() = 'See details']]
    ${status}=     Run Keyword And Return Status    Get WebElement                                            xpath=${locator}
    Log            ${status}
    IF    ${status}
        Click Element      xpath=//button[text() = 'See details']
        Screenshot
        ${locator}=        Set Variable                              //div[contains(@class, 'o_error_detail')]
        ${code_content}    Get Text                                  xpath=${locator}/pre


        Log               ${code_content}
        Log To Console    Error dialog was shown
        JS On Element     ${locator}                element.scrollTop = element.scrollHeight;
        Screenshot

        FAIL    error dialog was shown - please check ${code_content}
    END


ElementPreCheck    [Arguments]    ${element}

    Log2                        Element Precheck ${element}
    Wait Blocking
    # Element may be in a tab. So click the parent tab. If there is no parent tab, forget about the result
    # not verified for V16 yet with tabs
    ${code}=                    Catenate
    ...                         const callback = arguments[arguments.length - 1];
    ...                         var path="${element}".replace('xpath=','');
    ...                         var id=document.evaluate("("+path+")/ancestor::div[contains(@class,'oe_notebook_page')]/@id"
    ...                         ,document,null,XPathResult.STRING_TYPE,null).stringValue;
    ...                         if (id != ''){
    ...                         window.location = "#"+id;
    ...                         $("a[href='#"+id+"']").click();
    ...                         console.log("Clicked at #" + id);
    ...                         }
    ...                         callback();
    ...                         return true;
    Execute Async Javascript    ${code}
    Wait Blocking
    Log2                        Done: Element Precheck ${element}

_has_module_installed    [Arguments]    ${modulename}

    Log To Console    Checking ${modulename} installed
    ${modules}=       Odoo Search Records                 ir.module.module    [('name', '=', "${modulename}")]
    ${length}=        Get Length                          ${modules}
    IF    not ${length}
        Log To Console    Checking ${modulename} installed: False
        RETURN            ${False}
    END

    ${state}=    Eval    modules[0].state    modules=${modules}

    IF    '${state}' == 'installed'
        Log To Console    Checking ${modulename} installed: True
        RETURN            ${True}
    END

    Log To Console    Checking ${modulename} installed: False
    RETURN            ${False}

_While Element Attribute Value    [Arguments]    ${xpath}    ${attribute}    ${operator}    ${param_value}    ${conversion}=${None}

    Log To Console    While Element Attribute Value ${xpath} ${attribute} ${operator} ${param_value} ${conversion}

    IF    '${conversion}' == 'as_bool'
        ${param_value}=    Convert To Boolean    ${param_value}
    END
    ${started}=    Get Time    epoch

    ${timeout}=    Get Selenium Timeout

    WHILE    ${TRUE}
        ${end_time}=           Get Time    epoch
        ${elapsed_seconds}=    Evaluate    ${end_time} - ${started}
        IF    ${elapsed_seconds} > ${timeout}
            FAIL    Timeout ${timeout} waiting for button to become clickable hit.
        END
        ${status}    ${value}=                Run Keyword And Ignore Error
        ...          Get Element Attribute
        ...          xpath=${xpath}
        ...          ${attribute}
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
        ${condition}=        Evaluate        ${testcondition}
        # Log To Console    ${condition}
        IF    ${condition}
            Sleep    0.2s
        ELSE
            Log To Console    Returning from While Element Attribute value
            RETURN
        END
    END
    Log To Console
    ...               Done: While Element Attribute Value ${xpath} ${attribute} ${operator} ${param_value} ${conversion}

_Wait Until Element Is Not Disabled    [Arguments]    ${xpath}

    _While Element Attribute Value    ${xpath}    disabled    ==    true    as_bool


_highlight_element    [Arguments]    ${xpath}    ${toggle}=${TRUE}

    ${content}=    Get File    /opt/src/addons_robot/robot_utils/keywords/js/highlight_element.js
    ${strtoggle}=    Eval                                                 '1' if v else '0'    v=${toggle}
    ${js}=           Catenate                                             SEPARATOR=\n
    ...              const xpath = "${xpath}";
    ...              const toggle = "${strtoggle}";
    ...              const callback = arguments[arguments.length - 1];
    ...              ${content};
    ...              highlightElementByXPath(xpath, toggle);
    ...              callback(xpath);
    Log              xpath is ${xpath}
    Log              ${js}
    ${res}=          Execute Async Javascript                             ${js}
    Log              ${res}


_showTooltipByXPath    [Arguments]    ${xpath}    ${tooltip}

    ${content}=
    ...                         Get File
    ...                         /opt/src/addons_robot/robot_utils/keywords/js/highlight_element.js
    ${js}=                      Catenate                                                              SEPARATOR=\n
    ...                         const xpath = "${xpath}";
    ...                         const toggle = "${strtoggle}";
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content}
    ...                         showTooltipByXPath(xpath, tooltip);
    ...                         callback();
    Execute Async Javascript    ${js}
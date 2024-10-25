*** Settings ***

Documentation   Odoo backend keywords.
Library         ../library/browser.py
Library         SeleniumLibrary
Resource        odoo_client.robot
Resource        tools.robot
Library         ../library/tools.py
Resource        styling.robot
Library         String  # example Random String

*** Keywords ***

_LocatorACE  [Arguments]  ${fieldname}
	RETURN  xpath=//div[@name='${fieldname}' and contains(@class, 'o_field_ace')]//div[contains(@class, 'ace_editor')]

_WriteACEEditor              [Arguments]     ${fieldname}    ${value}
    # V17
    # <div name="field1" class="o_field_widget o_field_ace"
    ${locator}=             _LocatorACE  ${fieldname}
    ${origId} =             Get Element Attribute    ${locator}  id
    ${tempId} =             Generate Random String    8
    Assign Id To Element    locator=${locator}    id=${tempId}
    ${js}=                  Catenate  
    ...                     const callback = arguments[arguments.length - 1];
    ...                     var editor = ace.edit(document.getElementById("${tempId}")); 
    ...                     editor.focus();
    ...                     editor.setValue(`${value}`, 1); 
    ...                     document.activeElement.blur();
    ...                     callback();
    Screenshot
    Execute Async Javascript  ${js}
    Assign Id To Element    locator=${locator}    id=${origId}
    Screenshot


_Write To Xpath           [Arguments]     ${xpath}    ${value}  ${ignore_auto_complete}=False
    Log To Console                     _Write To XPath called with ${xpath} ${value} ${ignore_auto_complete}
    ElementPreCheck                    xpath=${xpath}
    Wait Until Element Is Visible       xpath=${xpath}


    ${status}  ${error}=  Run Keyword And Ignore Error  Input Text              xpath=${xpath}  ${value}
    IF  '${status}' == 'FAIL'
        Log To Console    Could not regularly insert text to ${xpath} - trying to scroll into view first

        ${element}=    Get WebElement    xpath=${xpath}
        Execute Async JavaScript    const callback = arguments[arguments.length - 1]; arguments[0].scrollIntoView(true); callback();   ${element}

        Set Focus To Element        xpath=${xpath}
        Input Text                  xpath=${xpath}  ${value}

    END


    ${klass}=    Get Element Attribute   xpath=${xpath}  class
    ${is_autocomplete}=   Evaluate    "o-autocomplete--input" in "${klass}"  
    IF  ${is_autocomplete} and not ${ignore_auto_complete}
        Wait Blocking
        IF  ${odoo_version} == 16.0
            ${xpath}=                       Set Variable    //ul[contains(@class, 'o-autocomplete--dropdown-menu dropdown-menu')]
            Wait To Click                   xpath=${xpath}/li[1]
        ELSE IF  ${odoo_version} == 17.0
            ${xpath}=                       Set Variable    //ul[@role='menu' and contains(@class, 'o-autocomplete--dropdown-menu')]  
            Wait To Click                   xpath=${xpath}/li[1]/a
        ELSE
            FAIL  needs implementation for ${odoo_version}
        END
        Wait Blocking
    END

    # Try to blur to show save button
    Screenshot
    Execute Async Javascript  const callback = arguments[arguments.length-1];document.activeElement ? document.activeElement.blur() : null; callback();

    # Close Error Dialog And Log
    Screenshot

    ElementPostCheck

Wait Blocking
    Log To Console                       Wait Blocking
    # TODO something not ok here - if --timeout is 30 then this function
    # executes 20 times slower then with robot --timeout 10
    Repeat Keyword  10 times    Run Keyword And Ignore Error     Wait Until Element Is Not Visible   xpath=//span[contains(@class, 'o_loading_indicator')]

    ${state}  ${result}=  Run Keyword And Ignore Error     Wait Until Element Is Not Visible   xpath=//div[contains(@class, 'o_blockUI')]  
    IF  '${state}' == 'FAIL'
        Log To Console  o_blockUI still visible
    END

    ${state}  ${result}=  Run Keyword And Ignore Error     Wait Until Element Is Not Visible   xpath=//body[contains(@class, 'o_loading')]
    IF  '${state}' == 'FAIL'
        Log To Console  o_loading still visible
    END

    ${state}  ${result}=  Run Keyword And Ignore Error     Wait Until Element Is Not Visible   xpath=//body[contains(@class, 'o_ewait')]
    IF  '${state}' == 'FAIL'
        Log To Console  o_ewait still visible
    END
    Log To Console                       Wait Blocking Done

ElementPostCheck
    Wait Blocking
    Screenshot

ElementPreCheck    [Arguments]    ${element}
    Log To Console              Element Precheck ${element}
    Wait Blocking
    # Element may be in a tab. So click the parent tab. If there is no parent tab, forget about the result
    # not verified for V16 yet with tabs
    ${code}=                Catenate 
    ...    const callback = arguments[arguments.length - 1];
    ...    var path="${element}".replace('xpath=','');
    ...    var id=document.evaluate("("+path+")/ancestor::div[contains(@class,'oe_notebook_page')]/@id"
    ...        ,document,null,XPathResult.STRING_TYPE,null).stringValue;
    ...    if (id != ''){
    ...        window.location = "#"+id;
    ...        $("a[href='#"+id+"']").click();
    ...        console.log("Clicked at #" + id);
    ...    }
    ...    callback();
    ...    return true;
    Execute Async Javascript       ${code}
    Wait Blocking
    Log To Console              Done: Element Precheck ${element}


_has_module_installed  [Arguments]  ${modulename}
    Log To Console  Checking ${modulename} installed
    ${modules}=  Odoo Search Records  ir.module.module  [('name', '=', "${modulename}")]
    ${length}=   Get Length  ${modules}
    IF  not ${length}
        Log To Console  Checking ${modulename} installed: False
        RETURN  ${False}
    END

    ${state}=  Evaluate  ${modules}[0].state

    IF  '${state}' == 'installed'
        Log To Console  Checking ${modulename} installed: True
        RETURN  ${True}
    END

    Log To Console  Checking ${modulename} installed: False
    RETURN  ${False}


_While Element Attribute Value  [Arguments]  ${xpath}  ${attribute}  ${operator}  ${param_value}  ${conversion}=${None}
    Log To Console  While Element Attribute Value ${xpath} ${attribute} ${operator} ${param_value} ${conversion}

    IF  '${conversion}' == 'as_bool'
        ${param_value}=  Convert To Boolean  ${param_value}
    END
    WHILE  ${TRUE}
        ${status}  ${value}=  Run Keyword And Ignore Error  Get Element Attribute  xpath=${xpath}  ${attribute}
        IF  '${status}' == 'FAIL'
            # in V17 a newbutton is quickly gone and checking is not possible
            # decision to return False
            RETURN 
        END
        # Log To Console  Waiting for ${xpath} ${attribute} ${operator} ${param_value} - got ${value}
        IF  '${conversion}' == 'as_bool'
            ${status}    ${integer_number}=    Run Keyword And Ignore Error  Convert To Integer    ${value}
            IF  '${status}' != 'FAIL'
                ${value}=    Set Variable  ${integer_number}
            END
            ${value}=  Convert To Boolean  ${value}
        END
        ${testcondition}=  Set Variable  '${value}' ${operator} '${param_value}'
        # Log To Console  ${testcondition}
        ${condition}=  Evaluate  ${testcondition}
        # Log To Console  ${condition}
        IF  ${condition}
            Sleep  0.2s
        ELSE
            Log To Console  Returning from While Element Attribute value
            RETURN
        END
    END
    Log To Console  Done: While Element Attribute Value ${xpath} ${attribute} ${operator} ${param_value} ${conversion}

_Wait Until Element Is Not Disabled  [Arguments]  ${xpath}
    _While Element Attribute Value  ${xpath}  disabled  ==  true  as_bool

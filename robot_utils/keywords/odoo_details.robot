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
    ...                     var editor = ace.edit(document.getElementById("${tempId}")); 
    ...                     editor.focus();
    ...                     editor.setValue(`${value}`, 1); 
    ...                     document.activeElement.blur();
    Screenshot
    Execute Javascript      ${js}
    Assign Id To Element    locator=${locator}    id=${origId}
    Screenshot


_Write To Xpath           [Arguments]     ${xpath}    ${value}
    ElementPreCheck                    xpath=${xpath}
    Wait Until Element Is Visible       xpath=${xpath}
    

    ${status}  ${error}=  Run Keyword And Ignore Error  Input Text              xpath=${xpath}  ${value}
    IF  '${status}' == 'FAIL'
        Log To Console    Could not regularly insert text to ${xpath} - trying to scroll into view first

        ${element}=    Get WebElement    xpath=${xpath}
        Execute JavaScript    arguments[0].scrollIntoView(true);    ${element}

        Input Text  xpath=${xpath}  ${value}

    END


    ${klass}=    Get Element Attribute   xpath=${xpath}  class
    ${is_autocomplete}=   Evaluate    "o-autocomplete--input" in "${klass}"  
    IF  ${is_autocomplete}
        IF  ${odoo_version} == 16.0
            ${xpath}=                       Set Variable    //ul[contains(@class, 'o-autocomplete--dropdown-menu dropdown-menu')]
            Wait To Click                   xpath=${xpath}/li[1]
        ELSE IF  ${odoo_version} == 17.0
            ${xpath}=                       Set Variable    //ul[@role='menu' and contains(@class, 'o-autocomplete--dropdown-menu')]  
            Wait To Click                   xpath=${xpath}/li[1]
        ELSE
            FAIL  needs implementation for ${odoo_version}
        END
        # sometimes 
        Sleep  1s
    END

    # Try to blur to show save button
    Execute Javascript  document.activeElement ? document.activeElement.blur() : null;

    # Close Error Dialog And Log
    Screenshot

    ElementPostCheck

Wait Blocking
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

ElementPostCheck
    Wait Blocking
    Screenshot

ElementPreCheck    [Arguments]    ${element}
    Wait Blocking
    Execute Javascript      console.log("${element}");
    # Element may be in a tab. So click the parent tab. If there is no parent tab, forget about the result
    # not verified for V16 yet with tabs
    ${code}=                Catenate 
    ...    var path="${element}".replace('xpath=','');
    ...    var id=document.evaluate("("+path+")/ancestor::div[contains(@class,'oe_notebook_page')]/@id"
    ...        ,document,null,XPathResult.STRING_TYPE,null).stringValue;
    ...    if (id != ''){
    ...        window.location = "#"+id;
    ...        $("a[href='#"+id+"']").click();
    ...        console.log("Clicked at #" + id);
    ...    }
    ...    return true;
    Execute Javascript       ${code}
    Wait Blocking


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


_While Element Attribute Value  [Arguments]  ${xpath}  ${attribute}  ${operator}  ${param_value}
    ${value}=  Get Element Attribute  xpath=${xpath}  ${attribute}
    WHILE  '${value}' ${operator} '${param_value}'
        Sleep  0.2s
        ${value}=  Get Element Attribute  xpath=${xpath}  ${attribute}
    END

_Wait Until Element Is Not Disabled  [Arguments]  ${xpath}
    _While Element Attribute Value  ${xpath}  disabled  ==  1
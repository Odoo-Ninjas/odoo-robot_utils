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
    Execute Javascript         var editor = ace.edit(document.getElementById("${tempId}")); editor.setValue(`${value}`, 1);
    Assign Id To Element    locator=${locator}    id=${origId}


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
            Wait Until Element Is Visible   xpath=${xpath}
            Click Element                   xpath=${xpath}/li[1]
        ELSE IF  ${odoo_version} == 17.0
            ${xpath}=                       Set Variable    //ul[@role='menu' and contains(@class, 'o-autocomplete--dropdown-menu')]  
            Wait Until Element Is Visible   xpath=${xpath}
            Click Element                   xpath=${xpath}/li[1]
        ELSE
            FAIL  needs implementation for ${odoo_version}
        END
    END

    # Close Error Dialog And Log
    Capture Page Screenshot

    ElementPostCheck

ElementPostCheck
    # Check that page is not loading
    Run Keyword And Ignore Error     Wait Until Page Contains Element    xpath=//body[not(contains(@class, 'o_loading'))]
    # Check that page is not blocked by RPC Call
    Run Keyword And Ignore Error     Wait Until Page Contains Element    xpath=//body[not(contains(@class, 'o_ewait'))]

    Run Keyword And Ignore Error     Wait Until Page Contains Element    xpath=//body[not(contains(@class, 'o_blockUI'))]
    # Check not AJAX request remaining (only longpolling)
    Run Keyword And Ignore Error     Wait For Ajax    1

ElementPreCheck    [Arguments]    ${element}
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

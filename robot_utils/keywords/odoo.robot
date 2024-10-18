*** Settings ***

Documentation   Odoo 13 backend keywords.
Library         ../../robot_utils_common/library/browser.py
Library         SeleniumLibrary
# Resource        ../../robot_utils/keywords/odoo_community_unverified.robot
Resource        ../../robot_utils_common/keywords/odoo_client.robot
Resource        ../../robot_utils_common/keywords/tools.robot
Library         ../../robot_utils_common/library/tools.py
Resource        ../../robot_utils_common/keywords/styling.robot
Library         String  # example Random String

*** Variables ***


*** Keywords ***


Login   [Arguments]     ${user}=${ODOO_USER}    ${password}=${ODOO_PASSWORD}    ${url}=${ODOO_URL}/web/login
    ${browser_id}=                          Open New Browser       ${url}
    # Run Keyword and Ignore error            Click element   //a[@href="/web/login"]
    Capture Page Screenshot
    Wait Until Element is Visible           name=login
    Log To Console                          Input is visible, now entering credentials for user ${user} with password ${password} 
    Input Text                              xpath=//input[@name='login'][1]    ${user}
    Input Text                              xpath=//input[@name='password'][1]    ${password}
    Log To Console                          Clicking Login
    Capture Page Screenshot
    Click Button                            xpath=//form[@class='oe_login_form']//button[@type='submit']
    Log To Console                          Clicked login button - waiting
    Capture Page Screenshot
    Wait Until Page Contains Element        xpath=//span[contains(@class, 'oe_topbar_name')]	timeout=${SELENIUM_TIMEOUT}
    ElementPostCheck
    Log To Console                          Logged In - continuing
    [return]    ${browser_id}

DatabaseConnect    [Arguments]    ${db}=${db}    ${odoo_db_user}=${ODOO_DB_USER}    ${odoo_db_password}=${ODOO_DB_PASSWORD}    ${odoo_db_server}=${SERVER}    ${odoo_db_port}=${ODOO_DB_PORT}
		Connect To Database Using Custom Params	psycopg2        database='${db}',user='${odoo_db_user}',password='${odoo_db_password}',host='${odoo_db_server}',port=${odoo_db_port}

ClickMenu    [Arguments]	${menu}
    # works V16
    Log To Console     Clicking menu ${menu}
    ${xpath}=   Set Variable  //a[@data-menu-xmlid='${menu}'] | //button[@data-menu-xmlid='${menu}']
    Wait Until Element is visible       xpath=${xpath} 
	Click Element	xpath=${xpath}
	Wait Until Page Contains Element	xpath=//body[contains(@class, 'o_web_client')]
	ElementPostCheck
	sleep   1


MainMenu	[Arguments]	${menu}
    # works V16
    Wait Until Element is visible       xpath=//div[contains(@class, "o_navbar_apps_menu")]
    Click Element                        xpath=//div[contains(@class, "o_navbar_apps_menu")]/button
    Wait Until Element is visible       xpath=//a[@data-menu-xmlid='${menu}']
	Click Link	xpath=//a[@data-menu-xmlid='${menu}']
	Wait Until Page Contains Element	xpath=//body[contains(@class, 'o_web_client')]
	ElementPostCheck
	sleep   1

ApplicationMainMenuOverview
    
    Wait Until Element is visible       xpath=//div[contains(@class, "o_main_navbar")]
    Click Element                        xpath=//div[contains(@class, "o_main_navbar")]/button
    Wait Until Page Contains Element	xpath=//body[contains(@class, 'o_web_client')]
	ElementPostCheck

Is Visible  [Arguments]  ${xpath}
    ${is_visible}=    Run Keyword And Return Status    Wait Until Element Is Visible    xpath=${xpath}   
    [Return]  ${is_visible}

Close Error Dialog And Log
    ${visible_js_error_dialog}=  Is Visible  xpath=//div[contains(@class, 'o_dialog_error')]
    Run Keyword If         ${visible_js_error_dialog}    ${errordetails}=  Get Element Attribute  xpath=//div[contains(@class, 'o_error_detail')]@innerHTML
    Run Keyword If         ${visible_js_error_dialog}    Log To Console  ${errordetails}
    Run Keyword If         ${visible_js_error_dialog}    Click Element  xpath=//div[contains(@class, 'o_dialog_error')]//footer/button[contains(@class, 'btn-primary')]

WriteInField                [Arguments]     ${fieldname}    ${value}
    ${xpath}=               Set Variable  //input[@id='${fieldname}']|textarea[@id='${fieldname}']
    ElementPreCheck         xpath=${xpath}
    ${count}=               Get Element Count           xpath=${xpath}
    IF  ${count} == 0
        # Odoo V17 introduced index 0 at field names
        ${xpath}=           Set Variable  //input[@id='${fieldname}_0']|textarea[@id='${fieldname}_0']
        ElementPreCheck     xpath=${xpath}
        ${count}=               Get Element Count           xpath=${xpath}
    END
    IF  ${count} == 0
        FAIL                Element with name ${fieldname} not found     
    END
    Input Text              xpath=${xpath}  ${value}

    ${klass}=    Get Element Attribute   xpath=${xpath}  class
    ${is_autocomplete}=   Evaluate    "o-autocomplete--input" in "${klass}"
    # Capture Page Screenshot
    # needs wait for ajax call if many2one field
    Run Keyword If  ${is_auto_complete}  Sleep                   3s
    # wait if it is a many2one
    ${visible}=             Is Visible   xpath=//ul[@role='listbox']
    # Capture Page Screenshot
    Run Keyword If          ${visible}    Click Element    xpath=//li[@class='o-autocomplete--dropdown-item ui-menu-item'][1]

    # Close Error Dialog And Log
    # Capture Page Screenshot

    ElementPostCheck

Upload File                [Arguments]     ${fieldname}    ${value}
    File Should Exist       ${value}
    ${xpath}=               Set Variable  //div[@name='${fieldname}']//input
    Log                     Uploading file to ${fieldname}
    ${js_show_fileupload}=  Catenate  
    ...  const nodes = document.querySelector("div[name='${fieldname}']");
    ...  nodes.getElementsByTagName('input')[0].classList.remove("o_hidden");

    Execute Javascript      ${js_show_fileupload}
    Capture Page Screenshot
    Input Text              xpath=${xpath}    ${value}
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

Wait Until Block Is Gone
    Wait Until Element Is Not Visible  xpath=//div[contains(@class, 'o_blockUI')]

Wait To Click   [Arguments]       ${xpath}
    Capture Page Screenshot
    ${status}  ${error}=  Run Keyword And Ignore Error  Wait Until Element Is Visible          xpath=${xpath}
    Run Keyword If  '${status}' == 'FAIL'  Log  Element with ${xpath} was not visible - trying per javascript click
    Wait Until Block Is Gone
    Capture Page Screenshot
    IF  '${status}' != 'FAIL'  
        RETURN  Run Keyword And Return Status  Click Element  xpath=${xpath}
    END

    # try to click per javascript then; if mouse fails
    ${js}=  Catenate  
    ...  const xpath = "${xpath}";
    ...  const result = document.evaluate(xpath, document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    ...  for (let i = 0; i < result.snapshotLength; i++) {
    ...     const element = result.snapshotItem(i);
    ...     element.click();
    ...  }
    Execute Javascript  ${js}
    Capture Page Screenshot

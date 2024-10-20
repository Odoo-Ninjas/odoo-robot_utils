*** Settings ***

Documentation   Odoo backend keywords.
Library         ../library/browser.py
Library         SeleniumLibrary
Resource        odoo_client.robot
Resource        tools.robot
Library         ../library/tools.py
Resource        styling.robot
Resource        odoo_details.robot
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
    Click Button                            xpath=//div[contains(@class, 'oe_login_buttons')]//button[@type='submit']
    Log To Console                          Clicked login button - waiting
    Capture Page Screenshot
    Wait Until Page Contains Element        xpath=//nav[contains(@class, 'o_main_navbar')]	timeout=${SELENIUM_TIMEOUT}
    ElementPostCheck
    Log To Console                          Logged In - continuing
    RETURN    ${browser_id}

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
    RETURN  ${is_visible}

Close Error Dialog And Log
    ${visible_js_error_dialog}=  Is Visible  xpath=//div[contains(@class, 'o_dialog_error')]
    Run Keyword If         ${visible_js_error_dialog}    ${errordetails}=  Get Element Attribute  xpath=//div[contains(@class, 'o_error_detail')]@innerHTML
    Run Keyword If         ${visible_js_error_dialog}    Log To Console  ${errordetails}
    Run Keyword If         ${visible_js_error_dialog}    Click Element  xpath=//div[contains(@class, 'o_dialog_error')]//footer/button[contains(@class, 'btn-primary')]

WriteInField                [Arguments]     ${fieldname}    ${value}
    # Check if it is ACE:
    # <div name="field1" class="o_field_widget o_field_ace"
    ${locator_if_ACE}=                        _LocatorACE  ${fieldname}
    Run Keyword And Ignore Error              ElementPreCheck  ${locator_if_ACE}
    ${status_is_ace}  ${testel}=              Run Keyword And Ignore Error  Get WebElement  //div[@name='${fieldname}' and contains(@class, 'o_field_ace')]
    IF  '${status_is_ace}' != 'FAIL'
        _WriteACEEditor  ${fieldname}  ${value}
    ELSE
        ${xpath}=               Set Variable  //input[@id='${fieldname}' or @id='${fieldname}_0']|textarea[@id='${fieldname}' or @id='${fieldname}_0']
        _Write To Xpath          ${xpath}  ${value}
    END


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

Wait Until Block Is Gone
    Wait Until Element Is Not Visible  xpath=//div[contains(@class, 'o_blockUI')]

Wait To Click   [Arguments]       ${xpath}
    Capture Page Screenshot
    ${status}  ${error}=  Run Keyword And Ignore Error  Wait Until Element Is Visible          xpath=${xpath}
    Run Keyword If  '${status}' == 'FAIL'  Log  Element with ${xpath} was not visible - trying per javascript click
    Wait Until Block Is Gone
    Capture Page Screenshot
    IF  '${status}' != 'FAIL'  
        Click Element  xpath=${xpath}
        RETURN 
    END

    # try to click per javascript then; if mouse fails
    Log  Could not identify element ${xpath} - so trying by pure javascript to click it.
    ${js}=  Catenate  
    ...  const xpath = "${xpath}";
    ...  const result = document.evaluate(xpath, document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    ...  for (let i = 0; i < result.snapshotLength; i++) {
    ...     const element = result.snapshotItem(i);
    ...     element.click();
    ...  }
    Execute Javascript  ${js}
    Capture Page Screenshot

FormSave
    Wait To Click               xpath=//button[contains(@class, 'o_form_button_save')]
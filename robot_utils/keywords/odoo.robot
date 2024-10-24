*** Settings ***

Documentation   Odoo backend keywords.
Library         ../library/browser.py
Library         SeleniumLibrary
Library         OperatingSystem
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
    Wait Until Page Contains Element        xpath=//nav[contains(@class, 'o_main_navbar')]
    ElementPostCheck
    Log To Console                          Logged In - continuing
    RETURN    ${browser_id}

DatabaseConnect    [Arguments]    ${db}=${db}    ${odoo_db_user}=${ODOO_DB_USER}    ${odoo_db_password}=${ODOO_DB_PASSWORD}    ${odoo_db_server}=${SERVER}    ${odoo_db_port}=${ODOO_DB_PORT}
		Connect To Database Using Custom Params	psycopg2        database='${db}',user='${odoo_db_user}',password='${odoo_db_password}',host='${odoo_db_server}',port=${odoo_db_port}

ClickMenu    [Arguments]	${menu}
    Screenshot
    Log To Console     Clicking menu ${menu}
    ${xpath}=                           Set Variable  //a[@data-menu-xmlid='${menu}'] | //button[@data-menu-xmlid='${menu}']
    Wait Until Element is visible       xpath=${xpath} 

    ${attribute_value}=    Get Element Attribute    ${xpath}  aria-expanded

    IF  '${attribute_value}' == 'true'
        RETURN
    ELSE IF  '${attribute_value}' == 'false'
        Wait To Click	                    xpath=${xpath}
        _While Element Attribute Value  ${xpath}  aria-expanded  ==  false  as_bool
    ELSE
        Wait To Click	                    xpath=${xpath}
        Wait Until Page Contains Element	xpath=//body[contains(@class, 'o_web_client')]
    END

	ElementPostCheck


MainMenu	[Arguments]	${menu}
    # works V16
    ${enterprise}=  _has_module_installed  web_enterprise
    IF  ${enterprise}
        Wait Until Element is visible       xpath=//div[contains(@class, "o_navbar_apps_menu")]
        Click Element                       xpath=//div[contains(@class, "o_navbar_apps_menu")]/button
        Wait Until Element is visible       xpath=//a[@data-menu-xmlid='${menu}']
        Click Link	                        xpath=//a[@data-menu-xmlid='${menu}']
        Wait Until Page Contains Element	xpath=//body[contains(@class, 'o_web_client')]
        ElementPostCheck
    ELSE
        # Works V16
        Log  Enterprise is not installed - there is no main menu - just the burger menu
        ${home_menu}=                       Set Variable        //nav[@class='o_main_navbar']//button[@title='Home Menu']
        Wait Until Element Is Visible       xpath=${home_menu}
        Wait To Click                       xpath=${home_menu}
        Wait To Click                       xpath=//a[@data-menu-xmlid='${menu}']

    END

ApplicationMainMenuOverview
    ${enterprise}=  _has_module_installed  web_enterprise
    IF  ${enterprise}
        FAIL  not implemented ${odoo_version} enterprise
    ELSE
        IF  ${odoo_version} == 16.0
            Wait Until Element is visible       xpath=//nav[contains(@class, "o_main_navbar")]
            Click Element                        xpath=//nav[contains(@class, "o_main_navbar")]/button
            Wait Until Page Contains Element	xpath=//body[contains(@class, 'o_web_client')]
        ELSE
            FAIL  not implemented ${odoo_version}
    END
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
    ${xpath}=               Set Variable  //div[@name='${fieldname}']//input[@type='file']
    Log To Console          Uploading file to ${fieldname}
    ${js_show_fileupload}=  Catenate  
    ...  const callback = arguments[arguments.length - 1];
    ...  const nodes = document.querySelector("div[name='${fieldname}']");
    ...  const inputel = nodes.getElementsByTagName('input')[0];
    ...  inputel.classList.remove("o_hidden");
    ...  inputel.classList.remove("d-none");
    ...  callback();

    Wait Until Element Is Visible   xpath=${xpath}/..
    Execute Async Javascript        ${js_show_fileupload}
    Screenshot
    Input Text                      xpath=${xpath}    ${value}
    ElementPostCheck

Wait To Click   [Arguments]       ${xpath}
    Capture Page Screenshot
    ${status}  ${error}=  Run Keyword And Ignore Error  Wait Until Element Is Visible          xpath=${xpath}
    Run Keyword If  '${status}' == 'FAIL'  Log  Element with ${xpath} was not visible - trying per javascript click
    Wait Blocking
    Screenshot
    IF  '${status}' != 'FAIL'  
        ${disabled_value}=  Get Element Attribute  xpath=${xpath}  disabled
        IF  '${disabled_value}' == '1'
            FAIL  Button at ${xpath} is disabled
        END

        ${status2}  ${result}=  Run Keyword And Ignore Error  Click Element  xpath=${xpath}

        IF  '${status2}' != 'FAIL'  
            RETURN 
        ELSE
            _Wait Until Element Is Not Disabled  xpath=${xpath}
        END
    END
    Log To Console  Wait To Click using fallback with javascript, as element was not clickable.

    # try to click per javascript then; if mouse fails
    Log  Could not identify element ${xpath} - so trying by pure javascript to click it.
    ${guid}=  Get Guid
    ${libdir}=  library Directory
    ${wait_for_disabled_and_enabled}=  Get File    ${libdir}/../keywords/js/waitForChange.js
    ${js}=  Catenate  
    ...  const callback = arguments[arguments.length - 1];
    ...  const xpath = "${xpath}";
    ...  ${wait_for_disabled_and_enabled};
    ...  const result = document.evaluate(xpath, document, null, 
    ...     XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    ...  for (let i = 0; i < result.snapshotLength; i++) {
    ...     const element = result.snapshotItem(i);
    ...     waitForDisabledAndEnabled(element).then(() => {
    ...         console.log("Element went through disable/enable cycle");
    ...         callback();
    ...     });
    ...     element.click();
    ...  }
    Execute Async Javascript  ${js}
    _Wait Until Element Is Not Disabled  xpath=${xpath}
    Screenshot
    Element Post Check

Breadcrumb Back
    Log To Console                  Click breadcrumb - last item
    IF  ${odoo_version} == 17.0
        Wait To Click               //ol[contains(@class, 'breadcrumb')]/li[a][last()]
    ELSE IF  ${odoo_version} == 16.0
        Wait To Click               //ol[contains(@class, 'breadcrumb')]/li[a][last()]
    ELSE
        FAIL  Breadcrumb Needs implementation for ${odoo_version}
    END
    ElementPostCheck

FormSave
    Screenshot
    Wait To Click               xpath=//button[contains(@class, 'o_form_button_save')]
    Screenshot


Goto View  [Arguments]  ${model}  ${id}  ${type}=form
    Go To   ${ODOO_URL}/web
    Screenshot

    Go To   ${ODOO_URL}/web#id=${id}&cids=1&model=${model}&view_type=${type}
    IF  '${type}' == 'form'
        Wait Until Element Is Visible  xpath=//div[@class='o_form_view_container']
    ELSE IF  '${type}' == 'form' OR '${type}' == 'list'
        Wait Until Element Is Visible  xpath=//div[@class='o_list_renderer']
    ELSE
        FAIL  needs implementation for ${type}
    END
    Screenshot
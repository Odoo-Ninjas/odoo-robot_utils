*** Settings ***

Documentation   Odoo 13 backend keywords.
Library         ../../robot_utils_common/library/browser.py
Library         SeleniumLibrary
Resource        ../../robot_utils/keywords/odoo_community_unverified.robot
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
    Wait Until Page Contains Element        xpath=//span[contains(@class, 'oe_topbar_name')]	timeout=10 sec
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

WriteInField                [Arguments]     ${fieldname}    ${value}
    ${xpath}=               Set Variable  //input[@id='${fieldname}']|textarea[@id='${fieldname}']
    ElementPreCheck         xpath=${xpath}
    Input Text              xpath=${xpath}  ${value}
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

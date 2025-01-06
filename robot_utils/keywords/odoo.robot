*** Settings ***
Documentation       Odoo backend keywords.

Library             ../library/browser.py
Library             SeleniumLibrary
Library             OperatingSystem
Resource            debug.robot
Resource            odoo_client.robot
Resource            tools.robot
Library             ../library/tools.py
Resource            styling.robot
Resource            odoo_details.robot
Resource            highlighting.robot
Resource            browser.robot
Library             String    # example Random String
Library             ../library/default_vars.py


*** Keywords ***
Login    [Arguments]    ${user}=${ODOO_USER}    ${password}=${ODOO_PASSWORD}    ${url}=${ODOO_URL}/web/login
    Load Default Vars
    ${randomstring}=    Evaluate    str(uuid.uuid4())    modules=uuid
    ${url}=    Set Variable    ${url}#${randomstring}
    ${browser_id}=    Open New Browser    ${url}
    ${snippetmode}=    Get Variable Value    ${SNIPPET_MODE}    ${FALSE}
    IF    ${snippetmode}    RETURN    ${browser_id}
    # Run Keyword and Ignore error    Click element    //a[@href="/web/login"]
    Capture Page Screenshot
    Wait Until Element is Visible    name=login
    Log To Console    Input is visible, now entering credentials for user ${user} with password ${password}
    Input Text    xpath=//input[@name='login'][1]    ${user}
    Input Text    xpath=//input[@name='password'][1]    ${password}
    Log To Console    Clicking Login
    Capture Page Screenshot
    Click Button    xpath=//div[contains(@class, 'oe_login_buttons')]//button[@type='submit']
    Log To Console    Clicked login button - waiting
    Capture Page Screenshot
    IF    ${odoo_version} <= 11.0
        Wait Until Page Contains Element    xpath=//body[contains(@class, 'o_web_client')]
    ELSE IF    ${odoo_version} < 14.0
        Wait Until Page Contains Element    xpath=//nav[contains(@id, 'oe_main_menu_navbar')]
    ELSE
        Wait Until Page Contains Element    xpath=//nav[contains(@class, 'o_main_navbar')]
    END
    ElementPostCheck
    Log To Console    Logged In - continuing
    RETURN    ${browser_id}

DatabaseConnect    [Arguments]
    ...    ${db}=${db}
    ...    ${odoo_db_user}=${ODOO_DB_USER}
    ...    ${odoo_db_password}=${ODOO_DB_PASSWORD}
    ...    ${odoo_db_server}=${SERVER}
    ...    ${odoo_db_port}=${ODOO_DB_PORT}
    Connect To Database Using Custom Params
    ...    psycopg2
    ...    database='${db}',user='${odoo_db_user}',password='${odoo_db_password}',host='${odoo_db_server}',port=${odoo_db_port}

ClickMenu    [Arguments]    ${menu}

    Screenshot
    Log To Console    Clicking menu ${menu}
    ${xpath}=    Set Variable    //a[@data-menu-xmlid='${menu}'] | //button[@data-menu-xmlid='${menu}']
    Wait Until Element is visible    xpath=${xpath}

    ${attribute_value}=    Get Element Attribute    ${xpath}    aria-expanded

    IF    '${attribute_value}' == 'true'
        RETURN
    ELSE IF    '${attribute_value}' == 'false'
        Wait To Click    xpath=${xpath}
        _While Element Attribute Value    ${xpath}    aria-expanded    ==    false    as_bool
    ELSE
        Wait To Click    xpath=${xpath}
        Wait Until Page Contains Element    xpath=//body[contains(@class, 'o_web_client')]
    END

    ElementPostCheck

MainMenu    [Arguments]    ${menu}
    # works V16
    ${enterprise}=    _has_module_installed    web_enterprise
    IF    ${enterprise}
        IF    ${odoo_version} == 11.0
            Log    not needed - top menue on top
        ELSE IF    ${odoo_version} == 14.0
            Wait Until Element is visible    xpath=//nav[contains(@class, "o_main_navbar")]
        ELSE IF    ${odoo_version} == 17.0
            ${homemenu}=    Run Keyword And Return Status    Get WebElement    css=div.o_home_menu
            IF    not ${homemenu}
                Wait To Click    xpath=//nav/a[contains(@class, 'o_menu_toggle')]
            END
        ELSE
            Wait Until Element is visible    xpath=//div[contains(@class, "o_navbar_apps_menu")]
            Wait To Click    xpath=//div[contains(@class, "o_navbar_apps_menu")]/button
        END
        ${xpath}=    Set Variable    //a[@data-menu-xmlid='${menu}'][1]
        Wait Until Page Contains Element    xpath=${xpath}
        Wait To Click    xpath=${xpath}
        Wait Until Page Contains Element    xpath=//body[contains(@class, 'o_web_client')]
        ElementPostCheck
    ELSE
        # Works V16
        Log To Console    Enterprise is not installed - there is no main menu - just the burger menu
        IF    ${odoo_version} == 11.0
            Log    not needed - top menue on top
        ELSE
            ${home_menu}=    Set Variable    //nav[@class='o_main_navbar']//button[@title='Home Menu']
            Wait Until Page Contains Element    xpath=${home_menu}
            Wait To Click    xpath=${home_menu}
        END
        Wait To Click    xpath=//a[@data-menu-xmlid='${menu}'][position() = 1]
    END

ApplicationMainMenuOverview
    ${enterprise}=    _has_module_installed    web_enterprise
    IF    ${enterprise}
        FAIL    not implemented ${odoo_version} enterprise
    ELSE
        IF    ${odoo_version} == 16.0
            Wait Until Element is visible    xpath=//nav[contains(@class, "o_main_navbar")]
            Click Element    xpath=//nav[contains(@class, "o_main_navbar")]/button
            Wait Until Page Contains Element    xpath=//body[contains(@class, 'o_web_client')]
        ELSE
            FAIL    not implemented ${odoo_version}
        END
    END
    ElementPostCheck

Close Error Dialog And Log
    ${visible_js_error_dialog}=    Is Visible    xpath=//div[contains(@class, 'o_dialog_error')]
    IF    ${visible_js_error_dialog}
        # before it was @innerHTML
        ${errordetails}=    Get Element Attribute    xpath=//div[contains(@class, 'o_error_detail')]    innerHTML
    END
    IF    ${visible_js_error_dialog}
        Log To Console    ${errordetails}
        IF    ${visible_js_error_dialog}
            Click Element
            ...    xpath=//div[contains(@class, 'o_dialog_error')]//footer/button[contains(@class, 'btn-primary')]
        END
    END

Write    [Arguments]
    ...    ${fieldname}
    ...    ${value}
    ...    ${ignore_auto_complete}=False
    ...    ${parent}=${NONE}
    ...    ${tooltip}=${NONE}
    ...    ${css_parent}=${NONE}

    # Check if it is ACE:
    # <div name="field1" class="o_field_widget o_field_ace"
    ${start}=    Get Current Time MS

    ${parent_set}=    Eval    bool(v)    v=${parent}
    IF    ${parent_set}
        ${parent}=    Catenate    SEPARATOR=|    div[name='${parent}'], div[id='${parent}']
    END

    ${elapsed}=  Get Elapsed Time Ms  ${start}
    Log To Console    Elapsed time WriteInField at Pos A: ${elapsed}ms

    Log2
    ...    WriteInField ${fieldname}=${value} ignore_auto_complete=${ignore_auto_complete} with parent=${parent} and xpath_parent=${css_parent}
    ${locator_ACE}=    _LocatorACE    ${fieldname}    ${parent}    css_parent=${css_parent}

    ${locator_select}=    _LocatorSelect    ${fieldname}    ${parent}    css_parent=${css_parent}
    ${elapsed}=  Get Elapsed Time Ms  ${start}
    Log To Console    Elapsed time WriteInField at Pos A0: ${elapsed}ms

    ${js}=    Catenate
    ...    SEPARATOR=\n
    ...    const callback = arguments[arguments.length - 1];
    ...    const el_ace = document.querySelector(`${locator_ACE}`);
    ...    const el_select = document.querySelector(`${locator_select}`);
    ...    if (el_ace) { callback("ace") }
    ...    else if (el_select) { callback("select") }
    ...    else callback("none");
    ${eltype}=  Execute Async Javascript    ${js}
    ${elapsed}=  Get Elapsed Time Ms  ${start}
    Log To Console    Elapsed time WriteInField at Pos A0.1: ${elapsed}ms

    ${hastooltip}=    Eval    bool(h)    h=${tooltip}

    IF    '${eltype}' == 'ace'
        ElementPreCheck    ${locator_ACE}
        _WriteACEEditor    ${fieldname}    ${value}    ${parent}    css_parent=${css_parent}    tooltip=${tooltip}
    ELSE IF    '${eltype}' == 'select'
        ElementPreCheck    ${locator_select}
        _WriteSelect    ${fieldname}    ${value}    ${parent}    css_parent=${css_parent}    tooltip=${tooltip}
    ELSE
        ${elapsed}=  Get Elapsed Time Ms  ${start}
        Log To Console    Elapsed time WriteInField at Pos B1: ${elapsed}ms

        ${csss}=    Create List
        ...    div[name='${fieldname}'] input
        ...    div[name='${fieldname}'] textarea
        ...    input[id='${fieldname}'],input[id='${fieldname}_0'],input[name='${fieldname}']
        ...    textarea[id='${fieldname}'],textarea[id='${fieldname}_0'],textarea[name='${fieldname}']

        ${csss}=    _prepend_parent    ${csss}    ${parent}    css_parent=${css_parent}
        ${css}=    Catenate    SEPARATOR=,      @{csss}

        ${elapsed}=  Get Elapsed Time Ms  ${start}
        Log To Console    Elapsed time WriteInField at Pos B3: ${elapsed}ms

        ${element}=  Get WebElement  css=${css}
        ${tempid}=  Do Get Guid
        ${tempid}=  Set Variable  id${tempid}
        ${oldid}=  Get Element Attribute  ${element}  id 
        Execute Javascript  document.querySelector('#' + CSS.escape('${oldid}')).setAttribute('id', '${tempid}');
        ${oldcss}=  Set Variable  ${css}
        ${css}=  Set Variable  \#${tempid}
        ${testwebel}=  Get WebElement  css=${css}

        Highlight Element    ${css}    ${TRUE}
        ${elapsed}=  Get Elapsed Time Ms  ${start}
        Log To Console    Elapsed time WriteInField at Pos B3.1: ${elapsed}ms
        IF  not ${ROBO_NO_UI_HIGHLIGHTING}
            JS Scroll Into View    ${css}
        END
        ${elapsed}=  Get Elapsed Time Ms  ${start}
        Log To Console    Elapsed time WriteInField at Pos B3.1.1: ${elapsed}ms
        IF  not ${ROBO_NO_UI_HIGHLIGHTING}
            Mouse Over  ${testwebel}
        END
        ${elapsed}=  Get Elapsed Time Ms  ${start}
        Log To Console    Elapsed time WriteInField at Pos B3.2: ${elapsed}ms
        ${elapsed}=  Get Elapsed Time Ms  ${start}
        Log To Console    Elapsed time WriteInField at Pos B3.3: ${elapsed}ms
        _Write To Element    ${element}    ${value}    ignore_auto_complete=${ignore_auto_complete}
        ${elapsed}=  Get Elapsed Time Ms  ${start}
        Log To Console    Elapsed time WriteInField at Pos B3.4: ${elapsed}ms
        Highlight Element    ${css}    ${FALSE}
        ${elapsed}=  Get Elapsed Time Ms  ${start}
        Log To Console    Elapsed time WriteInField at Pos B3.5: ${elapsed}ms

        Set Element Attribute  ${css}  id  ${oldid}
        ${css}=  Set Variable  ${oldcss}
    END
    IF    ${hastooltip}    
        _removeTooltips
    END
    Log To Console    Done: WriteInField ${fieldname}=${value}
    Screenshot
    ${elapsed}=    Get Elapsed Time MS  ${start}
    Log To Console    Elapsed time WriteInField: ${elapsed}ms

Breadcrumb Back
    Log To Console    Click breadcrumb - last item
    IF    ${odoo_version} == 17.0
        Wait To Click    //ol[contains(@class, 'breadcrumb')]/li[a][last()]
    ELSE IF    ${odoo_version} == 16.0
        Wait To Click    //ol[contains(@class, 'breadcrumb')]/li[a][last()]
    ELSE
        FAIL    Breadcrumb Needs implementation for ${odoo_version}
    END
    ElementPostCheck

Form Save
    Screenshot
    Wait To Click    xpath=//button[contains(@class, 'o_form_button_save')]
    Screenshot

Goto View    [Arguments]    ${model}    ${id}    ${type}=form
    Log To Console    Goto View ${model} ${id} ${type}
    Go To    ${ODOO_URL}/web
    Screenshot

    ${random}=    Generate Random String    10    [LETTERS]
    ${url}=    Set Variable    ${ODOO_URL}/web#id=${id}&cids=1&model=${model}&view_type=${type}&randomid=${random}
    Log To Console    url: ${url}
    Go To    ${url}
    IF    '${type}' == 'form'
        Wait Until Element Is Visible    xpath=//div[@class='o_form_view_container']
    ELSE IF    '${type}' == 'form' OR '${type}' == 'list'
        Wait Until Element Is Visible    xpath=//div[@class='o_list_renderer']
    ELSE
        FAIL    needs implementation for ${type}
    END
    Screenshot
    Log To Console    Goto View ${model} ${id} ${type} Done

Odoo Write One2many    [Arguments]    ${fieldname}    ${data}
    FOR    ${key}    ${value}    IN    &{data}
        Write In Field    ${key}    ${value}    parent=${fieldname}
    END

Odoo Click    [Arguments]    ${xpath}    ${tooltip}=${NONE}
    Wait To Click    xpath=${xpath}    tooltip=${tooltip}

Wait To Click    [Arguments]    ${css}    ${tooltip}=${NONE}
# V17: they disable also menuitems and enable to avoid double clicks; not
# so in <= V16
    Add Cursor
    Log To Console    Wait To Click ${css}

    Wait Until Page Contains Element    xpath=${css}
    Wait Blocking
    Log    Could not identify element ${css} - so trying by pure javascript to click it.
    ${hastooltip}=    Eval    bool(h)    h=${tooltip}

    ${status_mouse_over}=    Run Keyword And Return Status    Mouse Over    ${css}
    IF    '${status_mouse_over}' == 'FAIL'
        JS Scroll Into View    ${css}
        ${status_mouse_over}=    Run Keyword And Return Status    Mouse Over    ${css}
    END
    IF    ${hastooltip}
        _showTooltipByLocator    ${css}    tooltip=${tooltip}
    END
    JS On Element    ${css}    jscode=element.click()    maxcount=1
    IF    ${hastooltip}    _removeTooltips

    Sleep    10ms    # Give chance to become disabled
    _Wait Until Element Is Not Disabled    ${css}
    Element Post Check
    Capture Page Screenshot
    Remove Cursor
    Log To Console    Done Wait To Click ${css}
    Wait Blocking

Odoo Button    [Arguments]    ${text}=${NONE}    ${name}=${NONE}    ${tooltip}=${NONE}

    ${hasname}=    Eval    bool(n)    t=${text}    n=${name}
    ${hastext}=    Eval    bool(t)    t=${text}    n=${name}

    IF    ${hasname}
        Wait To Click    (//button[@name='${name}'] | //a[@name='${name}'])[1]    tooltip=${tooltip}
    ELSE IF    ${hastext}
        Wait To Click
        ...    (//button[contains(text(), '${text}')] | //a[contains(text(), '${text}')])[1]
        ...    tooltip=${tooltip}
    ELSE
        FAIL    provide either text or name
    END

Odoo Upload File    [Arguments]    ${fieldname}    ${filepath}    ${parent}=${NONE}    ${xpath_parent}=${NONE}

    Log To Console    UploadFile ${fieldname}=${filepath}
    File Should Exist    ${filepath}

    ${xpath}=    Set Variable
    ...    //div[@name='${fieldname}']//input[@type='file']
    ${xpath}=    _prepend_parent    ${xpath}    ${parent}    xpath_parent=${xpath_parent}

    Log To Console    Uploading file to ${fieldname}
    ${js_show_fileupload}=    Catenate
    ...    SEPARATOR=\n
    ...    const callback = arguments[arguments.length - 1];
    ...    const nodes = Array.from(document.querySelectorAll("div[name='${fieldname}'] input[type='file'], div.o_field_binary_file[name='${fieldname}'] div.o_hidden_input_file, div.o_field_binary_file[name='${fieldname}'] div.o_hidden"));
    ...    nodes.forEach(inputel => {
    ...    inputel.classList.remove("o_hidden_input_file");
    ...    inputel.classList.remove("o_hidden");
    ...    inputel.style.display = "";
    ...    });
    ...    callback();
    Screenshot
    Wait Until Page Contains Element    xpath=${xpath}/..

    Screenshot
    Log To Console    ${js_show_fileupload}
    Execute Async Javascript    ${js_show_fileupload}
    Screenshot

    Wait Until Element Is Visible    xpath=${xpath}/..
    Screenshot

    ${file_name}=    tools.Get File Name    ${file_path}
    Copy File    ${filepath}    ${DIRECTORY UPLOAD FILES LOCAL}/${file_name}

    Choose File    xpath=${xpath}    ${DIRECTORY UPLOAD FILES BROWSER DRIVER}/${file_name}
    ElementPostCheck
    Log To Console    Done UploadFile ${fieldname}=${filepath}

Odoo Setting Checkbox    [Arguments]    ${title}    ${toggle}=${TRUE}

    Log    Setting Configuration ${title}

    # Works for V14:
    ${xpath}=    Set Variable    //*[@id='${title}']//input[@type='checkbox']
    JS Scroll Into View    ${xpath}

    ${jsvalue}=    Eval    'true' if v else 'false'    v=${toggle}
    JS On Element    ${xpath}    element.checked=${jsvalue};    maxcount=1

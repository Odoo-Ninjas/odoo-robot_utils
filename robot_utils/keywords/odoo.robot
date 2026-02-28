*** Settings ***
Documentation       Odoo backend keywords.

Library             ../library/browser.py
Library             SeleniumLibrary
Library             OperatingSystem
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
Login    [Arguments]    ${user}=${ROBO_ODOO_USER}    ${password}=${ROBO_ODOO_PASSWORD}    ${url}=${ODOO_URL}/web/login
    # {user} is overwritten by context usually
    ${randomstring}=    Evaluate    str(uuid.uuid4())    modules=uuid
    ${url}=    Set Variable    ${url}#${randomstring}
    ${browser_id}=    Open New Browser    ${url}
    ${snippetmode}=    Get Variable Value    ${SNIPPET_MODE}    ${FALSE}
    IF    ${snippetmode}    RETURN    ${browser_id}
    # Run Keyword and Ignore error    Click element    //a[@href="/web/login"]
    Capture Page Screenshot
    Wait Until Element is Visible    name=login
    Log To Console    Input is visible, now entering credentials for user ${user} with password ${password}
    Input Text    css=input#login    ${user}
    Input Text    css=input#password    ${password}
    Log To Console    Clicking Login
    Capture Page Screenshot
    Click Button    css=div.oe_login_buttons button[type='submit']
    Log To Console    Clicked login button - waiting
    Capture Page Screenshot
    IF    ${odoo_version} <= 11.0
        Wait Until Page Contains Element    css=body.o_web_client
    ELSE IF    ${odoo_version} < 14.0
        Wait Until Page Contains Element    css=nav.oe_main_menu_navbar
    ELSE
        Wait Until Page Contains Element    css=nav.o_main_navbar
    END
    Wait Blocking And Eval Error States
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
    ${css}=    Set Variable    a[data-menu-xmlid='${menu}'], button[data-menu-xmlid='${menu}']
    Wait Until Element is visible    css=${css}

    ${attribute_value}=    Get Element Attribute    css=${css}    aria-expanded

    IF    '${attribute_value}' == 'true'
        RETURN
    ELSE IF    '${attribute_value}' == 'false'
        Wait To Click    css=${css}
        _While Element Attribute Value    ${css}    aria-expanded    ==    false    as_bool
    ELSE
        Wait To Click    ${css}
        Wait Until Page Contains Element    css=body.o_web_client
    END

    Wait Blocking And Eval Error States

MainMenu    [Arguments]    ${menu}
    # works V16
    ${enterprise}=    _has_module_installed    web_enterprise
    IF    ${enterprise}
        IF    ${odoo_version} == 11.0
            Log    not needed - top menue on top
        ELSE IF    ${odoo_version} == 14.0
            Wait Until Element is visible    nav.o_main_navbar
        ELSE IF    ${odoo_version} == 17.0
            ${homemenu}=    Run Keyword And Return Status    Get WebElement    css=div.o_home_menu
            IF    not ${homemenu}    Wait To Click    nav a.o_menu_toggle
        ELSE
            Wait Until Element is visible    div.o_navbar_apps_menu
            Wait To Click    div.o_navbar_apps_menu button
        END
        ${css}=    Set Variable    a[data-menu-xmlid='${menu}']
        Wait Until Page Contains Element    css=${css}
        Wait To Click    css=${css}
        Wait Until Page Contains Element    css=body.o_web_client
        Wait Blocking And Eval Error States
    ELSE
        # Works V16
        Log To Console    Enterprise is not installed - there is no main menu - just the burger menu
        IF    ${odoo_version} == 11.0
            Log    not needed - top menue on top
        ELSE
            ${home_menu}=    Set Variable    nav.o_main_navbar button[title='Home Menu']
            Wait Until Page Contains Element    css=${home_menu}
            Wait To Click    css=${home_menu}
        END
        Wait To Click    css=a[data-menu-xmlid='${menu}']    position=1
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
    Wait Blocking And Eval Error States

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

Write List    [Arguments]    ${values}    ${parent_fieldname}

    # select the current activated line and remember it
    ${webelement}=    Get WebElement    css=[name='${parent_fieldname}'] tbody tr.o_data_row.o_selected_row
    ${haswebelement}=    Eval    bool(w)    w=${webelement}

    IF    not ${haswebelement}    FAIL    Please call 'add a line' or so first

    FOR    ${key}    ${value}    IN    &{values}
        ${cssparent}=    Set Variable    [name='${parent_fieldname}'] tbody tr.o_data_row.o_selected_row
        ${csstd}=    Set Variable    div[name='${key}']
        JS On Element    ${cssparent} ${csstd}
        ...    element.click()
        Write    ${key}    ${value}    css_parent=${cssparent}
        Log    Key: ${key}, Value: ${value}
    END

Write    [Documentation]
    ...    Toggle checkbox value:    write    name    Buy
    ...    Force Set checkbox value:    write    name    Buy    checkboxvalue=${TRUE}
    [Arguments]
    ...    ${fieldname}
    ...    ${value}
    ...    ${ignore_auto_complete}=${FALSE}
    ...    ${parent}=${NONE}
    ...    ${tooltip}=${NONE}
    ...    ${css_parent}=${NONE}
    ...    ${checkboxvalue}=${NONE}

    ${start}=    Get Current Time MS
    Wait Blocking And Eval Error States

    ${parent_set}=    Eval    bool(v)    v=${parent}
    IF    ${parent_set}
        ${parent}=    Set Variable    div[name='${parent}'], div[id='${parent}']
    END

    ${identity_type}=    Identify Input Type
    ...    ${fieldname}
    ...    ${value}
    ...    ${parent}
    ...    ${css_parent}

    ${locator_css}=    Get From Dictionary    ${identity_type}    path
    ${eltype}=    Get From Dictionary    ${identity_type}    key

    ${hastooltip}=    Eval    bool(h)    h=${tooltip}
    IF    $hastooltip
        ShowTooltip By Locator    ${locator_css}    tooltip=${tooltip}
    END

    IF    "${eltype}" == "boolean"
        _ToggleCheckbox    ${locator_css}    force_value=${value}
    ELSE IF    "${eltype}" == "many2many_checkboxes"
        _ToggleCheckbox    ${locator_css}    force_value=${checkboxvalue}
    ELSE IF    "${eltype}" == "radio"
        _ToggleRadio    ${locator_css}
    ELSE IF    "${eltype}" == "ace"
        _WriteACEEditor    ${locator_css}    ${value}    tooltip=${tooltip}
    ELSE IF    "${eltype}" == "select"
        _WriteSelect
        ...    ${locator_css}
        ...    ${fieldname}
        ...    ${value}
        ...    ${parent}
        ...    css_parent=${css_parent}
        ...    tooltip=${tooltip}
    ELSE IF    "${eltype}" == "input"
        _Write To Element    ${locator_css}    ${value}    ignore_auto_complete=${ignore_auto_complete}
    ELSE
        FAIL    not implemented: ${eltype}
    END
    Remove Tooltips
    Wait Blocking And Eval Error States

    IF    ${hastooltip}    _removeTooltips

Breadcrumb Back
    Log To Console    Click breadcrumb - last item
    IF    ${ODOO_VERSION} in [17.0]
        Wait To Click    ol.breadcrumb li:nth-last-child(1) a
    ELSE IF    ${ODOO_VERSION} in [16.0]
        Wait To Click    ol.breadcrumb li:nth-last-child(2) a
    ELSE IF    ${ODOO_VERSION} in [18.0, 19.0]
        Wait To Click    ol.breadcrumb li:nth-last-child(1) a
    ELSE
        FAIL    Breadcrumb Needs implementation for ${ODOO_VERSION}
    END
    Wait Blocking And Eval Error States

Form Save
    Wait To Click    button.o_form_button_save

Slug    [Arguments]    ${ids}
    IF    not ${ids}
        ${ids}=    Set Variable    ${{ [] }}
    END
    ${id}=    Eval    id[0] if id and isinstance(id, (list,tuple)) and len(id) \=\= 1 else id    id=${ids}
    RETURN    ${id}

Goto View    [Arguments]    ${model}    ${id}    ${type}=form
    Log To Console    Goto View ${model} ${id} ${type}
    Go To    ${ODOO_URL}/web

    ${id}=    Slug    ${id}

    ${random}=    Generate Random String    10    [LETTERS]
    ${url}=    Set Variable    ${ODOO_URL}/web#cids=1&model=${model}&view_type=${type}&randomid=${random}
    IF    ${id}
        ${url}=    Set Variable    ${url}&id=${id}
    END
    Log To Console    url: ${url}
    Go To    ${url}
    IF    '${type}' == 'form'
        Wait Until Element Is Visible    xpath=//div[@class='o_form_view_container']
    ELSE IF    '${type}' == 'form' OR '${type}' == 'list'
        Wait Until Element Is Visible    xpath=//div[@class='o_list_renderer']
    ELSE
        FAIL    Goto View needs implementation for ${type}
    END
    Screenshot
    Log To Console    Goto View ${model} ${id} ${type} Done

Odoo Write One2many    [Arguments]    ${fieldname}    ${data}
    FOR    ${key}    ${value}    IN    &{data}
        Write    ${key}    ${value}    parent=${fieldname}
    END

Odoo Click    [Arguments]    ${xpath}    ${tooltip}=${NONE}
    Wait To Click    xpath=${xpath}    tooltip=${tooltip}

Wait To Click    [Arguments]
    ...    ${css}
    ...    ${tooltip}=${NONE}
    ...    ${maxcount}=1
    ...    ${limit}=1
    ...    ${position}=0
    ...    ${error_check}=${TRUE}
    ...    ${autowait}=${TRUE}
# V17: they disable also menuitems and enable to avoid double clicks; not
# so in <= V16
    Add Cursor
    Log To Console    Wait To Click ${css}

    Wait Until Page Contains Element    css=${css}
    Wait Blocking And Eval Error States    error_check=${error_check}
    Log    Could not identify element ${css} - so trying by pure javascript to click it.
    ${hastooltip}=    Eval    bool(h)    h=${tooltip}

    ${status_mouse_over}=    Run Keyword And Return Status    Mouse Over    css=${css}
    IF    '${status_mouse_over}' == 'FAIL'
        JS Scroll Into View    ${css}
        ${status_mouse_over}=    Run Keyword And Return Status    Mouse Over    css=${css}
    END
    IF    ${hastooltip}
        ShowTooltip By Locator    css=${css}    tooltip=${tooltip}
    END
    JS On Element    ${css}    jscode=element.click()    maxcount=${maxcount}    limit=${limit}    position=${position}
    IF    ${hastooltip}    _removeTooltips

    Sleep    10ms    # Give chance to become disabled
    Wait Ajax Requests Done
    _Wait Until Element Is Not Disabled    ${css}
    Wait Blocking And Eval Error States    error_check=${error_check}
    Capture Page Screenshot
    Remove Cursor
    Log To Console    Done Wait To Click ${css}
    Wait Blocking And Eval Error States    error_check=${error_check}

	IF  ${autowait}
        ${contains_add}=  Eval  a in b  a=.o_list_button_add  b=${css}
        IF  ${contains_add}
            Wait Until Element is visible    css=div.o_form_sheet
        END
    END

Click Tab    [Arguments]    ${tabcaption}
    Odoo Button    text=${tabcaption}    custom_css=a[role='tab']

Odoo Button    [Arguments]    ${text}=${NONE}    ${name}=${NONE}    ${tooltip}=${NONE}    ${custom_css}=${NONE}  ${limit}=0

    ${hasname}=    Eval    bool(n)    t=${text}    n=${name}
    ${hastext}=    Eval    bool(t)    t=${text}    n=${name}
    ${has_custom_css}=    Eval    bool(t)    t=${custom_css}

    IF    ${hasname}
        IF    ${has_custom_css}    FAIL    not implemented
        Wait To Click    button[name='${name}'], a[name='${name}']    tooltip=${tooltip}
    ELSE IF    ${hastext}
        IF    ${has_custom_css}
            ${buttoncss}=    Set Variable    ${custom_css}
        ELSE
            ${buttoncss}=    Set Variable    button,a
        END
        ${css}=    CSS Identifier With Text    ${buttoncss}    ${text}  limit=${limit}
        Wait To Click    ${css}    tooltip=${tooltip}
    ELSE
        FAIL    provide either text or name
    END

Odoo Upload File    [Arguments]    ${fieldname}    ${filepath}    ${parent}=${NONE}    ${css_parent}=${NONE}

    Log To Console    UploadFile ${fieldname}=${filepath}
    File Should Exist    ${filepath}

    ${css}=    Create List
    ...    div[name='${fieldname}'] input[type='file']
    ...    div.o_field_binary_file[name='${fieldname}'] div.o_hidden_input_file
    ...    div.o_field_binary_file[name='${fieldname}'] div.o_hidden
    ${css}=    _prepend_parent    ${css}    ${parent}    css_parent=${css_parent}
    ${css}=    Catenate    SEPARATOR=,    @{css}

    Log To Console    Uploading file to ${fieldname}

    ${js}=    Catenate    SEPARATOR=\n
    ...    element.classList.remove("o_hidden_input_file");
    ...    element.classList.remove("o_hidden");
    ...    element.classList.remove("d-none");
    ...    element.style.display = null;
    JS On Element    ${css}    ${js}  filter_visible=${FALSE}

    ${file_name}=    tools.Get File Name    ${file_path}
    IF    "${DIRECTORY_UPLOAD_FILES_LOCAL}" == ""
        FAIL    Please define DIRECTORY_UPLOAD_FILES_LOCAL
    END
    IF    "${DIRECTORY UPLOAD FILES BROWSER DRIVER}" == ""
        FAIL    Please define DIRECTORY UPLOAD FILES BROWSER DRIVER
    END
    Log To Console    Copying file to ${DIRECTORY UPLOAD FILES LOCAL}/${file_name}
    tools.Copy File    ${filepath}    ${DIRECTORY UPLOAD FILES LOCAL}/${file_name}

    Log To Console    Choosing file from ${DIRECTORY UPLOAD FILES BROWSER DRIVER}/${file_name}

    # that input text works on file element it is required that the useless file detector is set
    Input Text    css=${css}    ${DIRECTORY UPLOAD FILES BROWSER DRIVER}/${file_name}
    Wait Blocking And Eval Error States
    Log To Console    Done UploadFile ${fieldname}=${filepath}

Odoo Setting Checkbox    [Arguments]    ${title}    ${toggle}=${TRUE}

    Log    Setting Configuration ${title}

    IF    ${odoo_version} == 14.0
        # Works for V14:
        ${xpath}=    Set Variable    [id='${title}'] input[type='checkbox']
    ELSE IF    ${odoo_version} == 17.0
        ${xpath}=    Set Variable    [name='${title}'] input[type='checkbox']
    ELSE
        FAIL    ${odoo_version} not implemented for Setting Configuration
    END
    JS Scroll Into View    ${xpath}

    ${jsvalue}=    Eval    'true' if v else 'false'    v=${toggle}

    ${code}=    Catenate
    ...    element.checked=${jsvalue};
    ...    element.dispatchEvent(new Event("change", { bubbles: true }));
    JS On Element    ${xpath}    ${code}    maxcount=1

Eval Error States
    Eval JS Error Dialog
    Eval Validation User Error Dialog

Add User To Group  [Arguments]  ${username}  ${groupxmlid}

    ${group}=  Odoo Ref  ${groupxmlid}
    ${user}=  Odoo Search Records  res.users  [('login', '=', '${username}')]
    Eval  u.write({'groups_id': [[4, g.id]]})  u=${user}  g=${group}

Odoo Field Exists  [Arguments]  ${model}  ${fieldname}
    ${has}=    Odoo Search    ir.model.fields    [('model_id.model', '=', "${model}"), ('name', '=', '${fieldname}')]    count=${TRUE}
    ${has}=   Eval  bool(h)  h=${has}
    RETURN  ${has}

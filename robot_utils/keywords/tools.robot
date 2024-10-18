*** Settings ***
Documentation    Some Tools
Library          ../library/odoo.py
Library          ../library/tools.py
Library          Collections


*** Keywords ***

Set Dict Key
    [Arguments]
    ...                   ${data}
    ...                   ${key}
    ...                   ${value}
    tools.Set Dict Key    ${data}     ${key}    ${value}

Get Now As String
    [Arguments]
    ...            ${dummy}=${FALSE}
    ${result}=     tools.Get Now
    ${result}=     Set Variable         ${result.strftime("%Y-%m-%d %H:%M:%S")}
    RETURN         ${result}

Get Guid
    [Arguments]
    ...            ${dummy}=${FALSE}
    ${result}=     tools.Do Get Guid
    RETURN         ${result}

Odoo Sql
    [Arguments]
    ...            ${sql}
    ...            ${dbname}=${ODOO_DB}
    ...            ${host}=${ODOO_URL}
    ...            ${user}=${ODOO_USER}
    ...            ${pwd}=${ODOO_PASSWORD}
    ...            ${context}=${None}
    ${result}=     tools.Execute Sql          ${host}    ${dbname}    ${user}    ${pwd}    ${sql}    context=${context}
    RETURN         ${result}


Output Source
    [Arguments]
    ${myHtml} =       Get Source
    Log To Console    ${myHtml}


# For Stresstests suitable
Wait For Marker
    [Arguments]
    ...                               ${appendix}
    ...                               ${timeout}=120
    ...                               ${dbname}=${ODOO_DB}
    ...                               ${host}=${ODOO_URL}
    ...                               ${user}=${ODOO_USER}
    ...                               ${pwd}=${ODOO_PASSWORD}
    tools.Internal Wait For Marker    ${host}                    ${dbname}    ${user}    ${pwd}    ${TEST_NAME}${appendix}    ${timeout}


Set Wait Marker
    [Arguments]
    ...                               ${appendix}
    ...                               ${dbname}=${ODOO_DB}
    ...                               ${host}=${ODOO_URL}
    ...                               ${user}=${ODOO_USER}
    ...                               ${pwd}=${ODOO_PASSWORD}
    tools.Internal Set Wait Marker    ${host}                    ${dbname}    ${user}    ${pwd}    ${TEST_NAME}${appendix}

Open New Browser    [Arguments]     ${url}
    Set Selenium Speed	            1.0
    Set Selenium Timeout	        ${SELENIUM_TIMEOUT}
    Log To Console    ${url} 
    Log To Console    odoo-version: ${odoo_version}
    Log To Console    Using this browser engine: ${browser} 
    ${browser_id}=                  Get Driver For Browser    ${browser}  ${CURDIR}${/}..${/}tests/download
    Set Window Size                 1920    1080
    Go To                           ${url}
    Capture Page Screenshot
    RETURN      ${browser_id}

Eval Regex
    [Arguments]    ${regex}    ${text}
    ${matches}=    Evaluate    re.findall($regex, $text)
    ${result}=     Run Keyword If    "${matches}"!="[]"    Get From List    ${matches}   0
    RETURN         ${result}

Get Instance ID From Url
    [Arguments]  ${assumed_model}
    ${url}=    Get Location
    Log To Console  Location is ${url}
    Set Variable    ${url}
    ${model}=    Eval Regex    model=([^&]+)    ${url}
    ${id}=    Eval Regex    [\#\&]id=([^&]+)    ${url}
    Should Be Equal As Strings  ${model}   ${assumed_model}
    Log To Console  Model: ${model}
    Log To Console  ID: ${id}
    ${id}=  evaluate  int("${id}")
    RETURN    ${id}

Get All Variables
    ${variables}=    List All Variables
    RETURN    ${variables}

Log All Variables
	${variables}=    Get All Variables
	Log To Console  ${variables}

Log Keyword Parameters  
    [Arguments]      ${keyword}
    ${params}=       tools.Get Function Parameters  ${keyword}
    Log Many         ${params}
    Log To Console   ${params}

Assert  [Arguments]  ${expr}  ${msg}=Assertion failed
    tools.My_Assert  ${expr}  ${msg}
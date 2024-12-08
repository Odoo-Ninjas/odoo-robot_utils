*** Settings ***
Documentation       Some Tools

Library             ../library/odoo.py
Library             ../library/tools.py
Library             Collections


*** Keywords ***
Set Dict Key
    [Arguments]
    ...    ${data}
    ...    ${key}
    ...    ${value}
    tools.Set Dict Key    ${data}    ${key}    ${value}

Get Now As String
    [Arguments]
    ...    ${dummy}=${FALSE}
    ${result}=    tools.Get Now
    ${result}=    Set Variable    ${result.strftime("%Y-%m-%d %H:%M:%S")}
    RETURN    ${result}

Get Guid
    [Arguments]
    ...    ${dummy}=${FALSE}
    ${result}=    tools.Do Get Guid
    RETURN    ${result}

Odoo Sql
    [Arguments]
    ...    ${sql}
    ...    ${dbname}=${ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ODOO_USER}
    ...    ${pwd}=${ODOO_PASSWORD}
    ...    ${context}=${None}
    ${result}=    tools.Execute Sql    ${host}    ${dbname}    ${user}    ${pwd}    ${sql}    context=${context}
    RETURN    ${result}

Output Source
    ${myHtml}=    Get Source
    Log To Console    ${myHtml}

# For Stresstests suitable

Wait For Marker
    [Arguments]
    ...    ${appendix}
    ...    ${timeout}=120
    ...    ${dbname}=${ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ODOO_USER}
    ...    ${pwd}=${ODOO_PASSWORD}
    tools.Internal Wait For Marker
    ...    ${host}
    ...    ${dbname}
    ...    ${user}
    ...    ${pwd}
    ...    ${TEST_NAME}${appendix}
    ...    ${timeout}

Set Wait Marker
    [Arguments]
    ...    ${appendix}
    ...    ${dbname}=${ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ODOO_USER}
    ...    ${pwd}=${ODOO_PASSWORD}
    tools.Internal Set Wait Marker    ${host}    ${dbname}    ${user}    ${pwd}    ${TEST_NAME}${appendix}

Open New Browser    [Arguments]    ${url}
    Set Selenium Speed    1.0
    Set Selenium Timeout    ${SELENIUM_TIMEOUT}
    Log To Console    ${url}
    Log To Console    odoo-version: ${odoo_version}
    Log To Console    Using this browser engine: ${browser}
    ${browser_id}=    Get Driver For Browser    ${browser}    ${CURDIR}${/}..${/}tests/download
    Set Window Size    1920    1080
    Go To    ${url}
    Capture Page Screenshot
    RETURN    ${browser_id}

Eval Regex
    [Arguments]    ${regex}    ${text}
    ${matches}=    Evaluate    re.findall($regex, $text)
    IF    "${matches}"!="[]"
        ${result}=    Get From List    ${matches}    0
    ELSE
        ${result}=    Set Variable    ${None}
    END
    RETURN    ${result}

Extract Param From Url    [Arguments]    ${param}    ${url}=${NONE}
    IF    not ${url}
        ${url}=    Get Location
    END
    TRY
        ${param_value}=    Evaluate
        ...    urllib.parse.parse_qs(urllib.parse.urlparse("${url}").query)['${param}'][0]
        ...    modules=urllib
    EXCEPT
        ${param_value}=    Evaluate
        ...    urllib.parse.parse_qs(urllib.parse.urlparse("${url}").fragment)['${param}'][0]
        ...    modules=urllib
    END

    Log To Console    Parameter value: ${param_value} from ${param} in ${url}
    RETURN    ${param_value}

Get Instance ID From Url    [Arguments]    ${expected_model}
    ${counter}=    Set Variable    0
    WHILE    ${counter} < ${SELENIUM_TIMEOUT}
        ${is_model}=    Extract Param From Url    model
        IF    '${is_model}' == '${expected_model}'    BREAK
        Sleep    1s
    END
    IF    '${is_model}' != '${expected_model}'
        FAIL    Expected model ${expected_model} but got ${is_model}
    END

    ${counter}=    Set Variable    0
    WHILE    ${counter} < ${SELENIUM_TIMEOUT}
        TRY
            ${id}=    Extract Param From Url    id
            ${id}=    Evaluate    int("${id}")
            BREAK
        EXCEPT
            Log To Console
            ...    Sometimes the id is not in the url, seems so some reloading happens. So wait a little bit and give a chance
            Sleep    1s
        END
    END
    RETURN    ${id}

Get All Variables
    ${variables}=    List All Variables
    RETURN    ${variables}

Log All Variables
    ${variables}=    Get All Variables
    Log To Console    ${variables}

Log Keyword Parameters
    [Arguments]    ${keyword}
    ${params}=    tools.Get Function Parameters    ${keyword}
    Log Many    ${params}
    Log To Console    ${params}

Log2    [Arguments]    ${msg}
    Log To Console    ${msg}
    Log    ${msg}

Assert    [Arguments]    ${expr}    ${msg}=Assertion failed
    tools.My_Assert    ${expr}    ${msg}

Screenshot
    Capture Page Screenshot

Set Element Attribute
    # UNTESTED
    [Arguments]    ${xpath}    ${attribute}    ${value}
    ${js}=    Catenate    SEPARATOR=;
    ...    element.setAttribute("${attribute}", "${value}");
    JS On Element    ${xpath}    ${js}

JS On Element    [Arguments]    ${xpath}    ${jscode}

    ${js}=    Catenate
    ...    const callback = arguments[arguments.length - 1];
    ...    const xpath = "${xpath}";
    ...    const result = document.evaluate(
    ...    xpath, document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    ...    for (let i = 0; i < result.snapshotLength; i++) {
    ...    const element = result.snapshotItem(i);
    ...    ${jscode};
    ...    }
    ...    callback();

    Execute Async Javascript    ${js}

Get Selenium Timeout  [Arguments]
	# this gets the current timeout
    ${current_timeout}=    Set Selenium Timeout    0
    Set Selenium Timeout    ${current_timeout}
    # current_timeout = 3 seconds
    ${current_timeout}=  Eval  int(t.split(" ")[0])  t=${current_timeout}
    RETURN  ${current_timeout}
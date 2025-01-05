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
        ${counter}=  Evaluate  ${counter} + 1
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
        ${counter}=  Evaluate  ${counter} + 1
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

JS On Element    [Arguments]    ${xpath}    ${jscode}    ${maxcount}=0

    ${js}=    Catenate    SEPARATOR=\n
    ...    const callback = arguments[arguments.length - 1];
    ...    const xpath = "${xpath}";
    ...    const result = document.evaluate(
    ...    xpath, document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    ...    let funcresult = true;
    ...    if (${maxcount} && ${maxcount} > result.snapshotLength) {
    ...    callback("maxcount");
    ...    return;
    ...    }
    ...    for (let i = 0; i < result.snapshotLength; i++) {
    ...    const element = result.snapshotItem(i);
    ...    funcresult = 'ok';
    ...    ${jscode};
    ...    }
    ...    callback(funcresult);

    ${res}=    Execute Async Javascript    ${js}
    IF    "${res}" == "maxcount"
        FAIL    Too many elements found for ${xpath}. Please make sure you identify it more closely.
    END
    IF    "${res}" != "ok"    FAIL    did not find the element ${xpath} to click

Get Selenium Timeout    # this gets the current timeout
    ${current_timeout}=    Set Selenium Timeout    0
    Set Selenium Timeout    ${current_timeout}
    # current_timeout = 3 seconds
    ${current_timeout}=    Eval    int(t.split(" ")[0])    t=${current_timeout}
    RETURN    ${current_timeout}

Is Visible    [Arguments]    ${xpath}

    ${is_visible}=    Run Keyword And Return Status    Wait Until Element Is Visible    xpath=${xpath}    timeout=1ms
    RETURN    ${is_visible}

JS Scroll Into View    [Arguments]    ${xpath}

    Run Keyword And Ignore Error    Wait Until Element Is Visible    xpath=${xpath}
    Run Keyword And Ignore Error    JS On Element    xpath=${xpath}    element.scrollIntoView(true);
    Run Keyword And Ignore Error    Scroll Element Into View    xpath=${xpath}
    Sleep    1s
    Capture Page Screenshot

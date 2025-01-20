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
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
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
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
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
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
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
        ${counter}=    Evaluate    ${counter} + 1
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
        ${counter}=    Evaluate    ${counter} + 1
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
    Log To Console    no screenshots
    # Capture Page Screenshot

Set Element Attribute
    # UNTESTED
    [Arguments]    ${css}    ${attribute}    ${value}
    ${js}=    Catenate    SEPARATOR=;
    ...    element.setAttribute("${attribute}", "${value}");
    JS On Element    ${css}    ${js}

JS On Element    [Arguments]    ${css}    ${jscode}    ${maxcount}=0  ${return_callback}=${FALSE}

    ${js}=    Catenate    SEPARATOR=\n
    ...    const callback = arguments[arguments.length - 1];
    ...    const css = `${css}`;
    ...    const result = document.querySelectorAll(css);
    ...    let funcresult = "not_ok";
    ...    if (${maxcount} && ${maxcount} > result.length) {
    ...      callback("maxcount");
    ...    }
    ...    else {
    ...      for (const element of result) {
    ...        funcresult = 'ok';
    ...        ${jscode};
    ...      }
    ...      callback(funcresult);
    ...    }

    ${res}=    Execute Async Javascript    ${js}
    IF  ${return_callback}
        RETURN  ${res}
    ELSE
        IF    "${res}" == "maxcount"
            FAIL    Too many elements found for ${css}. Please make sure you identify it more closely.
        END
        IF    "${res}" != "ok"    FAIL    did not find the element ${css} to click
    END

Get Selenium Timeout    # this gets the current timeout
    ${current_timeout}=    Set Selenium Timeout    0
    Set Selenium Timeout    ${current_timeout}
    # current_timeout = 3 seconds
    ${current_timeout}=    Eval    int(t.split(" ")[0])    t=${current_timeout}
    RETURN    ${current_timeout}

Is Visible    [Arguments]    ${css}

    ${is_visible}=    Run Keyword And Return Status    Wait Until Element Is Visible    css=${css}    timeout=1ms
    RETURN    ${is_visible}

JS Scroll Into View    [Arguments]    ${css}

    # Run Keyword And Ignore Error    Wait Until Element Is Visible    css=${css}    timeout=20ms
    Run Keyword And Ignore Error    JS On Element    ${css}    element.scrollIntoView(true);
    # Run Keyword And Ignore Error    Scroll Element Into View    css=${css}

Get JS    [Arguments]    ${name}    ${prepend_js}=${NONE}
    [Documentation] 
    ...  ${js}=  Get JS  element_precheck.js
    ...  mode="${mode}"

    ${libdir}=    library Directory
    ${result}=    Get File    ${libdir}/../keywords/js/${name}

    ${result}=    Catenate    SEPARATOR=\n
    ...    ${prepend_js}
    ...    ${result}
    RETURN    ${result}


CSS Identifier With Text  [Arguments]  ${css}  ${text}  ${match}=exact
    Assert  '${match}' in ['exact', 'contains']
    ${identifier}=  Do Get Guid
    ${identifier}=  Set Variable  id${identifier}
    ${dataname}=  Set Variable  cssidentifier
    Execute Async Javascript  
    ...  const callback = arguments[arguments.length - 1];
    ...  const id = `${identifier}`;
    ...  const css = `${css}`;
    ...  const text = `${text}`.trim();
    ...  const arr = Array.from(document.querySelectorAll(css));
    ...  for (el of arr.filter(fe => '${match}' === 'exact' ? fe.textContent.trim() === text : fe.textContent.indexOf(text) >= 0)) {
    ...      el.dataset.${dataname} = id;
    ...  }
    ...  callback(true);
    ${result}=  Set Variable  [data-${dataname} = "${identifier}"]
    RETURN  ${result}


Activate AJAX Counter
    ${libdir}=    library Directory
    ${result}=    Get File    ${libdir}/../keywords/js/ajax_counter.js
    Execute Javascript  ${result}

Get Ajax Counter
    ${counter}=  Execute Async Javascript
    ...  const callback = arguments[arguments.length - 1];
    ...  const counter = parseInt(localStorage.getItem('robo_counter') || 0);
    ...  callback(counter);
    ${counter}=  Eval  int("${counter}")
    RETURN  ${counter}

Wait Ajax Requests Done
    ${counter_ajax}=  Get Ajax Counter
    ${counter}=    Set Variable    0
    WHILE    ${counter} < ${SELENIUM_TIMEOUT} and ${counter_ajax} > 0
        Sleep  0.1s
        ${counter}=  Evaluate  ${counter} + 0.1
        ${counter_ajax}=  Get Ajax Counter
    END
    IF  ${counter} > 0
        FAIL  Timeout waiting for ajax requests to finish
    END

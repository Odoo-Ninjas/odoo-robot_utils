*** Settings ***
Documentation       Some Tools

Library             ../library/odoo.py
Library             ../library/tools.py
Library             Collections
Library             SeleniumLibrary


*** Keywords ***
Eval Bool    [Arguments]    ${value}
    ${t}=    Eval
    ...    v if isinstance(v, bool) else (v.lower() in ['1', 'true', 'wahr', 'ja'] if isinstance(v, str) else bool(v))
    ...    v=${value}
    RETURN    ${t}

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
    IF    ${ODOO_VERSION} >= 18.0
        IF  "${param}" == "model"
            ${param_value}=    Evaluate
            ...    "${url}".split("/")[-2]
            ...    modules=urllib
        ELSE IF  "${param}" == "id"
            ${param_value}=    Evaluate
            ...    int("${url}".split("/")[-1])
            ...    modules=urllib
        ELSE
            FAIL  not implemented ${param}
        END
    ELSE
        TRY
            ${param_value}=    Evaluate
            ...    urllib.parse.parse_qs(urllib.parse.urlparse("${url}").query)['${param}'][0]
            ...    modules=urllib
        EXCEPT
            ${param_value}=    Evaluate
            ...    urllib.parse.parse_qs(urllib.parse.urlparse("${url}").fragment)['${param}'][0]
            ...    modules=urllib
        END
    END

    Log To Console    Parameter value: ${param_value} from ${param} in ${url}
    RETURN    ${param_value}

_get_instance_id_from_url_lt_18  [Arguments]    ${expected_model}
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
    RETURN  ${id}

Get Instance ID From Url    [Arguments]    ${expected_model}

    IF  ${ODOO_VERSION} < 18.0
        ${id}=  _get_instance_id_from_url_lt_18  expected_model=${expected_model}
    ELSE
        ${url}=    Get Location   #  e.g.  /odoo/action-161/3
        ${id}=  Eval  int(s.split("/")[-1])  s=${url}

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
    Capture Page Screenshot

Set Element Attribute
    # UNTESTED
    [Arguments]    ${css}    ${attribute}    ${value}
    ${js}=    Catenate    SEPARATOR=;
    ...    element.setAttribute("${attribute}", "${value}");
    ${res}=    JS On Element    ${css}    ${js}

JS On Element    [Arguments]    ${css}    ${jscode}    ${maxcount}=0    ${return_callback}=${FALSE}    ${limit}=0    ${position}=0  ${filter_visible}=${TRUE}
    ${max_and_pos}=    Eval    max and pos    max=${maxcount}    pos=${position}
    IF    ${max_and_pos}
        ${maxcount}=    Set Variable    0
        ${limit}=    Set Variable    0
    END
    ${toolsjs}=    Get JS    
    ${js_filter_visible}=   Eval  'true' if b else 'false'  b=${filter_visible}

    ${js}=    Catenate    SEPARATOR=\n
    ...    ${toolsjs}
    ...    const callback_arg = arguments[arguments.length - 1];
    ...    const css = `${css}`;
    ...    const position = ${position};
    ...    const jscode = `${jscode}`;
    ...    const limit = ${limit};
    ...    const filter_visible = ${js_filter_visible};
    ...    const maxcount = ${maxcount};
    ...    getElement(callback_arg, css, maxcount, position, jscode, limit, filter_visible);

    # Set Selenium Timeout    100
    ${res}=    Execute Async Javascript    ${js}
    IF    ${return_callback}
        RETURN    ${res}
    ELSE
        IF    "${res}".startswith("maxcount")
            FAIL    Too many elements found for ${css}. Please make sure you identify it more closely.
        END
        IF    "${res}" != "ok"
            FAIL    did not find the element ${css} to click
        END
    END

Get Selenium Timeout    # this gets the current timeout
    RETURN  ${SELENIUM_TIMEOUT}

Is Visible    [Arguments]    ${css}

    ${is_visible}=    Run Keyword And Return Status    Wait Until Element Is Visible    css=${css}    timeout=1ms
    RETURN    ${is_visible}

JS Scroll Into View    [Arguments]    ${css}

    # Run Keyword And Ignore Error    Wait Until Element Is Visible    css=${css}    timeout=20ms
    Run Keyword And Ignore Error    JS On Element    ${css}    element.scrollIntoView(true);
    # Run Keyword And Ignore Error    Scroll Element Into View    css=${css}

Get JS    [Documentation]
    ...    ${js}=    Get JS    element_precheck.js
    ...    mode="${mode}"
    [Arguments]    ${name}=${NONE}    ${prepend_js}=${NONE}    ${append_js}=${NONE}

    ${prepend_js}=    Eval    X or ""    X=${prepend_js}
    ${append_js}=    Eval    X or ""    X=${append_js}

    ${libdir}=    library Directory
    ${tools}=    Get File    ${libdir}/../keywords/js/tools.js
    ${name_none}=  Eval  not x  x=${name}
    IF  not ${name_none}
        ${result}=    Get File    ${libdir}/../keywords/js/${name}
    ELSE
        ${result}=  Set Variable  # empty
    END

    ${result}=    Catenate    SEPARATOR=\n
    ...    ${tools}
    ...    ${prepend_js}
    ...    ${result}
    ...    ${append_js}
    RETURN    ${result}

CSS Identifier With Text    [Arguments]
    ...    ${css}
    ...    ${text}
    ...    ${match}=exact
    ...    ${attribute}=inner text
    ...    ${limit}=0
    ...    ${return_counter}=${FALSE}
    Wait Until Page Contains Element    css=${css}
    Assert    '${match}' in ['exact', 'contains']
    ${identifier}=    Do Get Guid
    ${identifier}=    Set Variable    id${identifier}
    ${dataname}=    Set Variable    cssidentifier
    ${toolsjs}=    Get JS    tools.js
    ${counter}=    Execute Async Javascript
    ...    ${toolsjs};
    ...    const callback = arguments[arguments.length - 1];
    ...    const id = `${identifier}`;
    ...    const css = `${css}`;
    ...    const text = `${text}`.trim();
    ...    const arr = Array.from(document.querySelectorAll(css));
    ...    let counter = 0;
    ...    function matches(el) {
    ...    let textValueToCheck = null;
    ...    if (`${attribute}` === 'inner text') {
    ...    textValueToCheck = el.textContent.trim();
    ...    } else {
    ...    textValueToCheck = el.getAttribute("${attribute}");
    ...    }
    ...    if (window.getComputedStyle(el).display === "none" || isAnyParentHidden(el)) {
    ...    return false;
    ...    }
    ...    const matches = '${match}' === 'exact' ? textValueToCheck === text : textValueToCheck.indexOf(text) >= 0;
    ...    if (matches) counter += 1;
    ...    if (${limit} > 0 && counter > ${limit}) return false;
    ...    return matches;
    ...    }
    ...    for (el of arr.filter(matches)) {
    ...    el.dataset.${dataname} = id;
    ...    }
    ...    callback(counter);
    ${result}=    Set Variable    [data-${dataname} = "${identifier}"]
    IF    ${return_counter}    RETURN    ${counter}    ${result}
    RETURN    ${result}

Activate AJAX Counter
    ${libdir}=    library Directory
    ${result}=    Get File    ${libdir}/../keywords/js/ajax_counter.js
    Execute Javascript    ${result}

Get Ajax Counter
    ${counter}=    Execute Async Javascript
    ...    const callback = arguments[arguments.length - 1];
    ...    const counter = parseInt(localStorage.getItem('robo_counter') || 0);
    ...    callback(counter);
    ...    console.log("Count current requests: " + counter);
    ${counter}=    Eval    int("${counter}")
    RETURN    ${counter}

Wait Ajax Requests Done
    ${counter_ajax}=    Get Ajax Counter
    ${counter}=    Set Variable    0
    ${there_was_a_request}=    Eval    c > 0    c=${counter_ajax}
    WHILE    ${counter} < ${SELENIUM_TIMEOUT} and ${counter_ajax} > 0
        Sleep    0.1s
        ${counter}=    Evaluate    ${counter} + 0.1
        ${counter_ajax}=    Get Ajax Counter
    END
    IF    ${counter_ajax} > 0
        FAIL    Timeout waiting for ajax requests to finish
    END

    IF    ${there_was_a_request}
        # Give time to react on the request;
        # e.g. button is pressed and server executes something; with 100ms
        # on M4 machine it was enough time to wait to show an error dialog

        Sleep    10ms

        # there is a documentation entry with more information:
        ## Expect Error after button click or input action
    END

JS Exists Element  [Arguments]  ${css}  ${text}
    ${js}=  Catenate  SEPARATOR=\n
    ...  debugger;
    ...  if (element.textContent.includes('${text}')) {
    ...  funcresult = 'found';
    ...  }
    ...  if (element.value && element.value.includes('${text}')) {
    ...  funcresult = 'found';
    ...  }
    ${exists}=  JS On Element  textarea  ${js}  return_callback=${TRUE}
    IF  "${exists}" != "found"
        Fail  Error not found
    END


Wait Until Responding
    ${url}=  Set Variable  ${ODOO_URL}/web/login
    Log To Console  calling ${url} to wait until there
    Wait For 200  url=${url}  DELAY_SECONDS=1  tries=10
    Log To Console  url ${url} is responding
*** Settings ***
Documentation    Some Tools

Library    ../library/odoo.py
Library    ../library/tools.py
Library    Collections
Library     SeleniumLibrary

*** Keywords ***

Last Browser

    ${driver}=    Last Browser Lib
    RETURN        ${driver}

Open New Browser    [Arguments]    ${url}
    ${python_path}    Evaluate    sys.executable    modules=sys
    Log    Python Executable: ${python_path}

    Set Selenium Speed         1.0
    Set Selenium Timeout       ${SELENIUM_TIMEOUT}
    Log To Console             ${url}
    Log To Console             odoo-version: ${odoo_version}
    ${BROWSER_HEADLESS}=       Eval                                                         True if str(b) in ["1", "True"] else False    b=${BROWSER_HEADLESS}
    ${driver}=                 Get Driver For Browser                                       ${CURDIR}${/}..${/}tests/download    ${BROWSER_HEADLESS}
    ${x}  ${y}=  Get Window Position      
    Set Window Position        0                                                            0
    Set Window Size            ${BROWSER_WIDTH}                                             ${BROWSER_HEIGHT}
    ${snippet}=  Get Variable Value         ${SNIPPET_MODE}  ${FALSE}
    IF  not ${snippet}
        Go To                      ${url}
    END
    Capture Page Screenshot
    RETURN                     ${driver}
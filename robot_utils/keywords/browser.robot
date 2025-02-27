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

Detect DevTools
    ${is_open}=    Execute Async Javascript    
    ...    let result = (window.outerWidth - window.innerWidth > 100) || (window.outerHeight - window.innerHeight > 100);
    ...    arguments[arguments.length - 1](result);
    RETURN   ${is_open}

Go To  [Arguments]  ${url}
    SeleniumLibrary.Go To  ${url}
    Activate Ajax Counter

Open New Browser    [Arguments]    ${url}
    ${python_path}    Evaluate    sys.executable    modules=sys
    Log    Python Executable: ${python_path}

    Set Selenium Speed         ${SELENIUM_SPEED}
    Set Selenium Timeout       ${SELENIUM_TIMEOUT}
    Log To Console             ${url}
    Log To Console             odoo-version: ${odoo_version}
    ${BROWSER_HEADLESS}=       Eval                                                         True if str(b) in ["1", "True"] else False    b=${BROWSER_HEADLESS}
    ${snippet}=              Get Variable Value         ${SNIPPET_MODE}  ${FALSE}
    ${TRY_REUSE_SESSION}=      Eval  True if snippetmode else False  snippetmode=${snippet}
    ${driver}=                 Get Driver For Browser                                       ${ROBO_UPLOAD_FILES_DIR_BROWSER_DRIVER}    ${BROWSER_HEADLESS}  try_reuse_session=${TRY_REUSE_SESSION}
    ${x}  ${y}=  Get Window Position      
    IF  not ${snippet}
        # Set Window Position        0                                                            0
        Set Window Size            ${BROWSER_WIDTH}                                             ${BROWSER_HEIGHT}
        Go To                      ${url}
    ELSE
        Activate Ajax Counter
    END
    Capture Page Screenshot
    RETURN                     ${driver}
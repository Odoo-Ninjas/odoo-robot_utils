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

    Set Selenium Speed         1.0
    Set Selenium Timeout       ${SELENIUM_TIMEOUT}
    Log To Console             ${url}
    Log To Console             odoo-version: ${odoo_version}
    Log To Console             Using this browser engine: ${browser}
    ${BROWSER_HEADLESS}=       Eval                                                         True if b\=\="1" else False    b=${BROWSER_HEADLESS}
    ${driver}=                 Get Driver For Browser                                       ${browser}                     ${CURDIR}${/}..${/}tests/download    ${BROWSER_HEADLESS}
    ${browser_width}=          Get Environment Variable                                     BROWSER_WIDTH
    ${browser_height}=         Get Environment Variable                                     BROWSER_HEIGHT
    Set Window Position        0                                                            0
    Log To Console             Browser width: ${browser_width} height: ${browser_height}
    Set Window Size            ${browser_width}                                             ${browser_height}
    Go To                      ${url}
    Capture Page Screenshot
    RETURN                     ${driver}
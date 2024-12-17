*** Settings ***
Library    SeleniumLibrary
Library    OperatingSystem 
Resource   ./tools.robot

*** Variables ***


*** Keywords ***

Highlight Element    [Arguments]    ${xpath}    ${toggle}

    ${toggle}=                  Eval                                                                  str(bool(t.lower()) if isinstance(t, str) else bool(t)).lower()    t=${toggle}
    ${content}=                 Get File
    ...                         ${CUSTOMS_DIR}/addons_robot/robot_utils/keywords/js/highlight_element.js
    ${js}=                      Catenate                                                              SEPARATOR=\n
    ...                         const xpath = "${xpath}";
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content}
    ...                         highlightElementByXPath(xpath, ${toggle});
    ...                         callback();
    Execute Async Javascript    ${js}


Add Cursor

    ${content}=                 Get File                                             ${CUSTOMS_DIR}/addons_robot/robot_utils/keywords/js/cursor.js
    ${js}=                      Catenate                                             SEPARATOR=\n
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content};
    ...                         addCursor()
    ...                         callback();
    Execute Async Javascript    ${js}

Remove Cursor
    ${content}=                 Get File                                             ${CUSTOMS_DIR}/addons_robot/robot_utils/keywords/js/cursor.js
    ${js}=                      Catenate                                             SEPARATOR=\n
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content};
    ...                         removeCursor()
    ...                         callback();
    Execute Async Javascript    ${js}


ShowTooltipByXPath    [Arguments]    ${xpath}    ${tooltip}

    ${content}=
    ...                         Get File
    ...                         ${CUSTOMS_DIR}/addons_robot/robot_utils/keywords/js/highlight_element.js
    ${js}=                      Catenate                                                              SEPARATOR=\n
    ...                         const xpath = "${xpath}";
    ...                         const tooltip = "${tooltip}";
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content}
    ...                         showTooltipByXPath(xpath, tooltip);
    ...                         callback();
    Execute Async Javascript    ${js}

RemoveTooltips    [Arguments]

    ${content}=
    ...                         Get File
    ...                         ${CUSTOMS_DIR}/addons_robot/robot_utils/keywords/js/highlight_element.js
    ${js}=                      Catenate                                                              SEPARATOR=\n
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content}
    ...                         removeTooltips();
    ...                         callback();
    Execute Async Javascript    ${js}
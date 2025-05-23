*** Settings ***
Library    SeleniumLibrary
Library    OperatingSystem
Resource   ./tools.robot

*** Variables ***


*** Keywords ***

Highlight Element    [Arguments]    ${css}    ${toggle}

    IF  ${ROBO_NO_UI_HIGHLIGHTING}
        RETURN
    END

    ${toggle}=                  Eval                                                                  str(bool(t.lower()) if isinstance(t, str) else bool(t)).lower()    t=${toggle}
    ${content}=                 Get File
    ...                         ${CUSTOMS_DIR}/addons_robot/robot_utils/keywords/js/highlight_element.js
    ${js}=                      Catenate                                                              SEPARATOR=\n
    ...                         const css = `${css}`;
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content}
    ...                         highlightElementByCss(css, ${toggle});
    ...                         callback();
    Execute Async Javascript    ${js}


Add Cursor
    IF  ${ROBO_NO_UI_HIGHLIGHTING}
        RETURN
    END

    ${content}=                 Get File                                             ${CUSTOMS_DIR}/addons_robot/robot_utils/keywords/js/cursor.js
    ${js}=                      Catenate                                             SEPARATOR=\n
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content};
    ...                         addCursor()
    ...                         callback();
    Execute Async Javascript    ${js}

Remove Cursor
    IF  ${ROBO_NO_UI_HIGHLIGHTING}
        RETURN
    END
    ${content}=                 Get File                                             ${CUSTOMS_DIR}/addons_robot/robot_utils/keywords/js/cursor.js
    ${js}=                      Catenate                                             SEPARATOR=\n
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content};
    ...                         removeCursor()
    ...                         callback();
    Execute Async Javascript    ${js}


ShowTooltipByLocator    [Arguments]    ${css}    ${tooltip}
    IF  ${ROBO_NO_UI_HIGHLIGHTING}
        RETURN
    END

    ${content}=
    ...                         Get File
    ...                         ${CUSTOMS_DIR}/addons_robot/robot_utils/keywords/js/highlight_element.js
    ${js}=                      Catenate                                                              SEPARATOR=\n
    ...                         const tooltip = "${tooltip}";
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content}
    ...                         showTooltipByCss(`${css}`, tooltip);
    ...                         callback();
    Execute Async Javascript    ${js}

RemoveTooltips    [Arguments]
    IF  ${ROBO_NO_UI_HIGHLIGHTING}
        RETURN
    END

    ${content}=
    ...                         Get File
    ...                         ${CUSTOMS_DIR}/addons_robot/robot_utils/keywords/js/highlight_element.js
    ${js}=                      Catenate                                                              SEPARATOR=\n
    ...                         const callback = arguments[arguments.length - 1];
    ...                         ${content}
    ...                         removeTooltips();
    ...                         callback();
    Execute Async Javascript    ${js}

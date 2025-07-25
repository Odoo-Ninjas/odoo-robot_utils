*** Settings ***
Library    SeleniumLibrary
Library             ../library/tools.py
Library             ../library/default_vars.py
Resource            ./odoo.robot
Resource            ./wodoo.robot

*** Keywords ***

Basic Teardown
    Wait Blocking
    Eval Error States

    Close All Browsers

Setup Test Basic
    Load Default Vars

    Wait Until Responding

    @{modules}=  Get Variable Value  ${INSTALL_MODULES}  ${NONE}
    IF  ${modules}
        Toggle Module Installation  ${modules}  ${TRUE}
    END

    @{modules}=  Get Variable Value  ${UNINSTALL_MODULES}  ${NONE}
    IF  ${modules}
        Toggle Module Installation  ${modules}  ${FALSE}
    END

Toggle Module Installation  [Arguments]  ${modules}  ${install_state}
    ${method}=  Eval  'update' if v else 'uninstall'  v=${install_state}

    FOR  ${module}  IN  @{modules}
        ${state}=  Odoo Search Read Records    ir.module.module  [['name', '=', '${module}']]  state

        IF  ${state}
            ${state}=  Set Variable  ${state}[0]
        ELSE
            ${state}=  Create Dictionary  state=uninstalled
        END
        ${state}=  Get From Dictionary  ${state}  state
        ${installed}=  Eval  '${state}' \=\= 'installed'  state=${state}

        IF  ${installed} and not ${install_state} or not ${installed} and ${install_state}
            Log To Console  ${method}ing ${module}
            Odoo Command  kill odoo
            Odoo Command  ${method} ${module}
            Odoo Command  up -d
            Wait Until Responding
        END

    END

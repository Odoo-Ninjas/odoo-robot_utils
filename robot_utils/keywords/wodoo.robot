*** Settings ***
Library     ../library/zodoo.py
Resource    ../keywords/tools.robot


*** Keywords ***
Odoo Command
    [Arguments]    ${shellcmd}    ${output}=${FALSE}
    zodoo.command    ${shellcmd}    ${output}

    # TIPP: call Wait Until Responding when doing odoo up -d

Odoo Update Docker Compose
    [Arguments]    ${service}    ${environment}
    zodoo.update_docker_compose    ${service}    ${environment}


Odoo Start Queuejobs
    Odoo Command    up -d odoo_queuejobs  --no-recreate
    Wait Until Responding

Odoo Stop Queuejobs
    Odoo Command    kill odoo_queuejobs

Odoo Start Cronjobs
    Odoo Command    up -d odoo_cronjobs --no-recreate
    Wait Until Responding

Odoo Stop Cronjobs
    Odoo Command    kill odoo_cronjobs
Start Containers By Robot
    Odoo Command  up -d --no-recreate postgres
    Odoo Command  wait-for-container-postgres
    Odoo Command  up -d --no-recreate
    Wait Until Responding
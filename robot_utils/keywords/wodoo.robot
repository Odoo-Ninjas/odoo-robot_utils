*** Settings ***
Library     ../library/wodoo.py
Resource    ../keywords/tools.robot


*** Keywords ***
Odoo Command
    [Arguments]    ${shellcmd}    ${output}=${FALSE}
    wodoo.command    ${shellcmd}    ${output}

    # TIPP: call Wait Until Responding when doing odoo up -d

Odoo Update Docker Compose
    [Arguments]    ${service}    ${environment}
    wodoo.update_docker_compose    ${service}    ${environment}


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
    Odoo Command  up -d --no-recreate
    Odoo Command  wait-for-container-postgres
    Wait Until Responding
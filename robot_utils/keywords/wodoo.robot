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
    # Use up -d without --no-recreate so containers with stale network references
    # (left by orphan cleanup in prepare_test_db) are recreated fresh. Volumes are
    # not touched so the restored DB is preserved.
    Odoo Command  up -d postgres
    Odoo Command  wait-for-container-postgres
    Odoo Command  up -d
    Wait Until Responding
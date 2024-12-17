*** Settings ***
Library    ../library/wodoo.py


*** Keywords ***

Odoo Command
    [Arguments]      ${shellcmd}  ${output}=${FALSE}
    wodoo.command    ${shellcmd}  ${output}

Odoo Start Queuejobs
    Odoo Command    up -d odoo_queuejobs

Odoo Stop Queuejobs
    Odoo Command    kill odoo_queuejobs

Odoo Start Cronjobs
    Odoo Command    up -d odoo_cronjobs

Odoo Stop Cronjobs
    Odoo Command    kill odoo_cronjobs
# Uses the current opened browser and you can test your next snippet here
*** Comments ***
# odoo-uninstall: partner_autocomplete


*** Settings ***
Documentation       Testing Basic Functions of the Robot Keywords

Library             OperatingSystem
Resource            ../keywords/odoo.robot

Test Setup          Last Browser


*** Test Cases ***
My Snippet
    Capture Page Screenshot

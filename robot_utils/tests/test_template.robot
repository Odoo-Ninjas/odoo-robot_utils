*** Settings ***
Documentation    Todo.........
Resource         ../addons_robot/robot_utils/keywords/odoo.robot
Resource         ../addons_robot/robot_utils/keywords/tools.robot
Resource         ../addons_robot/robot_utils/keywords/wodoo.robot
Test Setup       Setup Test


*** Variables ***
${SNIPPET_MODE}    ${{ 0 }}  # if true, then login does not happen and your test continues in opened browser
                                 # useful to fine tune some keyword
@{INSTALL_MODULES}  robot_utils  zbsync
@{UNINSTALL_MODULES}  partner_autocomplete


*** Test Cases ***
Buy Something and change amount
    # Search for the admin
    # Odoo Load Data    ../data/products.xml 
    MainMenu          purchase.menu_purchase_root
    Odoo Button       Create
    WriteInField      partner_id                     A-Vendor DE
    Odoo Button       text=Add a product
    WriteInField      product_id                     Storage Box    parent=order_line
    WriteInField      product_qty                    50             parent=order_line
    FormSave
    Screenshot
    Odoo Button       name=button_confirm

*** Keywords ***
Setup Test
    Setup Test Basic
    Login
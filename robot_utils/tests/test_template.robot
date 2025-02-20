*** Settings ***
# For keywords have a look in addons_robot/robot_utils/keywords/documentation.md
Resource         ${EXECDIR}/addons_robot/robot_utils/keywords/odoo.robot
Resource         ${EXECDIR}/addons_robot/robot_utils/keywords/tools.robot
Resource         ${EXECDIR}/addons_robot/robot_utils/keywords/wodoo.robot
Resource         ${EXECDIR}/addons_robot/robot_utils/keywords/test_setup.robot
Test Setup       Setup Test
Test Teardown    Teardown Test


*** Variables ***
# Set environment variable SNIPPET_MODE to robo test, to not login and continue with last ${TOKEN} !
# Allows to continue in the middle of the test.
@{INSTALL_MODULES}  robot_utils  purchase
@{UNINSTALL_MODULES}  partner_autocomplete


*** Test Cases ***
Buy Something and change amount
    # Search for the admin
    # Odoo Load Data    ../data/products.xml 
    MainMenu          purchase.menu_purchase_root
    IF  ${odoo_version} <= 16.0
        Odoo Button       New
    ELSE
        Odoo Button       Create
    END
    Write             partner_id                     A-Vendor DE
    Odoo Button       text=Add a product
    Write             product_id                     Storage Box    parent=order_line
    Write             product_qty                    50             parent=order_line
    FormSave
    Screenshot
    Odoo Button       name=button_confirm

*** Keywords ***
Setup Test
    Setup Test Basic
    Login

Teardown Test
    Basic Teardown